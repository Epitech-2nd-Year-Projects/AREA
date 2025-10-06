package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/adapters/inbound/http/router"
	loggerMailer "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/adapters/outbound/mailer/logger"
	sendgridMailer "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/adapters/outbound/mailer/sendgrid"
	oauthadapter "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/adapters/outbound/oauth"
	actionpostgres "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/adapters/outbound/postgres/action"
	areapostgres "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/adapters/outbound/postgres/area"
	authpostgres "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/adapters/outbound/postgres/auth"
	componentpostgres "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/adapters/outbound/postgres/component"
	gmail "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/adapters/outbound/reaction/gmail"
	reactionhttp "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/adapters/outbound/reaction/http"
	areaapp "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/app/area"
	authapp "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/app/auth"
	componentapp "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/app/components"
	configviper "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/platform/config/viper"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/platform/database/postgres"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/platform/httpserver"
	ginhttp "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/platform/httpserver/gin"
	projectlogging "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/platform/logging"
	projectlogger "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/platform/logging/zap"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/platform/security/password"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/platform/services/catalog"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
	"go.uber.org/zap"
)

func main() {
	if err := run(); err != nil {
		fmt.Fprintf(os.Stderr, "cmd/server: %v\n", err)
		os.Exit(1)
	}
}

func run() error {
	cfg, err := configviper.Load()
	if err != nil {
		return fmt.Errorf("configviper.Load: %w", err)
	}

	logCfg := projectlogging.Config{
		Level:         cfg.Logging.Level,
		Format:        cfg.Logging.Format,
		Pretty:        cfg.Logging.Pretty,
		IncludeCaller: cfg.Logging.IncludeCaller,
		DefaultFields: cfg.Logging.DefaultFields,
	}

	logger, err := projectlogger.New(logCfg)
	if err != nil {
		return fmt.Errorf("projectlogger.New: %w", err)
	}

	zap.ReplaceGlobals(logger)
	defer func() {
		_ = logger.Sync()
	}()

	httpCfg := httpserver.Config{
		Host:            cfg.Server.HTTP.Host,
		Port:            cfg.Server.HTTP.Port,
		ReadTimeout:     cfg.Server.HTTP.ReadTimeout,
		WriteTimeout:    cfg.Server.HTTP.WriteTimeout,
		IdleTimeout:     cfg.Server.HTTP.IdleTimeout,
		ShutdownTimeout: 20 * time.Second,
		Mode:            httpserver.ModeFromEnvironment(cfg.App.Environment),
		CORS: httpserver.CORSConfig{
			AllowedOrigins:   cfg.Server.HTTP.CORS.AllowedOrigins,
			AllowedMethods:   cfg.Server.HTTP.CORS.AllowedMethods,
			AllowedHeaders:   cfg.Server.HTTP.CORS.AllowedHeaders,
			AllowCredentials: cfg.Server.HTTP.CORS.AllowCredentials,
		},
	}

	server, err := ginhttp.New(httpCfg, ginhttp.WithLogger(logger))
	if err != nil {
		return fmt.Errorf("ginhttp.New: %w", err)
	}

	var (
		loaders          []catalog.Loader
		authHandler      *authapp.Handler
		oauthService     *authapp.OAuthService
		areaHandler      *areaapp.Handler
		componentHandler *componentapp.Handler
		timerScheduler   *areaapp.TimerScheduler
	)

	dbCtx := context.Background()
	db, dbErr := postgres.Open(dbCtx, cfg.Database)
	if dbErr != nil {
		logger.Warn("postgres connection unavailable", zap.Error(dbErr))
	} else {
		loaders = append(loaders, catalog.DBLoader{DB: db})

		repo := authpostgres.NewRepository(db)

		mailer := buildMailer(cfg, logger)

		authCfg := authapp.Config{
			PasswordMinLength: cfg.Security.Password.MinLength,
			SessionTTL:        cfg.Security.Sessions.TTL,
			VerificationTTL:   cfg.Security.Verification.TokenTTL,
			BaseURL:           cfg.App.BaseURL,
			CookieName:        cfg.Security.Sessions.CookieName,
		}

		authService := authapp.NewService(
			repo.Users(),
			repo.Sessions(),
			repo.VerificationTokens(),
			mailer,
			password.Hasher{Pepper: cfg.Security.Password.Pepper},
			nil,
			logger,
			authCfg,
		)

		oauthManager, managerErr := buildOAuthManager(cfg, logger)
		if managerErr != nil {
			logger.Warn("failed to build oauth manager", zap.Error(managerErr))
		} else if oauthManager != nil {
			oauthService = authapp.NewOAuthService(oauthManager, repo.Identities(), repo.Users(), repo.Sessions(), nil, logger, authCfg)
		}

		authHandler = authapp.NewHandler(authService, oauthService, authapp.CookieConfig{
			Domain:   cfg.Security.Sessions.Domain,
			Path:     cfg.Security.Sessions.Path,
			Secure:   cfg.Security.Sessions.Secure,
			HTTPOnly: cfg.Security.Sessions.HTTPOnly,
			SameSite: parseSameSite(cfg.Security.Sessions.SameSite),
		})

		areaRepo := areapostgres.NewRepository(db)
		componentRepo := componentpostgres.NewRepository(db)
		actionRepo := actionpostgres.NewRepository(db)

		httpClient := &http.Client{Timeout: 10 * time.Second}
		reactionHTTP := &reactionhttp.Executor{
			Client: httpClient,
			Logger: logger,
		}

		reactionHandlers := make([]areaapp.ComponentReactionHandler, 0, 1)
		if oauthManager != nil {
			gmailExecutor := gmail.NewExecutor(repo.Identities(), oauthManager, httpClient, nil, logger)
			reactionHandlers = append(reactionHandlers, gmailExecutor)
		}

		reactionDispatcher := areaapp.NewCompositeReactionExecutor(reactionHTTP, logger, reactionHandlers...)
		timerProvisioner := areaapp.NewTimerProvisioner(actionRepo, nil)
		areaService := areaapp.NewService(areaRepo, componentRepo, reactionDispatcher, nil, timerProvisioner)

		areaCookies := areaapp.CookieConfig{
			Name:     cfg.Security.Sessions.CookieName,
			Domain:   cfg.Security.Sessions.Domain,
			Path:     cfg.Security.Sessions.Path,
			Secure:   cfg.Security.Sessions.Secure,
			HTTPOnly: cfg.Security.Sessions.HTTPOnly,
			SameSite: parseSameSite(cfg.Security.Sessions.SameSite),
		}
		areaHandler = areaapp.NewHandler(areaService, authService, areaCookies)

		componentHandler = componentapp.NewHandler(
			componentapp.NewService(componentRepo),
			authService,
			componentapp.CookieConfig{
				Name:     cfg.Security.Sessions.CookieName,
				Domain:   cfg.Security.Sessions.Domain,
				Path:     cfg.Security.Sessions.Path,
				Secure:   cfg.Security.Sessions.Secure,
				HTTPOnly: cfg.Security.Sessions.HTTPOnly,
				SameSite: parseSameSite(cfg.Security.Sessions.SameSite),
			},
		)

		timerScheduler = areaapp.NewTimerScheduler(actionRepo, areaService, nil, areaapp.WithTimerLogger(logger))
		sqlDB, err := db.DB()
		if err != nil {
			logger.Warn("gorm.DB unwrap failed", zap.Error(err))
		} else {
			defer func() {
				_ = sqlDB.Close()
			}()
		}
	}

	if path := strings.TrimSpace(cfg.ServicesCatalog.BootstrapFile); path != "" {
		loaders = append(loaders, catalog.FileLoader{Path: path})
	}
	if len(loaders) == 0 {
		loaders = append(loaders, catalog.EmptyLoader{})
	}

	if err := router.Register(server.Engine(), router.Dependencies{
		AboutLoader:      catalog.NewChainLoader(loaders...),
		AuthHandler:      authHandler,
		AreaHandler:      areaHandler,
		ComponentHandler: componentHandler,
	}); err != nil {
		return fmt.Errorf("router.Register: %w", err)
	}

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	if timerScheduler != nil {
		go timerScheduler.Run(ctx)
	}

	logger.Info("starting http server",
		zap.String("environment", cfg.App.Environment),
		zap.String("addr", httpCfg.Address()),
	)

	if err := server.Run(ctx); err != nil {
		return fmt.Errorf("ginhttp.Server.Run: %w", err)
	}

	logger.Info("http server stopped gracefully")
	return nil
}

func buildMailer(cfg configviper.Config, logger *zap.Logger) outbound.Mailer {
	provider := strings.TrimSpace(strings.ToLower(cfg.Notifier.Mailer.Provider))
	switch provider {
	case "sendgrid":
		return sendgridMailer.Mailer{
			APIKey:    cfg.Notifier.Mailer.APIKey,
			FromEmail: cfg.Notifier.Mailer.FromEmail,
			FromName:  cfg.App.Name,
			Sandbox:   cfg.Notifier.Mailer.SandboxMode,
		}
	default:
		return loggerMailer.Mailer{Logger: logger}
	}
}

func buildOAuthManager(cfg configviper.Config, logger *zap.Logger) (*oauthadapter.Manager, error) {
	providerConfigs := make(map[string]oauthadapter.ProviderCredentials)
	for name, provider := range cfg.OAuth.Providers {
		key := strings.ToLower(strings.TrimSpace(name))
		if key == "" {
			continue
		}

		clientID := strings.TrimSpace(provider.ClientID)
		clientSecret := strings.TrimSpace(provider.ClientSecret)
		redirectURI := strings.TrimSpace(provider.RedirectURI)
		if clientID == "" || clientSecret == "" || redirectURI == "" {
			logger.Warn("oauth provider configuration incomplete",
				zap.String("provider", key))
			continue
		}

		creds := oauthadapter.ProviderCredentials{
			ClientID:     clientID,
			ClientSecret: clientSecret,
			RedirectURI:  redirectURI,
			Scopes:       append([]string(nil), provider.Scopes...),
		}
		providerConfigs[key] = creds
	}

	if len(providerConfigs) == 0 {
		return nil, nil
	}

	allowed := make([]string, 0, len(cfg.OAuth.AllowedProviders))
	for _, name := range cfg.OAuth.AllowedProviders {
		if trimmed := strings.ToLower(strings.TrimSpace(name)); trimmed != "" {
			allowed = append(allowed, trimmed)
		}
	}

	managerCfg := oauthadapter.ManagerConfig{
		Allowed:   allowed,
		Providers: providerConfigs,
	}

	manager, err := oauthadapter.NewManager(oauthadapter.BuiltIn(), managerCfg)
	if err != nil {
		return nil, err
	}
	return manager, nil
}

func parseSameSite(mode string) http.SameSite {
	switch strings.ToLower(strings.TrimSpace(mode)) {
	case "strict":
		return http.SameSiteStrictMode
	case "none":
		return http.SameSiteNoneMode
	case "lax":
		fallthrough
	default:
		return http.SameSiteLaxMode
	}
}

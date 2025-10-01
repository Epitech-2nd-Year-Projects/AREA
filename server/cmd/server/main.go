package main

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/adapters/inbound/http/router"
	configviper "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/platform/config/viper"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/platform/database/postgres"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/platform/httpserver"
	ginhttp "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/platform/httpserver/gin"
	projectlogging "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/platform/logging"
	projectlogger "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/platform/logging/zap"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/platform/services/catalog"
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

	var loaders []catalog.Loader

	dbCtx := context.Background()
	db, dbErr := postgres.Open(dbCtx, cfg.Database)
	if dbErr != nil {
		logger.Warn("postgres connection unavailable", zap.Error(dbErr))
	} else {
		loaders = append(loaders, catalog.DBLoader{DB: db})
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
		AboutLoader: catalog.NewChainLoader(loaders...),
	}); err != nil {
		return fmt.Errorf("router.Register: %w", err)
	}

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

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

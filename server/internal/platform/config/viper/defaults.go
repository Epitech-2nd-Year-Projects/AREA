package configviper

import (
	"time"

	"github.com/spf13/viper"
)

var _defaultConfig = Config{
	App: AppConfig{
		Name:        "AREA Server",
		Environment: "development",
		BaseURL:     "http://localhost:8080",
	},
	Server: ServerConfig{
		HTTP: HTTPConfig{
			Host:         "0.0.0.0",
			Port:         8080,
			ReadTimeout:  15 * time.Second,
			WriteTimeout: 15 * time.Second,
			IdleTimeout:  60 * time.Second,
			CORS: HTTPCORSConfig{
				AllowedOrigins:   []string{"http://localhost:8081"},
				AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
				AllowedHeaders:   []string{"Authorization", "Content-Type"},
				AllowCredentials: true,
			},
		},
		Telemetry: TelemetryConfig{
			Tracing: TracingConfig{
				Enabled:  true,
				Exporter: "otlp",
				Endpoint: "http://localhost:4317",
			},
			Metrics: MetricsConfig{
				Enabled:  true,
				Exporter: "prometheus",
				Endpoint: ":9464",
			},
			SamplingRatio: 0.2,
		},
	},
	Database: DatabaseConfig{
		Driver:          "postgres",
		Host:            "localhost",
		Port:            5432,
		Name:            "area",
		UserEnv:         "DATABASE_USER",
		PasswordEnv:     "DATABASE_PASSWORD",
		DSNEnv:          "DATABASE_URL",
		SSLMode:         "disable",
		MaxOpenConns:    25,
		MaxIdleConns:    25,
		ConnMaxLifetime: 30 * time.Minute,
		ConnMaxIdleTime: 10 * time.Minute,
	},
	Logging: LoggingConfig{
		Level:         "info",
		Format:        "text",
		Pretty:        false,
		IncludeCaller: false,
		DefaultFields: map[string]string{"service": "area-server"},
	},
	Queue: QueueConfig{
		Driver: "redis",
		Redis: RedisQueueConfig{
			Addr:          "localhost:6379",
			DB:            0,
			PasswordEnv:   "REDIS_PASSWORD",
			ConsumerGroup: "area-workers",
			Stream:        "area-jobs",
		},
	},
	Notifier: NotifierConfig{
		Webhook: WebhookConfig{
			Timeout:      10 * time.Second,
			MaxRetries:   5,
			RetryBackoff: 2 * time.Second,
		},
		Mailer: MailerConfig{
			Provider:    "sendgrid",
			FromEmail:   "noreply@area.local",
			SandboxMode: true,
			APIKeyEnv:   "SENDGRID_API_KEY",
		},
	},
	Secrets: SecretsConfig{
		Provider: "dotenv",
		Path:     ".env",
	},
	OAuth: OAuthConfig{
		AllowedProviders: []string{"google", "github", "gitlab", "dropbox", "slack", "spotify", "notion", "zoom", "linear", "microsoft"},
		Providers: map[string]OAuthProviderConfig{
			"google": {
				ClientIDEnv:     "GOOGLE_OAUTH_CLIENT_ID",
				ClientSecretEnv: "GOOGLE_OAUTH_CLIENT_SECRET",
				RedirectURI:     "http://localhost:8080/oauth/google/callback",
				Scopes:          []string{"email", "profile", "https://www.googleapis.com/auth/gmail.send"},
			},
			"github": {
				ClientIDEnv:     "GITHUB_OAUTH_CLIENT_ID",
				ClientSecretEnv: "GITHUB_OAUTH_CLIENT_SECRET",
				RedirectURI:     "http://localhost:8080/oauth/github/callback",
				Scopes:          []string{"read:user", "user:email", "repo"},
			},
			"gitlab": {
				ClientIDEnv:     "GITLAB_OAUTH_CLIENT_ID",
				ClientSecretEnv: "GITLAB_OAUTH_CLIENT_SECRET",
				RedirectURI:     "http://localhost:8080/oauth/gitlab/callback",
				Scopes:          []string{"read_user", "api"},
			},
			"dropbox": {
				ClientIDEnv:     "DROPBOX_OAUTH_CLIENT_ID",
				ClientSecretEnv: "DROPBOX_OAUTH_CLIENT_SECRET",
				RedirectURI:     "http://localhost:8080/oauth/dropbox/callback",
				Scopes:          []string{"account_info.read", "files.metadata.read", "files.metadata.write"},
			},
			"slack": {
				ClientIDEnv:     "SLACK_OAUTH_CLIENT_ID",
				ClientSecretEnv: "SLACK_OAUTH_CLIENT_SECRET",
				RedirectURI:     "http://localhost:8080/oauth/slack/callback",
				Scopes: []string{
					"chat:write",
					"channels:history",
					"groups:history",
					"im:history",
					"mpim:history",
					"users:read",
					"offline_access",
				},
			},
			"spotify": {
				ClientIDEnv:     "SPOTIFY_OAUTH_CLIENT_ID",
				ClientSecretEnv: "SPOTIFY_OAUTH_CLIENT_SECRET",
				RedirectURI:     "http://localhost:8080/oauth/spotify/callback",
				Scopes: []string{
					"user-read-email",
					"user-read-private",
					"user-library-read",
					"playlist-modify-public",
					"playlist-modify-private",
				},
			},
			"notion": {
				ClientIDEnv:     "NOTION_OAUTH_CLIENT_ID",
				ClientSecretEnv: "NOTION_OAUTH_CLIENT_SECRET",
				RedirectURI:     "http://localhost:8080/oauth/notion/callback",
				Scopes:          []string{"read", "write"},
			},
			"microsoft": {
				ClientIDEnv:     "MICROSOFT_OAUTH_CLIENT_ID",
				ClientSecretEnv: "MICROSOFT_OAUTH_CLIENT_SECRET",
				RedirectURI:     "http://localhost:8080/oauth/microsoft/callback",
				Scopes: []string{
					"offline_access",
					"openid",
					"profile",
					"email",
					"Mail.Read",
					"Mail.Send",
				},
			},
			"zoom": {
				ClientIDEnv:     "ZOOM_OAUTH_CLIENT_ID",
				ClientSecretEnv: "ZOOM_OAUTH_CLIENT_SECRET",
				RedirectURI:     "http://localhost:8080/oauth/zoom/callback",
			},
			"linear": {
				ClientIDEnv:     "LINEAR_OAUTH_CLIENT_ID",
				ClientSecretEnv: "LINEAR_OAUTH_CLIENT_SECRET",
				RedirectURI:     "http://localhost:8080/oauth/linear/callback",
				Scopes:          []string{"read", "write", "issues:read", "issues:create", "offline_access"},
			},
		},
	},
	Security: SecurityConfig{
		JWT: JWTConfig{
			Issuer:           "area-api",
			AccessTokenTTL:   15 * time.Minute,
			RefreshTokenTTL:  720 * time.Hour,
			AccessSecretEnv:  "JWT_ACCESS_SECRET",
			RefreshSecretEnv: "JWT_REFRESH_SECRET",
		},
		Password: PasswordConfig{
			MinLength: 12,
			PepperEnv: "PASSWORD_PEPPER",
		},
		Sessions: SessionConfig{
			CookieName: "area_session",
			Path:       "/",
			Secure:     false,
			HTTPOnly:   true,
			SameSite:   "lax",
			TTL:        168 * time.Hour,
		},
		Verification: VerificationConfig{
			TokenTTL: 48 * time.Hour,
		},
		Encryption: EncryptionConfig{
			IdentitiesKeyEnv: "IDENTITY_ENCRYPTION_KEY",
		},
	},
	ServicesCatalog: ServicesCatalogConfig{
		RefreshInterval: 5 * time.Minute,
		BootstrapFile:   "",
	},
}

func applyDefaults(v *viper.Viper) {
	v.SetDefault("app.name", _defaultConfig.App.Name)
	v.SetDefault("app.environment", _defaultConfig.App.Environment)
	v.SetDefault("app.baseURL", _defaultConfig.App.BaseURL)

	v.SetDefault("server.http.host", _defaultConfig.Server.HTTP.Host)
	v.SetDefault("server.http.port", _defaultConfig.Server.HTTP.Port)
	v.SetDefault("server.http.readTimeout", _defaultConfig.Server.HTTP.ReadTimeout.String())
	v.SetDefault("server.http.writeTimeout", _defaultConfig.Server.HTTP.WriteTimeout.String())
	v.SetDefault("server.http.idleTimeout", _defaultConfig.Server.HTTP.IdleTimeout.String())
	v.SetDefault("server.http.cors.allowedOrigins", _defaultConfig.Server.HTTP.CORS.AllowedOrigins)
	v.SetDefault("server.http.cors.allowedMethods", _defaultConfig.Server.HTTP.CORS.AllowedMethods)
	v.SetDefault("server.http.cors.allowedHeaders", _defaultConfig.Server.HTTP.CORS.AllowedHeaders)
	v.SetDefault("server.http.cors.allowCredentials", _defaultConfig.Server.HTTP.CORS.AllowCredentials)

	v.SetDefault("server.telemetry.tracing.enabled", _defaultConfig.Server.Telemetry.Tracing.Enabled)
	v.SetDefault("server.telemetry.tracing.exporter", _defaultConfig.Server.Telemetry.Tracing.Exporter)
	v.SetDefault("server.telemetry.tracing.endpoint", _defaultConfig.Server.Telemetry.Tracing.Endpoint)
	v.SetDefault("server.telemetry.metrics.enabled", _defaultConfig.Server.Telemetry.Metrics.Enabled)
	v.SetDefault("server.telemetry.metrics.exporter", _defaultConfig.Server.Telemetry.Metrics.Exporter)
	v.SetDefault("server.telemetry.metrics.endpoint", _defaultConfig.Server.Telemetry.Metrics.Endpoint)
	v.SetDefault("server.telemetry.samplingRatio", _defaultConfig.Server.Telemetry.SamplingRatio)

	v.SetDefault("database.driver", _defaultConfig.Database.Driver)
	v.SetDefault("database.host", _defaultConfig.Database.Host)
	v.SetDefault("database.port", _defaultConfig.Database.Port)
	v.SetDefault("database.name", _defaultConfig.Database.Name)
	v.SetDefault("database.userEnv", _defaultConfig.Database.UserEnv)
	v.SetDefault("database.passwordEnv", _defaultConfig.Database.PasswordEnv)
	v.SetDefault("database.dsnEnv", _defaultConfig.Database.DSNEnv)
	v.SetDefault("database.sslMode", _defaultConfig.Database.SSLMode)
	v.SetDefault("database.maxOpenConns", _defaultConfig.Database.MaxOpenConns)
	v.SetDefault("database.maxIdleConns", _defaultConfig.Database.MaxIdleConns)
	v.SetDefault("database.connMaxLifetime", _defaultConfig.Database.ConnMaxLifetime.String())
	v.SetDefault("database.connMaxIdleTime", _defaultConfig.Database.ConnMaxIdleTime.String())

	v.SetDefault("logging.level", _defaultConfig.Logging.Level)
	v.SetDefault("logging.format", _defaultConfig.Logging.Format)
	v.SetDefault("logging.pretty", _defaultConfig.Logging.Pretty)
	v.SetDefault("logging.includeCaller", _defaultConfig.Logging.IncludeCaller)
	v.SetDefault("logging.defaultFields", _defaultConfig.Logging.DefaultFields)

	v.SetDefault("queue.driver", _defaultConfig.Queue.Driver)
	v.SetDefault("queue.redis.addr", _defaultConfig.Queue.Redis.Addr)
	v.SetDefault("queue.redis.db", _defaultConfig.Queue.Redis.DB)
	v.SetDefault("queue.redis.passwordEnv", _defaultConfig.Queue.Redis.PasswordEnv)
	v.SetDefault("queue.redis.consumerGroup", _defaultConfig.Queue.Redis.ConsumerGroup)
	v.SetDefault("queue.redis.stream", _defaultConfig.Queue.Redis.Stream)

	v.SetDefault("notifier.webhook.timeout", _defaultConfig.Notifier.Webhook.Timeout.String())
	v.SetDefault("notifier.webhook.maxRetries", _defaultConfig.Notifier.Webhook.MaxRetries)
	v.SetDefault("notifier.webhook.retryBackoff", _defaultConfig.Notifier.Webhook.RetryBackoff.String())
	v.SetDefault("notifier.mailer.provider", _defaultConfig.Notifier.Mailer.Provider)
	v.SetDefault("notifier.mailer.fromEmail", _defaultConfig.Notifier.Mailer.FromEmail)
	v.SetDefault("notifier.mailer.sandboxMode", _defaultConfig.Notifier.Mailer.SandboxMode)
	v.SetDefault("notifier.mailer.apiKeyEnv", _defaultConfig.Notifier.Mailer.APIKeyEnv)

	v.SetDefault("secrets.provider", _defaultConfig.Secrets.Provider)
	v.SetDefault("secrets.path", _defaultConfig.Secrets.Path)

	v.SetDefault("oauth.allowedProviders", _defaultConfig.OAuth.AllowedProviders)
	v.SetDefault("oauth.providers.google.clientIDEnv", _defaultConfig.OAuth.Providers["google"].ClientIDEnv)
	v.SetDefault("oauth.providers.google.clientSecretEnv", _defaultConfig.OAuth.Providers["google"].ClientSecretEnv)
	v.SetDefault("oauth.providers.google.redirectURI", _defaultConfig.OAuth.Providers["google"].RedirectURI)
	v.SetDefault("oauth.providers.google.scopes", _defaultConfig.OAuth.Providers["google"].Scopes)
	v.SetDefault("oauth.providers.github.clientIDEnv", _defaultConfig.OAuth.Providers["github"].ClientIDEnv)
	v.SetDefault("oauth.providers.github.clientSecretEnv", _defaultConfig.OAuth.Providers["github"].ClientSecretEnv)
	v.SetDefault("oauth.providers.github.redirectURI", _defaultConfig.OAuth.Providers["github"].RedirectURI)
	v.SetDefault("oauth.providers.github.scopes", _defaultConfig.OAuth.Providers["github"].Scopes)
	v.SetDefault("oauth.providers.gitlab.clientIDEnv", _defaultConfig.OAuth.Providers["gitlab"].ClientIDEnv)
	v.SetDefault("oauth.providers.gitlab.clientSecretEnv", _defaultConfig.OAuth.Providers["gitlab"].ClientSecretEnv)
	v.SetDefault("oauth.providers.gitlab.redirectURI", _defaultConfig.OAuth.Providers["gitlab"].RedirectURI)
	v.SetDefault("oauth.providers.gitlab.scopes", _defaultConfig.OAuth.Providers["gitlab"].Scopes)
	v.SetDefault("oauth.providers.dropbox.clientIDEnv", _defaultConfig.OAuth.Providers["dropbox"].ClientIDEnv)
	v.SetDefault("oauth.providers.dropbox.clientSecretEnv", _defaultConfig.OAuth.Providers["dropbox"].ClientSecretEnv)
	v.SetDefault("oauth.providers.dropbox.redirectURI", _defaultConfig.OAuth.Providers["dropbox"].RedirectURI)
	v.SetDefault("oauth.providers.dropbox.scopes", _defaultConfig.OAuth.Providers["dropbox"].Scopes)
	v.SetDefault("oauth.providers.slack.clientIDEnv", _defaultConfig.OAuth.Providers["slack"].ClientIDEnv)
	v.SetDefault("oauth.providers.slack.clientSecretEnv", _defaultConfig.OAuth.Providers["slack"].ClientSecretEnv)
	v.SetDefault("oauth.providers.slack.redirectURI", _defaultConfig.OAuth.Providers["slack"].RedirectURI)
	v.SetDefault("oauth.providers.slack.scopes", _defaultConfig.OAuth.Providers["slack"].Scopes)
	v.SetDefault("oauth.providers.spotify.clientIDEnv", _defaultConfig.OAuth.Providers["spotify"].ClientIDEnv)
	v.SetDefault("oauth.providers.spotify.clientSecretEnv", _defaultConfig.OAuth.Providers["spotify"].ClientSecretEnv)
	v.SetDefault("oauth.providers.spotify.redirectURI", _defaultConfig.OAuth.Providers["spotify"].RedirectURI)
	v.SetDefault("oauth.providers.spotify.scopes", _defaultConfig.OAuth.Providers["spotify"].Scopes)
	v.SetDefault("oauth.providers.notion.clientIDEnv", _defaultConfig.OAuth.Providers["notion"].ClientIDEnv)
	v.SetDefault("oauth.providers.notion.clientSecretEnv", _defaultConfig.OAuth.Providers["notion"].ClientSecretEnv)
	v.SetDefault("oauth.providers.notion.redirectURI", _defaultConfig.OAuth.Providers["notion"].RedirectURI)
	v.SetDefault("oauth.providers.notion.scopes", _defaultConfig.OAuth.Providers["notion"].Scopes)
	v.SetDefault("oauth.providers.microsoft.clientIDEnv", _defaultConfig.OAuth.Providers["microsoft"].ClientIDEnv)
	v.SetDefault("oauth.providers.microsoft.clientSecretEnv", _defaultConfig.OAuth.Providers["microsoft"].ClientSecretEnv)
	v.SetDefault("oauth.providers.microsoft.redirectURI", _defaultConfig.OAuth.Providers["microsoft"].RedirectURI)
	v.SetDefault("oauth.providers.microsoft.scopes", _defaultConfig.OAuth.Providers["microsoft"].Scopes)
	v.SetDefault("oauth.providers.zoom.clientIDEnv", _defaultConfig.OAuth.Providers["zoom"].ClientIDEnv)
	v.SetDefault("oauth.providers.zoom.clientSecretEnv", _defaultConfig.OAuth.Providers["zoom"].ClientSecretEnv)
	v.SetDefault("oauth.providers.zoom.redirectURI", _defaultConfig.OAuth.Providers["zoom"].RedirectURI)
	v.SetDefault("oauth.providers.zoom.scopes", _defaultConfig.OAuth.Providers["zoom"].Scopes)
	v.SetDefault("oauth.providers.linear.clientIDEnv", _defaultConfig.OAuth.Providers["linear"].ClientIDEnv)
	v.SetDefault("oauth.providers.linear.clientSecretEnv", _defaultConfig.OAuth.Providers["linear"].ClientSecretEnv)
	v.SetDefault("oauth.providers.linear.redirectURI", _defaultConfig.OAuth.Providers["linear"].RedirectURI)
	v.SetDefault("oauth.providers.linear.scopes", _defaultConfig.OAuth.Providers["linear"].Scopes)

	v.SetDefault("security.jwt.issuer", _defaultConfig.Security.JWT.Issuer)
	v.SetDefault("security.jwt.accessTokenTTL", _defaultConfig.Security.JWT.AccessTokenTTL.String())
	v.SetDefault("security.jwt.refreshTokenTTL", _defaultConfig.Security.JWT.RefreshTokenTTL.String())
	v.SetDefault("security.jwt.accessSecretEnv", _defaultConfig.Security.JWT.AccessSecretEnv)
	v.SetDefault("security.jwt.refreshSecretEnv", _defaultConfig.Security.JWT.RefreshSecretEnv)
	v.SetDefault("security.password.minLength", _defaultConfig.Security.Password.MinLength)
	v.SetDefault("security.password.pepperEnv", _defaultConfig.Security.Password.PepperEnv)
	v.SetDefault("security.sessions.cookieName", _defaultConfig.Security.Sessions.CookieName)
	v.SetDefault("security.sessions.domain", _defaultConfig.Security.Sessions.Domain)
	v.SetDefault("security.sessions.path", _defaultConfig.Security.Sessions.Path)
	v.SetDefault("security.sessions.secure", _defaultConfig.Security.Sessions.Secure)
	v.SetDefault("security.sessions.httpOnly", _defaultConfig.Security.Sessions.HTTPOnly)
	v.SetDefault("security.sessions.sameSite", _defaultConfig.Security.Sessions.SameSite)
	v.SetDefault("security.sessions.ttl", _defaultConfig.Security.Sessions.TTL.String())
	v.SetDefault("security.verification.tokenTTL", _defaultConfig.Security.Verification.TokenTTL.String())

	v.SetDefault("servicesCatalog.refreshInterval", _defaultConfig.ServicesCatalog.RefreshInterval.String())
	v.SetDefault("servicesCatalog.bootstrapFile", _defaultConfig.ServicesCatalog.BootstrapFile)
}

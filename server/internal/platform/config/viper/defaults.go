package configviper

import (
	"time"

	"github.com/spf13/viper"
)

var defaultConfig = Config{
	App: AppConfig{
		Name:        "AREA",
		Environment: "development",
		Version:     "dev",
	},
	HTTP: HTTPConfig{
		Host:           "0.0.0.0",
		Port:           8080,
		ReadTimeout:    10 * time.Second,
		WriteTimeout:   10 * time.Second,
		IdleTimeout:    60 * time.Second,
		AllowedOrigins: []string{"*"},
		PublicBaseURL:  "http://localhost:8080",
	},
	Database: DatabaseConfig{
		DSN:             "postgres://area:area@localhost:5432/area?sslmode=disable",
		MaxOpenConns:    25,
		MaxIdleConns:    25,
		ConnMaxLifetime: 30 * time.Minute,
		ConnMaxIdleTime: 10 * time.Minute,
		MigrationsPath:  "./migrations",
	},
	Logging: LoggingConfig{
		Level:  "info",
		Format: "json",
		Pretty: false,
	},
	Telemetry: TelemetryConfig{
		Enabled:           false,
		OTLPEndpoint:      "",
		ServiceName:       "area-server",
		ServiceVersion:    "dev",
		TracesSampleRatio: 1.0,
		MetricsInterval:   15 * time.Second,
	},
}

func applyDefaults(v *viper.Viper) {
	v.SetDefault("app.name", defaultConfig.App.Name)
	v.SetDefault("app.environment", defaultConfig.App.Environment)
	v.SetDefault("app.version", defaultConfig.App.Version)

	v.SetDefault("http.host", defaultConfig.HTTP.Host)
	v.SetDefault("http.port", defaultConfig.HTTP.Port)
	v.SetDefault("http.read_timeout", defaultConfig.HTTP.ReadTimeout.String())
	v.SetDefault("http.write_timeout", defaultConfig.HTTP.WriteTimeout.String())
	v.SetDefault("http.idle_timeout", defaultConfig.HTTP.IdleTimeout.String())
	v.SetDefault("http.allowed_origins", defaultConfig.HTTP.AllowedOrigins)
	v.SetDefault("http.public_base_url", defaultConfig.HTTP.PublicBaseURL)

	v.SetDefault("database.dsn", defaultConfig.Database.DSN)
	v.SetDefault("database.max_open_conns", defaultConfig.Database.MaxOpenConns)
	v.SetDefault("database.max_idle_conns", defaultConfig.Database.MaxIdleConns)
	v.SetDefault("database.conn_max_lifetime", defaultConfig.Database.ConnMaxLifetime.String())
	v.SetDefault("database.conn_max_idle_time", defaultConfig.Database.ConnMaxIdleTime.String())
	v.SetDefault("database.migrations_path", defaultConfig.Database.MigrationsPath)

	v.SetDefault("logging.level", defaultConfig.Logging.Level)
	v.SetDefault("logging.format", defaultConfig.Logging.Format)
	v.SetDefault("logging.pretty", defaultConfig.Logging.Pretty)

	v.SetDefault("telemetry.enabled", defaultConfig.Telemetry.Enabled)
	v.SetDefault("telemetry.otlp_endpoint", defaultConfig.Telemetry.OTLPEndpoint)
	v.SetDefault("telemetry.service_name", defaultConfig.Telemetry.ServiceName)
	v.SetDefault("telemetry.service_version", defaultConfig.Telemetry.ServiceVersion)
	v.SetDefault("telemetry.traces_sample_ratio", defaultConfig.Telemetry.TracesSampleRatio)
	v.SetDefault("telemetry.metrics_interval", defaultConfig.Telemetry.MetricsInterval.String())
}

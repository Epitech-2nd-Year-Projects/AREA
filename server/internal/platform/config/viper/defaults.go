package configviper

import (
	"time"

	"github.com/spf13/viper"
)

var _defaultConfig = Config{
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
	v.SetDefault("app.name", _defaultConfig.App.Name)
	v.SetDefault("app.environment", _defaultConfig.App.Environment)
	v.SetDefault("app.version", _defaultConfig.App.Version)

	v.SetDefault("http.host", _defaultConfig.HTTP.Host)
	v.SetDefault("http.port", _defaultConfig.HTTP.Port)
	v.SetDefault("http.read_timeout", _defaultConfig.HTTP.ReadTimeout.String())
	v.SetDefault("http.write_timeout", _defaultConfig.HTTP.WriteTimeout.String())
	v.SetDefault("http.idle_timeout", _defaultConfig.HTTP.IdleTimeout.String())
	v.SetDefault("http.allowed_origins", _defaultConfig.HTTP.AllowedOrigins)
	v.SetDefault("http.public_base_url", _defaultConfig.HTTP.PublicBaseURL)

	v.SetDefault("database.dsn", _defaultConfig.Database.DSN)
	v.SetDefault("database.max_open_conns", _defaultConfig.Database.MaxOpenConns)
	v.SetDefault("database.max_idle_conns", _defaultConfig.Database.MaxIdleConns)
	v.SetDefault("database.conn_max_lifetime", _defaultConfig.Database.ConnMaxLifetime.String())
	v.SetDefault("database.conn_max_idle_time", _defaultConfig.Database.ConnMaxIdleTime.String())
	v.SetDefault("database.migrations_path", _defaultConfig.Database.MigrationsPath)

	v.SetDefault("logging.level", _defaultConfig.Logging.Level)
	v.SetDefault("logging.format", _defaultConfig.Logging.Format)
	v.SetDefault("logging.pretty", _defaultConfig.Logging.Pretty)

	v.SetDefault("telemetry.enabled", _defaultConfig.Telemetry.Enabled)
	v.SetDefault("telemetry.otlp_endpoint", _defaultConfig.Telemetry.OTLPEndpoint)
	v.SetDefault("telemetry.service_name", _defaultConfig.Telemetry.ServiceName)
	v.SetDefault("telemetry.service_version", _defaultConfig.Telemetry.ServiceVersion)
	v.SetDefault("telemetry.traces_sample_ratio", _defaultConfig.Telemetry.TracesSampleRatio)
	v.SetDefault("telemetry.metrics_interval", _defaultConfig.Telemetry.MetricsInterval.String())
}

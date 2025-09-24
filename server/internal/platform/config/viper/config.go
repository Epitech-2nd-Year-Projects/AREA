package configviper

import "time"

// Config aggregates all runtime configuration for the AREA server
type Config struct {
	App       AppConfig       `mapstructure:"app"`
	HTTP      HTTPConfig      `mapstructure:"http"`
	Database  DatabaseConfig  `mapstructure:"database"`
	Logging   LoggingConfig   `mapstructure:"logging"`
	Telemetry TelemetryConfig `mapstructure:"telemetry"`
}

// AppConfig controls global application parameters
type AppConfig struct {
	Name        string `mapstructure:"name"`
	Environment string `mapstructure:"environment"`
	Version     string `mapstructure:"version"`
}

// HTTPConfig captures HTTP server runtime settings
type HTTPConfig struct {
	Host           string        `mapstructure:"host"`
	Port           int           `mapstructure:"port"`
	ReadTimeout    time.Duration `mapstructure:"read_timeout"`
	WriteTimeout   time.Duration `mapstructure:"write_timeout"`
	IdleTimeout    time.Duration `mapstructure:"idle_timeout"`
	AllowedOrigins []string      `mapstructure:"allowed_origins"`
	PublicBaseURL  string        `mapstructure:"public_base_url"`
}

// DatabaseConfig holds Postgres connectivity tuning parameters
type DatabaseConfig struct {
	DSN             string        `mapstructure:"dsn"`
	MaxOpenConns    int           `mapstructure:"max_open_conns"`
	MaxIdleConns    int           `mapstructure:"max_idle_conns"`
	ConnMaxLifetime time.Duration `mapstructure:"conn_max_lifetime"`
	ConnMaxIdleTime time.Duration `mapstructure:"conn_max_idle_time"`
	MigrationsPath  string        `mapstructure:"migrations_path"`
}

// LoggingConfig describes desired logging behavior
type LoggingConfig struct {
	Level  string `mapstructure:"level"`
	Format string `mapstructure:"format"`
	Pretty bool   `mapstructure:"pretty"`
}

// TelemetryConfig holds tracing and metrics exporter settings
type TelemetryConfig struct {
	Enabled           bool          `mapstructure:"enabled"`
	OTLPEndpoint      string        `mapstructure:"otlp_endpoint"`
	ServiceName       string        `mapstructure:"service_name"`
	ServiceVersion    string        `mapstructure:"service_version"`
	TracesSampleRatio float64       `mapstructure:"traces_sample_ratio"`
	MetricsInterval   time.Duration `mapstructure:"metrics_interval"`
}

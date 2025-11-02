package configviper

import "time"

// Config aggregates all runtime configuration for the AREA server
type Config struct {
	App             AppConfig             `mapstructure:"app"`
	Server          ServerConfig          `mapstructure:"server"`
	Database        DatabaseConfig        `mapstructure:"database"`
	Logging         LoggingConfig         `mapstructure:"logging"`
	Queue           QueueConfig           `mapstructure:"queue"`
	Notifier        NotifierConfig        `mapstructure:"notifier"`
	Secrets         SecretsConfig         `mapstructure:"secrets"`
	OAuth           OAuthConfig           `mapstructure:"oauth"`
	Security        SecurityConfig        `mapstructure:"security"`
	ServicesCatalog ServicesCatalogConfig `mapstructure:"servicesCatalog"`
}

// AppConfig controls global application parameters
type AppConfig struct {
	Name        string `mapstructure:"name"`
	Environment string `mapstructure:"environment"`
	BaseURL     string `mapstructure:"baseURL"`
}

// ServerConfig groups HTTP and telemetry configuration
type ServerConfig struct {
	HTTP      HTTPConfig      `mapstructure:"http"`
	Telemetry TelemetryConfig `mapstructure:"telemetry"`
}

// HTTPConfig captures HTTP server runtime settings
type HTTPConfig struct {
	Host         string              `mapstructure:"host"`
	Port         int                 `mapstructure:"port"`
	ReadTimeout  time.Duration       `mapstructure:"readTimeout"`
	WriteTimeout time.Duration       `mapstructure:"writeTimeout"`
	IdleTimeout  time.Duration       `mapstructure:"idleTimeout"`
	CORS         HTTPCORSConfig      `mapstructure:"cors"`
	RateLimit    HTTPRateLimitConfig `mapstructure:"rateLimit"`
}

// HTTPCORSConfig lists Cross-Origin Resource Sharing parameters
type HTTPCORSConfig struct {
	AllowedOrigins   []string `mapstructure:"allowedOrigins"`
	AllowedMethods   []string `mapstructure:"allowedMethods"`
	AllowedHeaders   []string `mapstructure:"allowedHeaders"`
	AllowCredentials bool     `mapstructure:"allowCredentials"`
}

// HTTPRateLimitConfig captures HTTP rate limiting thresholds
type HTTPRateLimitConfig struct {
	Enabled                bool          `mapstructure:"enabled"`
	RequestsPerMinute      int           `mapstructure:"requestsPerMinute"`
	BurstRequestsPerMinute int           `mapstructure:"burstRequestsPerMinute"`
	BurstWindow            time.Duration `mapstructure:"burstWindow"`
}

// TelemetryConfig holds tracing and metrics exporter settings
type TelemetryConfig struct {
	Tracing       TracingConfig `mapstructure:"tracing"`
	Metrics       MetricsConfig `mapstructure:"metrics"`
	SamplingRatio float64       `mapstructure:"samplingRatio"`
}

// TracingConfig configures the tracing exporter
type TracingConfig struct {
	Enabled  bool   `mapstructure:"enabled"`
	Exporter string `mapstructure:"exporter"`
	Endpoint string `mapstructure:"endpoint"`
}

// MetricsConfig configures the metrics exporter
type MetricsConfig struct {
	Enabled  bool   `mapstructure:"enabled"`
	Exporter string `mapstructure:"exporter"`
	Endpoint string `mapstructure:"endpoint"`
}

// DatabaseConfig holds Postgres connectivity tuning parameters
type DatabaseConfig struct {
	Driver          string        `mapstructure:"driver"`
	Host            string        `mapstructure:"host"`
	Port            int           `mapstructure:"port"`
	Name            string        `mapstructure:"name"`
	UserEnv         string        `mapstructure:"userEnv"`
	PasswordEnv     string        `mapstructure:"passwordEnv"`
	DSNEnv          string        `mapstructure:"dsnEnv"`
	SSLMode         string        `mapstructure:"sslMode"`
	MaxOpenConns    int           `mapstructure:"maxOpenConns"`
	MaxIdleConns    int           `mapstructure:"maxIdleConns"`
	ConnMaxLifetime time.Duration `mapstructure:"connMaxLifetime"`
	ConnMaxIdleTime time.Duration `mapstructure:"connMaxIdleTime"`
	User            string        `mapstructure:"-"`
	Password        string        `mapstructure:"-"`
	DSN             string        `mapstructure:"-"`
}

// LoggingConfig describes desired logging behavior
type LoggingConfig struct {
	Level         string            `mapstructure:"level"`
	Format        string            `mapstructure:"format"`
	Pretty        bool              `mapstructure:"pretty"`
	IncludeCaller bool              `mapstructure:"includeCaller"`
	DefaultFields map[string]string `mapstructure:"defaultFields"`
}

// QueueConfig controls background job queue drivers
type QueueConfig struct {
	Driver string           `mapstructure:"driver"`
	Redis  RedisQueueConfig `mapstructure:"redis"`
}

// RedisQueueConfig describes Redis-backed queues
type RedisQueueConfig struct {
	Addr          string `mapstructure:"addr"`
	DB            int    `mapstructure:"db"`
	PasswordEnv   string `mapstructure:"passwordEnv"`
	ConsumerGroup string `mapstructure:"consumerGroup"`
	Stream        string `mapstructure:"stream"`
	Password      string `mapstructure:"-"`
}

// NotifierConfig manages outbound notification providers
type NotifierConfig struct {
	Webhook WebhookConfig `mapstructure:"webhook"`
	Mailer  MailerConfig  `mapstructure:"mailer"`
}

// WebhookConfig tunes webhook retries
type WebhookConfig struct {
	Timeout      time.Duration `mapstructure:"timeout"`
	MaxRetries   int           `mapstructure:"maxRetries"`
	RetryBackoff time.Duration `mapstructure:"retryBackoff"`
}

// MailerConfig holds email provider settings
type MailerConfig struct {
	Provider    string `mapstructure:"provider"`
	FromEmail   string `mapstructure:"fromEmail"`
	SandboxMode bool   `mapstructure:"sandboxMode"`
	APIKeyEnv   string `mapstructure:"apiKeyEnv"`
	APIKey      string `mapstructure:"-"`
}

// SecretsConfig configures secret provider backends
type SecretsConfig struct {
	Provider string `mapstructure:"provider"`
	Path     string `mapstructure:"path"`
}

// OAuthConfig holds OAuth provider configuration
type OAuthConfig struct {
	AllowedProviders []string                       `mapstructure:"allowedProviders"`
	Providers        map[string]OAuthProviderConfig `mapstructure:"providers"`
}

// OAuthProviderConfig stores OAuth credentials and scopes
type OAuthProviderConfig struct {
	ClientIDEnv     string   `mapstructure:"clientIDEnv"`
	ClientSecretEnv string   `mapstructure:"clientSecretEnv"`
	RedirectURI     string   `mapstructure:"redirectURI"`
	Scopes          []string `mapstructure:"scopes"`
	ClientID        string   `mapstructure:"-"`
	ClientSecret    string   `mapstructure:"-"`
}

// SecurityConfig captures authentication-related configuration
type SecurityConfig struct {
	JWT          JWTConfig          `mapstructure:"jwt"`
	Password     PasswordConfig     `mapstructure:"password"`
	Sessions     SessionConfig      `mapstructure:"sessions"`
	Verification VerificationConfig `mapstructure:"verification"`
	Encryption   EncryptionConfig   `mapstructure:"encryption"`
}

// JWTConfig defines JWT token lifetimes and secrets
type JWTConfig struct {
	Issuer           string        `mapstructure:"issuer"`
	AccessTokenTTL   time.Duration `mapstructure:"accessTokenTTL"`
	RefreshTokenTTL  time.Duration `mapstructure:"refreshTokenTTL"`
	AccessSecretEnv  string        `mapstructure:"accessSecretEnv"`
	RefreshSecretEnv string        `mapstructure:"refreshSecretEnv"`
	AccessSecret     string        `mapstructure:"-"`
	RefreshSecret    string        `mapstructure:"-"`
}

// PasswordConfig stores password policy and pepper secret
type PasswordConfig struct {
	MinLength int    `mapstructure:"minLength"`
	PepperEnv string `mapstructure:"pepperEnv"`
	Pepper    string `mapstructure:"-"`
}

// SessionConfig controls cookie-based session issuance
type SessionConfig struct {
	CookieName string        `mapstructure:"cookieName"`
	Domain     string        `mapstructure:"domain"`
	Path       string        `mapstructure:"path"`
	Secure     bool          `mapstructure:"secure"`
	HTTPOnly   bool          `mapstructure:"httpOnly"`
	SameSite   string        `mapstructure:"sameSite"`
	TTL        time.Duration `mapstructure:"ttl"`
}

// VerificationConfig tunes email verification semantics
type VerificationConfig struct {
	TokenTTL time.Duration `mapstructure:"tokenTTL"`
}

// EncryptionConfig stores secrets used for encrypting persisted credentials
type EncryptionConfig struct {
	IdentitiesKeyEnv string `mapstructure:"identitiesKeyEnv"`
	IdentitiesKey    string `mapstructure:"-"`
}

// ServicesCatalogConfig configures service discovery bootstrap
type ServicesCatalogConfig struct {
	RefreshInterval time.Duration `mapstructure:"refreshInterval"`
	BootstrapFile   string        `mapstructure:"bootstrapFile"`
}

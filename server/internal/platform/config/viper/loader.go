package configviper

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/go-viper/mapstructure/v2"
	"github.com/spf13/viper"
	"github.com/subosito/gotenv"
)

const (
	_defaultEnvKeyDelimiter = "_"
	_configFileEnvSuffix    = "CONFIG_FILE"
)

// Load hydrates Config using Viper with layered sources defaults -> config file -> environment
func Load(opts ...Option) (Config, error) {
	options := defaultOptions()
	for _, opt := range opts {
		opt(&options)
	}

	configFile, err := resolveConfigFile(options)
	if err != nil {
		return Config{}, fmt.Errorf("resolveConfigFile: %w", err)
	}
	if configFile != "" {
		options.configFile = configFile
	}

	vp := viper.New()
	vp.SetConfigType(options.configType)

	applyDefaults(vp)

	replacer := strings.NewReplacer(".", _defaultEnvKeyDelimiter, "-", _defaultEnvKeyDelimiter)
	if options.envPrefix != "" {
		vp.SetEnvPrefix(options.envPrefix)
	}
	vp.SetEnvKeyReplacer(replacer)
	vp.AutomaticEnv()

	if options.configFile != "" {
		vp.SetConfigFile(options.configFile)
		if err := vp.ReadInConfig(); err != nil {
			return Config{}, fmt.Errorf("viper.ReadInConfig(%q): %w", options.configFile, err)
		}
	} else {
		vp.SetConfigName(options.configName)
		for _, path := range options.searchPaths {
			vp.AddConfigPath(path)
		}
		if err := vp.ReadInConfig(); err != nil {
			var notFound viper.ConfigFileNotFoundError
			if !errors.As(err, &notFound) {
				return Config{}, fmt.Errorf("viper.ReadInConfig(%q): %w", options.configName, err)
			}
		}
	}

	var cfg Config
	if err := vp.Unmarshal(&cfg, func(dec *mapstructure.DecoderConfig) {
		dec.TagName = "mapstructure"
		dec.DecodeHook = mapstructure.ComposeDecodeHookFunc(
			mapstructure.StringToTimeDurationHookFunc(),
			mapstructure.StringToSliceHookFunc(","),
		)
	}); err != nil {
		return Config{}, fmt.Errorf("viper.Unmarshal: %w", err)
	}

	if err := loadSecrets(cfg.Secrets); err != nil {
		return Config{}, fmt.Errorf("loadSecrets: %w", err)
	}

	if err := resolveSecrets(&cfg); err != nil {
		return Config{}, fmt.Errorf("resolveSecrets: %w", err)
	}

	normalizeConfig(&cfg)
	return cfg, nil
}

// MustLoad behaves like Load but panics if configuration cannot be hydrated
func MustLoad(opts ...Option) Config {
	cfg, err := Load(opts...)
	if err != nil {
		panic(err)
	}
	return cfg
}

func resolveConfigFile(opts options) (string, error) {
	if opts.configFile != "" {
		return opts.configFile, nil
	}
	if opts.envPrefix == "" {
		return "", nil
	}

	envKey := fmt.Sprintf("%s%s%s", strings.ToUpper(opts.envPrefix), _defaultEnvKeyDelimiter, _configFileEnvSuffix)
	candidate := strings.TrimSpace(os.Getenv(envKey))
	if candidate == "" {
		return "", nil
	}

	if !filepath.IsAbs(candidate) {
		abs, err := filepath.Abs(candidate)
		if err != nil {
			return "", fmt.Errorf("filepath.Abs(%q): %w", candidate, err)
		}
		candidate = abs
	}

	return candidate, nil
}

func normalizeConfig(cfg *Config) {
	if cfg == nil {
		return
	}

	if cfg.Logging.DefaultFields == nil {
		cfg.Logging.DefaultFields = map[string]string{}
	}
	if _, ok := cfg.Logging.DefaultFields["service"]; !ok {
		cfg.Logging.DefaultFields["service"] = "area-server"
	}

	if cfg.Queue.Redis.PasswordEnv == "" {
		cfg.Queue.Redis.PasswordEnv = _defaultConfig.Queue.Redis.PasswordEnv
	}

	if cfg.Secrets.Provider == "" {
		cfg.Secrets.Provider = _defaultConfig.Secrets.Provider
	}
	if cfg.Secrets.Path == "" {
		cfg.Secrets.Path = _defaultConfig.Secrets.Path
	}
}

func loadSecrets(cfg SecretsConfig) error {
	provider := strings.TrimSpace(cfg.Provider)
	if provider == "" {
		return nil
	}

	switch strings.ToLower(provider) {
	case "dotenv":
		path := strings.TrimSpace(cfg.Path)
		if path == "" {
			path = ".env"
		}
		if _, err := os.Stat(path); err != nil {
			if errors.Is(err, os.ErrNotExist) {
				return nil
			}
			return fmt.Errorf("stat %q: %w", path, err)
		}
		if err := gotenv.Load(path); err != nil {
			return fmt.Errorf("gotenv.Load(%q): %w", path, err)
		}
		return nil
	default:
		return fmt.Errorf("unsupported secrets provider %q", provider)
	}
}

func resolveSecrets(cfg *Config) error {
	if cfg == nil {
		return nil
	}

	if err := assignDatabaseSecrets(&cfg.Database); err != nil {
		return err
	}
	if err := assignQueueSecrets(&cfg.Queue); err != nil {
		return err
	}
	if err := assignNotifierSecrets(&cfg.Notifier); err != nil {
		return err
	}
	if err := assignOAuthSecrets(&cfg.OAuth); err != nil {
		return err
	}
	if err := assignSecuritySecrets(&cfg.Security); err != nil {
		return err
	}

	return nil
}

func assignDatabaseSecrets(cfg *DatabaseConfig) error {
	if cfg == nil {
		return nil
	}

	if secret, err := resolveEnv(cfg.DSNEnv, true); err != nil {
		return fmt.Errorf("database.dsnEnv: %w", err)
	} else if secret != "" {
		cfg.DSN = secret
	}

	if secret, err := resolveEnv(cfg.UserEnv, false); err != nil {
		return fmt.Errorf("database.userEnv: %w", err)
	} else if secret != "" {
		cfg.User = secret
	}

	if secret, err := resolveEnv(cfg.PasswordEnv, false); err != nil {
		return fmt.Errorf("database.passwordEnv: %w", err)
	} else if secret != "" {
		cfg.Password = secret
	}

	return nil
}

func assignQueueSecrets(cfg *QueueConfig) error {
	if cfg == nil {
		return nil
	}

	if secret, err := resolveEnv(cfg.Redis.PasswordEnv, false); err != nil {
		return fmt.Errorf("queue.redis.passwordEnv: %w", err)
	} else if secret != "" {
		cfg.Redis.Password = secret
	}

	return nil
}

func assignNotifierSecrets(cfg *NotifierConfig) error {
	if cfg == nil {
		return nil
	}

	if secret, err := resolveEnv(cfg.Mailer.APIKeyEnv, false); err != nil {
		return fmt.Errorf("notifier.mailer.apiKeyEnv: %w", err)
	} else if secret != "" {
		cfg.Mailer.APIKey = secret
	}

	return nil
}

func assignOAuthSecrets(cfg *OAuthConfig) error {
	if cfg == nil {
		return nil
	}

	for name, provider := range cfg.Providers {
		if secret, err := resolveEnv(provider.ClientIDEnv, false); err != nil {
			return fmt.Errorf("oauth.providers[%s].clientIDEnv: %w", name, err)
		} else if secret != "" {
			provider.ClientID = secret
		}
		if secret, err := resolveEnv(provider.ClientSecretEnv, false); err != nil {
			return fmt.Errorf("oauth.providers[%s].clientSecretEnv: %w", name, err)
		} else if secret != "" {
			provider.ClientSecret = secret
		}
		cfg.Providers[name] = provider
	}

	return nil
}

func assignSecuritySecrets(cfg *SecurityConfig) error {
	if cfg == nil {
		return nil
	}

	if secret, err := resolveEnv(cfg.JWT.AccessSecretEnv, true); err != nil {
		return fmt.Errorf("security.jwt.accessSecretEnv: %w", err)
	} else if secret != "" {
		cfg.JWT.AccessSecret = secret
	}

	if secret, err := resolveEnv(cfg.JWT.RefreshSecretEnv, true); err != nil {
		return fmt.Errorf("security.jwt.refreshSecretEnv: %w", err)
	} else if secret != "" {
		cfg.JWT.RefreshSecret = secret
	}

	if secret, err := resolveEnv(cfg.Password.PepperEnv, true); err != nil {
		return fmt.Errorf("security.password.pepperEnv: %w", err)
	} else if secret != "" {
		cfg.Password.Pepper = secret
	}

	return nil
}

func resolveEnv(key string, required bool) (string, error) {
	trimmed := strings.TrimSpace(key)
	if trimmed == "" {
		return "", nil
	}

	value, ok := os.LookupEnv(trimmed)
	if !ok {
		if required {
			return "", fmt.Errorf("environment variable %q not set", trimmed)
		}
		return "", nil
	}

	if required && strings.TrimSpace(value) == "" {
		return "", fmt.Errorf("environment variable %q is empty", trimmed)
	}

	return value, nil
}

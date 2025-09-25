package configviper

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/go-viper/mapstructure/v2"
	"github.com/spf13/viper"
)

const (
	defaultEnvKeyDelimiter = "_"
	configFileEnvSuffix    = "CONFIG_FILE"
)

// Load hydrates Config using Viper with layered sources defaults → config file → environment
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

	replacer := strings.NewReplacer(".", defaultEnvKeyDelimiter, "-", defaultEnvKeyDelimiter)
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

	envKey := fmt.Sprintf("%s%s%s", strings.ToUpper(opts.envPrefix), defaultEnvKeyDelimiter, configFileEnvSuffix)
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

	if cfg.Telemetry.ServiceName == "" {
		cfg.Telemetry.ServiceName = cfg.App.Name
	}
	if cfg.Telemetry.ServiceVersion == "" {
		cfg.Telemetry.ServiceVersion = cfg.App.Version
	}
}

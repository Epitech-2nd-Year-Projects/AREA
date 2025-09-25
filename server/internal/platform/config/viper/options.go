package configviper

// Option configures loader behavior
type Option func(*options)

type options struct {
	configFile  string
	searchPaths []string
	configName  string
	configType  string
	envPrefix   string
}

func defaultOptions() options {
	return options{
		configFile:  "",
		searchPaths: []string{".", "./config"},
		configName:  "config",
		configType:  "yaml",
		envPrefix:   "AREA",
	}
}

// WithConfigFile instructs the loader to read a specific config file path
func WithConfigFile(path string) Option {
	return func(o *options) {
		o.configFile = path
	}
}

// WithSearchPath adds an extra directory when resolving config files
func WithSearchPath(path string) Option {
	return func(o *options) {
		o.searchPaths = append(o.searchPaths, path)
	}
}

// WithConfigName overrides the default config file name
func WithConfigName(name string) Option {
	return func(o *options) {
		o.configName = name
	}
}

// WithConfigType sets the config file type used when parsing raw readers
func WithConfigType(configType string) Option {
	return func(o *options) {
		o.configType = configType
	}
}

// WithEnvPrefix changes the environment variable prefix used for overrides and defaults to AREA
func WithEnvPrefix(prefix string) Option {
	return func(o *options) {
		o.envPrefix = prefix
	}
}

package logging

import "strings"

// Config captures the runtime configuration for project logging
type Config struct {
	Level         string
	Format        string
	Pretty        bool
	IncludeCaller bool
	DefaultFields map[string]string
}

// Normalize applies defaults and canonicalises configuration values
func (c *Config) Normalize() {
	level := strings.ToLower(strings.TrimSpace(c.Level))
	if level == "" {
		c.Level = "info"
	} else {
		c.Level = level
	}

	format := strings.ToLower(strings.TrimSpace(c.Format))
	if format == "" {
		c.Format = "json"
	} else {
		c.Format = format
	}

	if c.DefaultFields == nil {
		c.DefaultFields = make(map[string]string)
	}
}

func cloneFields(src map[string]string) map[string]string {
	if len(src) == 0 {
		return nil
	}
	clone := make(map[string]string, len(src))
	for k, v := range src {
		clone[k] = v
	}
	return clone
}

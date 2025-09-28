package httpserver

import (
	"fmt"
	"strings"
	"time"
)

// Config captures the runtime configuration of the HTTP server
type Config struct {
	Host            string
	Port            int
	ReadTimeout     time.Duration
	WriteTimeout    time.Duration
	IdleTimeout     time.Duration
	ShutdownTimeout time.Duration
	Mode            Mode
	CORS            CORSConfig
}

// CORSConfig configures Cross-Origin Resource Sharing behaviour
type CORSConfig struct {
	AllowedOrigins   []string
	AllowedMethods   []string
	AllowedHeaders   []string
	AllowCredentials bool
}

// Mode describes the runtime mode of the Gin engine
type Mode string

const (
	ModeDebug   Mode = "debug"
	ModeRelease Mode = "release"
	ModeTest    Mode = "test"
)

// Normalize ensures the configuration contains sane defaults
func (c *Config) Normalize() {
	if c.Mode == "" {
		c.Mode = ModeDebug
	}
	if c.ShutdownTimeout <= 0 {
		c.ShutdownTimeout = 15 * time.Second
	}
	if len(c.CORS.AllowedMethods) == 0 {
		c.CORS.AllowedMethods = []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"}
	}
	if len(c.CORS.AllowedHeaders) == 0 {
		c.CORS.AllowedHeaders = []string{"Accept", "Authorization", "Content-Type", "X-Request-ID"}
	}
}

// Address renders the host and port into a listen address understood by net/http
func (c Config) Address() string {
	host := strings.TrimSpace(c.Host)
	if host == "" {
		return fmt.Sprintf(":%d", c.Port)
	}
	if strings.Contains(host, ":") {
		return fmt.Sprintf("[%s]:%d", strings.Trim(host, "[]"), c.Port)
	}
	return fmt.Sprintf("%s:%d", host, c.Port)
}

// ModeFromEnvironment derives a Gin mode from the application environment label
func ModeFromEnvironment(env string) Mode {
	normalized := strings.ToLower(strings.TrimSpace(env))
	switch normalized {
	case "prod", "production":
		return ModeRelease
	case "test", "testing":
		return ModeTest
	default:
		return ModeDebug
	}
}

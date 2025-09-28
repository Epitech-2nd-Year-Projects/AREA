package httpserver

import (
	"testing"
	"time"
)

func TestConfigNormalizeDefaults(t *testing.T) {
	cfg := Config{}
	cfg.Normalize()

	if cfg.Mode != ModeDebug {
		t.Fatalf("expected default mode %q got %q", ModeDebug, cfg.Mode)
	}
	if cfg.ShutdownTimeout != 15*time.Second {
		t.Fatalf("expected shutdown timeout 15s got %s", cfg.ShutdownTimeout)
	}
	if len(cfg.CORS.AllowedMethods) == 0 {
		t.Fatalf("expected default allowed methods to be set")
	}
	if len(cfg.CORS.AllowedHeaders) == 0 {
		t.Fatalf("expected default allowed headers to be set")
	}
}

func TestConfigAddress(t *testing.T) {
	tests := []struct {
		name string
		cfg  Config
		want string
	}{
		{
			name: "empty host with port",
			cfg:  Config{Port: 8080},
			want: ":8080",
		},
		{
			name: "host only",
			cfg:  Config{Host: "0.0.0.0"},
			want: "0.0.0.0:0",
		},
		{
			name: "ipv6 host",
			cfg:  Config{Host: "::1", Port: 9090},
			want: "[::1]:9090",
		},
		{
			name: "explicit host and port",
			cfg:  Config{Host: "example.com", Port: 80},
			want: "example.com:80",
		},
		{
			name: "zero values",
			cfg:  Config{},
			want: ":0",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := tt.cfg.Address(); got != tt.want {
				t.Fatalf("expected address %q got %q", tt.want, got)
			}
		})
	}
}

func TestModeFromEnvironment(t *testing.T) {
	tests := map[string]Mode{
		"production": ModeRelease,
		"prod":       ModeRelease,
		"test":       ModeTest,
		"testing":    ModeTest,
		"":           ModeDebug,
		"local":      ModeDebug,
	}

	for input, want := range tests {
		if got := ModeFromEnvironment(input); got != want {
			t.Fatalf("modeFromEnvironment(%q) = %q want %q", input, got, want)
		}
	}
}

package configviper

import (
	"os"
	"path/filepath"
	"testing"
	"time"
)

func TestLoadDefaults(t *testing.T) {
	t.Setenv("AREA_CONFIG_FILE", "")

	cfg, err := Load()
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	if cfg.Database.DSN != defaultConfig.Database.DSN {
		t.Fatalf("unexpected database DSN: %q", cfg.Database.DSN)
	}

	if cfg.HTTP.Port != defaultConfig.HTTP.Port {
		t.Fatalf("expected http port %d got %d", defaultConfig.HTTP.Port, cfg.HTTP.Port)
	}

	if cfg.HTTP.ReadTimeout != defaultConfig.HTTP.ReadTimeout {
		t.Fatalf("expected http read timeout %s got %s", defaultConfig.HTTP.ReadTimeout, cfg.HTTP.ReadTimeout)
	}

	if cfg.Telemetry.ServiceName != defaultConfig.Telemetry.ServiceName {
		t.Fatalf("expected telemetry service name %q got %q", defaultConfig.Telemetry.ServiceName, cfg.Telemetry.ServiceName)
	}
}

func TestLoadWithConfigFile(t *testing.T) {
	dir := t.TempDir()
	configPath := filepath.Join(dir, "config.yaml")

	content := `app:
  name: AREA E2E
http:
  port: 9090
  read_timeout: 5s
`

	if err := os.WriteFile(configPath, []byte(content), 0o600); err != nil {
		t.Fatalf("write config: %v", err)
	}

	cfg, err := Load(WithConfigFile(configPath))
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	if got, want := cfg.App.Name, "AREA E2E"; got != want {
		t.Fatalf("expected app name %q got %q", want, got)
	}

	if got, want := cfg.HTTP.Port, 9090; got != want {
		t.Fatalf("expected http port %d got %d", want, got)
	}

	if got, want := cfg.HTTP.ReadTimeout, 5*time.Second; got != want {
		t.Fatalf("expected http read timeout %s got %s", want, got)
	}
}

func TestLoadWithEnvOverrides(t *testing.T) {
	t.Setenv("AREA_HTTP_PORT", "7070")
	t.Setenv("AREA_HTTP_ALLOWED_ORIGINS", "https://example.com,https://app.local")

	cfg, err := Load()
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	if got, want := cfg.HTTP.Port, 7070; got != want {
		t.Fatalf("expected http port %d got %d", want, got)
	}

	if got := cfg.HTTP.AllowedOrigins; len(got) != 2 {
		t.Fatalf("expected 2 allowed origins, got %d", len(got))
	}
}

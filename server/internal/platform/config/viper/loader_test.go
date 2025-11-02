package configviper

import (
	"os"
	"path/filepath"
	"testing"
	"time"
)

const (
	fakeDatabaseDSN   = "postgres://area_app:change-me@localhost:5432/area?sslmode=disable"
	fakeAccessSecret  = "fake-access-secret"
	fakeRefreshSecret = "fake-refresh-secret"
	fakePepper        = "fake-pepper"
)

func setRequiredSecrets(t *testing.T) {
	t.Helper()

	t.Setenv("DATABASE_URL", fakeDatabaseDSN)
	t.Setenv("JWT_ACCESS_SECRET", fakeAccessSecret)
	t.Setenv("JWT_REFRESH_SECRET", fakeRefreshSecret)
	t.Setenv("PASSWORD_PEPPER", fakePepper)
	t.Setenv("IDENTITY_ENCRYPTION_KEY", "MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTI=")
}

func TestLoadDefaults(t *testing.T) {
	t.Setenv("AREA_CONFIG_FILE", "")
	setRequiredSecrets(t)

	cfg, err := Load()
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	if cfg.Database.DSN != fakeDatabaseDSN {
		t.Fatalf("unexpected database DSN: %q", cfg.Database.DSN)
	}

	if cfg.Server.HTTP.Port != _defaultConfig.Server.HTTP.Port {
		t.Fatalf("expected http port %d got %d", _defaultConfig.Server.HTTP.Port, cfg.Server.HTTP.Port)
	}

	if cfg.Server.HTTP.ReadTimeout != _defaultConfig.Server.HTTP.ReadTimeout {
		t.Fatalf("expected http read timeout %s got %s", _defaultConfig.Server.HTTP.ReadTimeout, cfg.Server.HTTP.ReadTimeout)
	}

	if cfg.Security.JWT.AccessSecret != fakeAccessSecret {
		t.Fatalf("expected access secret %q got %q", fakeAccessSecret, cfg.Security.JWT.AccessSecret)
	}
}

func TestLoadWithConfigFile(t *testing.T) {
	dir := t.TempDir()
	configPath := filepath.Join(dir, "config.yaml")

	content := `app:
  name: AREA E2E
server:
  http:
    port: 9090
    readTimeout: 5s
`

	if err := os.WriteFile(configPath, []byte(content), 0o600); err != nil {
		t.Fatalf("write config: %v", err)
	}

	setRequiredSecrets(t)

	cfg, err := Load(WithConfigFile(configPath))
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	if got, want := cfg.App.Name, "AREA E2E"; got != want {
		t.Fatalf("expected app name %q got %q", want, got)
	}

	if got, want := cfg.Server.HTTP.Port, 9090; got != want {
		t.Fatalf("expected http port %d got %d", want, got)
	}

	if got, want := cfg.Server.HTTP.ReadTimeout, 5*time.Second; got != want {
		t.Fatalf("expected http read timeout %s got %s", want, got)
	}
}

func TestLoadWithEnvOverrides(t *testing.T) {
	setRequiredSecrets(t)
	t.Setenv("AREA_SERVER_HTTP_PORT", "7070")
	t.Setenv("AREA_SERVER_HTTP_CORS_ALLOWEDORIGINS", "https://example.com,https://app.local")

	cfg, err := Load()
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	if got, want := cfg.Server.HTTP.Port, 7070; got != want {
		t.Fatalf("expected http port %d got %d", want, got)
	}

	if got := cfg.Server.HTTP.CORS.AllowedOrigins; len(got) != 2 {
		t.Fatalf("expected 2 allowed origins, got %d", len(got))
	}
}

package main

import (
	"net/http"
	"reflect"
	"testing"

	loggerMailer "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/adapters/outbound/mailer/logger"
	sendgridMailer "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/adapters/outbound/mailer/sendgrid"
	configviper "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/platform/config/viper"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
	"go.uber.org/zap/zaptest/observer"
)

func TestParseSameSite(t *testing.T) {
	t.Parallel()

	cases := []struct {
		input string
		want  http.SameSite
	}{
		{input: "", want: http.SameSiteLaxMode},
		{input: "  LAX  ", want: http.SameSiteLaxMode},
		{input: "strict", want: http.SameSiteStrictMode},
		{input: "NONE", want: http.SameSiteNoneMode},
		{input: "invalid", want: http.SameSiteLaxMode},
	}

	for _, tc := range cases {
		tc := tc
		t.Run(tc.input, func(t *testing.T) {
			if got := parseSameSite(tc.input); got != tc.want {
				t.Fatalf("parseSameSite(%q) = %v, want %v", tc.input, got, tc.want)
			}
		})
	}
}

func TestBuildMailerSendgrid(t *testing.T) {
	cfg := configviper.Config{
		App: configviper.AppConfig{Name: "AREA"},
		Notifier: configviper.NotifierConfig{
			Mailer: configviper.MailerConfig{
				Provider:    "sendgrid",
				FromEmail:   "noreply@example.com",
				SandboxMode: true,
				APIKey:      "api-key",
			},
		},
	}

	mailer := buildMailer(cfg, zap.NewNop())
	sg, ok := mailer.(sendgridMailer.Mailer)
	if !ok {
		t.Fatalf("expected sendgrid mailer, got %T", mailer)
	}
	if sg.APIKey != "api-key" || sg.FromEmail != "noreply@example.com" || sg.Sandbox != true {
		t.Fatalf("unexpected sendgrid mailer config: %#v", sg)
	}
}

func TestBuildMailerDefaultLogger(t *testing.T) {
	logger := zap.NewNop()
	cfg := configviper.Config{
		Notifier: configviper.NotifierConfig{
			Mailer: configviper.MailerConfig{
				Provider: "unknown",
			},
		},
	}

	mailer := buildMailer(cfg, logger)
	if _, ok := mailer.(loggerMailer.Mailer); !ok {
		t.Fatalf("expected logger mailer, got %T", mailer)
	}
}

func TestBuildOAuthManagerSuccess(t *testing.T) {
	cfg := configviper.Config{
		OAuth: configviper.OAuthConfig{
			AllowedProviders: []string{" GitHub "},
			Providers: map[string]configviper.OAuthProviderConfig{
				"GitHub": {
					ClientID:     "client-id",
					ClientSecret: "client-secret",
					RedirectURI:  "https://example.com/callback",
					Scopes:       []string{"repo"},
				},
			},
		},
	}

	manager, err := buildOAuthManager(cfg, zap.NewNop())
	if err != nil {
		t.Fatalf("buildOAuthManager() error = %v", err)
	}
	if manager == nil {
		t.Fatal("buildOAuthManager() returned nil manager")
	}

	names := manager.Names()
	if len(names) != 1 || names[0] != "github" {
		t.Fatalf("manager.Names() = %v, want [github]", names)
	}

	if provider, ok := manager.Provider("GitHub"); !ok || provider == nil {
		t.Fatalf("expected provider GitHub to be registered")
	}
}

func TestBuildOAuthManagerSkipsIncompleteProviders(t *testing.T) {
	core, logs := observer.New(zapcore.DebugLevel)
	logger := zap.New(core)

	cfg := configviper.Config{
		OAuth: configviper.OAuthConfig{
			Providers: map[string]configviper.OAuthProviderConfig{
				"google": {
					ClientID: "client-id",
					// Missing secret and redirect URI
				},
			},
		},
	}

	manager, err := buildOAuthManager(cfg, logger)
	if err != nil {
		t.Fatalf("buildOAuthManager() error = %v", err)
	}
	if manager != nil {
		t.Fatalf("expected nil manager, got %#v", manager)
	}
	if logs.Len() == 0 {
		t.Fatal("expected warning log for incomplete provider configuration")
	}
}

func TestBuildOAuthManagerReturnsErrorFromFactory(t *testing.T) {
	cfg := configviper.Config{
		OAuth: configviper.OAuthConfig{
			AllowedProviders: []string{"unknown"},
			Providers: map[string]configviper.OAuthProviderConfig{
				"unknown": {
					ClientID:     "id",
					ClientSecret: "secret",
					RedirectURI:  "https://example.com",
				},
			},
		},
	}

	manager, err := buildOAuthManager(cfg, zap.NewNop())
	if err == nil {
		t.Fatalf("expected error for unknown provider, got manager %#v", manager)
	}
}

func TestBuildMailerReturnsCopy(t *testing.T) {
	cfg := configviper.Config{
		App: configviper.AppConfig{Name: "AREA"},
		Notifier: configviper.NotifierConfig{
			Mailer: configviper.MailerConfig{
				Provider:    "sendgrid",
				FromEmail:   "noreply@example.com",
				SandboxMode: false,
				APIKey:      "key",
			},
		},
	}

	mailer := buildMailer(cfg, zap.NewNop())
	cfg.Notifier.Mailer.APIKey = "modified"

	sg, ok := mailer.(sendgridMailer.Mailer)
	if !ok {
		t.Fatalf("expected sendgrid mailer, got %T", mailer)
	}
	if sg.APIKey != "key" {
		t.Fatalf("expected API key to remain unchanged, got %q", sg.APIKey)
	}
}

func TestBuildOAuthManagerAllowedFallback(t *testing.T) {
	cfg := configviper.Config{
		OAuth: configviper.OAuthConfig{
			Providers: map[string]configviper.OAuthProviderConfig{
				"google": {
					ClientID:     "client",
					ClientSecret: "secret",
					RedirectURI:  "https://example.com",
				},
			},
		},
	}

	manager, err := buildOAuthManager(cfg, zap.NewNop())
	if err != nil {
		t.Fatalf("buildOAuthManager() error = %v", err)
	}
	if manager == nil {
		t.Fatal("expected manager when providers configured")
	}
	want := []string{"google"}
	if got := manager.Names(); !reflect.DeepEqual(want, got) {
		t.Fatalf("manager.Names() = %v, want %v", got, want)
	}
}

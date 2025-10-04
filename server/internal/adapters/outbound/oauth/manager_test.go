package oauth

import (
	"testing"

	identitydomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/identity"
)

func TestNewManagerBuildsProviders(t *testing.T) {
	registry := Registry{
		"test": {
			DisplayName:      "Test",
			AuthorizationURL: "https://auth.example/authorize",
			TokenURL:         "https://auth.example/token",
			UserInfoURL:      "https://auth.example/userinfo",
			ProfileExtractor: func(raw map[string]any) (identitydomain.Profile, error) {
				return identitydomain.Profile{Provider: "test", Subject: "abc", Raw: raw}, nil
			},
		},
	}

	cfg := ManagerConfig{
		Allowed: []string{"test"},
		Providers: map[string]ProviderCredentials{
			"test": {
				ClientID:     "client",
				ClientSecret: "secret",
				RedirectURI:  "https://app.example/callback",
			},
		},
	}

	manager, err := NewManager(registry, cfg)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	provider, ok := manager.Provider("test")
	if !ok {
		t.Fatalf("expected provider registered")
	}
	if provider.Name() != "test" {
		t.Fatalf("unexpected provider name %s", provider.Name())
	}
}

func TestNewManagerMissingDescriptor(t *testing.T) {
	cfg := ManagerConfig{
		Allowed: []string{"missing"},
		Providers: map[string]ProviderCredentials{
			"missing": {
				ClientID:     "client",
				ClientSecret: "secret",
				RedirectURI:  "https://app.example/callback",
			},
		},
	}

	if _, err := NewManager(nil, cfg); err == nil {
		t.Fatalf("expected error for unknown descriptor")
	}
}

func TestNewManagerMissingCredentials(t *testing.T) {
	registry := Registry{
		"test": {
			DisplayName:      "Test",
			AuthorizationURL: "https://auth.example/authorize",
			TokenURL:         "https://auth.example/token",
			UserInfoURL:      "https://auth.example/userinfo",
			ProfileExtractor: func(raw map[string]any) (identitydomain.Profile, error) {
				return identitydomain.Profile{Provider: "test", Subject: "abc", Raw: raw}, nil
			},
		},
	}

	cfg := ManagerConfig{
		Allowed:   []string{"test"},
		Providers: map[string]ProviderCredentials{},
	}

	if _, err := NewManager(registry, cfg); err == nil {
		t.Fatalf("expected error for missing credentials")
	}
}

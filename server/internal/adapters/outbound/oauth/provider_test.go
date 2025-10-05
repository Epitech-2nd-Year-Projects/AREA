package oauth

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"net/url"
	"testing"

	identitydomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/identity"
	identityport "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound/identity"
)

func TestProviderAuthorizationAndExchange(t *testing.T) {
	ctx := context.Background()

	var lastAccess string
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case "/token":
			if err := r.ParseForm(); err != nil {
				t.Fatalf("parse form: %v", err)
			}
			switch r.FormValue("grant_type") {
			case "authorization_code":
				if r.FormValue("code") != "code-123" {
					t.Fatalf("unexpected code %s", r.FormValue("code"))
				}
				lastAccess = "access-123"
				w.Header().Set("Content-Type", "application/json")
				payload := map[string]any{
					"access_token":  lastAccess,
					"refresh_token": "refresh-123",
					"token_type":    "Bearer",
					"expires_in":    3600,
				}
				_ = json.NewEncoder(w).Encode(payload)
			case "refresh_token":
				if r.FormValue("refresh_token") != "refresh-123" {
					t.Fatalf("unexpected refresh token %s", r.FormValue("refresh_token"))
				}
				lastAccess = "access-456"
				w.Header().Set("Content-Type", "application/json")
				payload := map[string]any{
					"access_token":  lastAccess,
					"refresh_token": "refresh-456",
					"token_type":    "Bearer",
					"expires_in":    7200,
				}
				_ = json.NewEncoder(w).Encode(payload)
			default:
				t.Fatalf("unexpected grant type %s", r.FormValue("grant_type"))
			}
		case "/userinfo":
			authHeader := r.Header.Get("Authorization")
			if authHeader != "Bearer "+lastAccess {
				t.Fatalf("unexpected authorization header %s", authHeader)
			}
			w.Header().Set("Content-Type", "application/json")
			payload := map[string]any{
				"id":    42,
				"email": "user@example.com",
				"name":  "Test User",
			}
			_ = json.NewEncoder(w).Encode(payload)
		default:
			w.WriteHeader(http.StatusNotFound)
		}
	}))
	defer ts.Close()

	descriptor := ProviderDescriptor{
		DisplayName:      "Test Provider",
		AuthorizationURL: "https://auth.example/authorize",
		TokenURL:         ts.URL + "/token",
		UserInfoURL:      ts.URL + "/userinfo",
		DefaultScopes:    []string{"profile"},
		AuthorizationParams: map[string]string{
			"access_type": "offline",
		},
		ProfileExtractor: func(raw map[string]any) (identitydomain.Profile, error) {
			return identitydomain.Profile{
				Provider: "test",
				Subject:  "subject-" + raw["id"].(json.Number).String(),
				Email:    raw["email"].(string),
				Name:     raw["name"].(string),
				Raw:      raw,
			}, nil
		},
	}

	creds := ProviderCredentials{
		ClientID:     "client",
		ClientSecret: "secret",
		RedirectURI:  "https://app.example/callback",
		Scopes:       []string{"email"},
	}

	prov, err := NewProvider("test", descriptor, creds)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	authResp, err := prov.AuthorizationURL(ctx, identityport.AuthorizationRequest{
		State: "state-1",
	})
	if err != nil {
		t.Fatalf("authorization url error: %v", err)
	}

	parsed, err := url.Parse(authResp.AuthorizationURL)
	if err != nil {
		t.Fatalf("parse auth url: %v", err)
	}
	query := parsed.Query()
	if query.Get("redirect_uri") != creds.RedirectURI {
		t.Fatalf("expected redirect uri %s", creds.RedirectURI)
	}
	if query.Get("scope") != "email" {
		t.Fatalf("expected scope email got %s", query.Get("scope"))
	}
	if query.Get("access_type") != "offline" {
		t.Fatalf("expected access_type offline")
	}

	exchange, err := prov.Exchange(ctx, "code-123", identityport.ExchangeRequest{})
	if err != nil {
		t.Fatalf("exchange error: %v", err)
	}
	if exchange.Token.AccessToken != "access-123" {
		t.Fatalf("unexpected access token %s", exchange.Token.AccessToken)
	}
	if exchange.Profile.Subject != "subject-42" {
		t.Fatalf("unexpected subject %s", exchange.Profile.Subject)
	}
	if exchange.Profile.Email != "user@example.com" {
		t.Fatalf("unexpected email %s", exchange.Profile.Email)
	}
	if _, ok := exchange.Raw["token"].(map[string]any); !ok {
		t.Fatalf("expected raw token map")
	}

	refresh, err := prov.Refresh(ctx, identitydomain.Identity{
		Provider:     "test",
		Subject:      exchange.Profile.Subject,
		RefreshToken: "refresh-123",
		Scopes:       []string{"email"},
	})
	if err != nil {
		t.Fatalf("refresh error: %v", err)
	}
	if refresh.Token.AccessToken != "access-456" {
		t.Fatalf("unexpected refresh access token %s", refresh.Token.AccessToken)
	}
	if refresh.Profile.Subject != exchange.Profile.Subject {
		t.Fatalf("subject mismatch after refresh")
	}
}

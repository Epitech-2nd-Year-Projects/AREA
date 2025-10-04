package oauth2

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"net/url"
	"testing"
	"time"
)

type fixedClock struct {
	now time.Time
}

func (c fixedClock) Now() time.Time { return c.now }

func TestAuthorizationURLWithPKCE(t *testing.T) {
	cfg := Config{
		ClientID: "client",
		AuthURL:  "https://auth.example/authorize",
		TokenURL: "https://auth.example/token",
		Scopes:   []string{"profile"},
	}
	client, err := NewClient(cfg)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	verifier := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"[:50]
	result, err := client.AuthorizationURL(context.Background(), AuthorizationRequest{
		RedirectURI:  "https://app.example/callback",
		State:        "state123",
		PKCE:         true,
		CodeVerifier: verifier,
		Extra: map[string]string{
			"access_type": "offline",
		},
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	parsed, err := url.Parse(result.URL)
	if err != nil {
		t.Fatalf("url parse failed: %v", err)
	}
	query := parsed.Query()
	if query.Get("state") != "state123" {
		t.Fatalf("expected state preserved")
	}
	if query.Get("code_challenge") == "" {
		t.Fatalf("expected code challenge present")
	}
	if query.Get("access_type") != "offline" {
		t.Fatalf("expected custom parameter propagated")
	}
	if result.CodeVerifier != verifier {
		t.Fatalf("expected code verifier to match input")
	}
	if result.CodeChallenge == "" {
		t.Fatalf("expected code challenge populated")
	}
	if result.CodeChallengeMethod != CodeChallengeMethodS256 {
		t.Fatalf("expected S256 method")
	}
}

func TestAuthorizationURLGeneratesState(t *testing.T) {
	cfg := Config{
		ClientID: "client",
		AuthURL:  "https://auth.example/authorize",
		TokenURL: "https://auth.example/token",
	}
	client, err := NewClient(cfg)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	result, err := client.AuthorizationURL(context.Background(), AuthorizationRequest{
		RedirectURI: "https://app.example/callback",
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if result.State == "" {
		t.Fatalf("expected state generated")
	}
}

func TestExchangeSuccess(t *testing.T) {
	now := time.Unix(1700000000, 0).UTC()
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if err := r.ParseForm(); err != nil {
			w.WriteHeader(http.StatusBadRequest)
			return
		}
		if r.FormValue("code") != "abc" {
			w.WriteHeader(http.StatusBadRequest)
			return
		}
		if r.FormValue("redirect_uri") != "https://app.example/callback" {
			w.WriteHeader(http.StatusBadRequest)
			return
		}
		payload := map[string]any{
			"access_token":  "token",
			"refresh_token": "refresh",
			"token_type":    "Bearer",
			"expires_in":    3600,
			"scope":         "profile email",
		}
		_ = json.NewEncoder(w).Encode(payload)
	}))
	defer ts.Close()

	cfg := Config{
		ClientID: "client",
		AuthURL:  "https://auth.example/authorize",
		TokenURL: ts.URL,
	}
	client, err := NewClient(cfg, WithClock(fixedClock{now: now}))
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	token, err := client.Exchange(context.Background(), ExchangeRequest{
		Code:        "abc",
		RedirectURI: "https://app.example/callback",
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if token.AccessToken != "token" {
		t.Fatalf("unexpected access token %s", token.AccessToken)
	}
	if !token.ExpiresAt.Equal(now.Add(3600 * time.Second)) {
		t.Fatalf("unexpected expiry %v", token.ExpiresAt)
	}
	if len(token.Scope) != 2 {
		t.Fatalf("expected two scopes")
	}
}

func TestRefreshHandlesError(t *testing.T) {
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusBadRequest)
		_, _ = w.Write([]byte(`{"error":"invalid_grant","error_description":"expired"}`))
	}))
	defer ts.Close()

	cfg := Config{
		ClientID: "client",
		AuthURL:  "https://auth.example/authorize",
		TokenURL: ts.URL,
	}
	client, err := NewClient(cfg)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	_, err = client.Refresh(context.Background(), RefreshRequest{RefreshToken: "dead"})
	if err == nil {
		t.Fatalf("expected error on refresh")
	}
}

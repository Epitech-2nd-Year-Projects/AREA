package reddit

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"strings"
	"testing"
	"time"

	areadomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/area"
	componentdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/component"
	identitydomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/identity"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/oauth2"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
	identityport "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound/identity"
	"github.com/google/uuid"
)

func TestExecutorSupports(t *testing.T) {
	exec := NewExecutor(nil, nil, nil, nil, nil)

	component := &componentdomain.Component{Name: redditComponentName, Provider: componentdomain.Provider{Name: redditProviderName}}
	if !exec.Supports(component) {
		t.Fatalf("expected support for reddit component")
	}
	if exec.Supports(&componentdomain.Component{Name: "other"}) {
		t.Fatalf("unexpected support for other component")
	}
}

func TestExecutorExecuteSuccess(t *testing.T) {
	identityID := uuid.New()
	userID := uuid.New()
	identity := identitydomain.Identity{
		ID:           identityID,
		UserID:       userID,
		Provider:     redditProviderName,
		Subject:      "subject",
		AccessToken:  "token-123",
		RefreshToken: "refresh-456",
		Scopes:       []string{"identity", "read", "submit"},
	}

	repo := &stubIdentityRepo{identity: identity}
	client := &stubHTTPClient{}
	exec := NewExecutor(repo, stubProviderResolver{}, client, stubClock{now: time.Now()}, nil)

	area := areadomain.Area{ID: uuid.New(), UserID: userID}
	component := &componentdomain.Component{Name: redditComponentName, Provider: componentdomain.Provider{Name: redditProviderName}}
	link := areadomain.Link{Config: componentdomain.Config{
		Component: component,
		Params: map[string]any{
			"identityId": identityID.String(),
			"thingId":    "t3_abc123",
			"text":       "Hello Reddit!",
		},
	}}

	result, err := exec.Execute(context.Background(), area, link)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if result.Endpoint != redditCommentAPIEndpoint {
		t.Fatalf("unexpected endpoint %s", result.Endpoint)
	}
	if len(client.requests) != 1 {
		t.Fatalf("expected exactly one HTTP request, got %d", len(client.requests))
	}
	if auth := client.requests[0].Header.Get("Authorization"); auth != "Bearer token-123" {
		t.Fatalf("unexpected authorization header %s", auth)
	}
	bodyBytes, _ := io.ReadAll(client.requests[0].Body)
	if !strings.Contains(string(bodyBytes), "thing_id=t3_abc123") {
		t.Fatalf("expected body to contain thing_id, got %s", string(bodyBytes))
	}
}

func TestParseCommentConfigAddsPrefix(t *testing.T) {
	identityID := uuid.New()
	params := map[string]any{
		"identityId": identityID.String(),
		"thingId":    "abc123",
		"text":       "hi",
	}

	cfg, err := parseCommentConfig(params)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if cfg.thingID != "t3_abc123" {
		t.Fatalf("expected prefixed thing id, got %q", cfg.thingID)
	}
}

func TestExecutorExecuteRefreshOnUnauthorized(t *testing.T) {
	identityID := uuid.New()
	userID := uuid.New()
	expired := time.Now().Add(-time.Hour)
	identity := identitydomain.Identity{
		ID:           identityID,
		UserID:       userID,
		Provider:     redditProviderName,
		Subject:      "subject",
		AccessToken:  "expired-token",
		RefreshToken: "refresh-456",
		Scopes:       []string{"identity", "read", "submit"},
		ExpiresAt:    &expired,
	}

	repo := &stubIdentityRepo{identity: identity}
	provider := &stubProvider{token: "new-access"}
	client := &stubHTTPClient{
		responses: []*http.Response{
			{StatusCode: http.StatusUnauthorized, Body: ioNopCloser("unauthorized")},
			{StatusCode: http.StatusOK, Body: ioNopCloser(`{"json":{}}`)},
		},
	}
	exec := NewExecutor(repo, stubProviderResolver{provider: provider}, client, stubClock{now: time.Now()}, nil)

	area := areadomain.Area{ID: uuid.New(), UserID: userID}
	component := &componentdomain.Component{Name: redditComponentName, Provider: componentdomain.Provider{Name: redditProviderName}}
	link := areadomain.Link{Config: componentdomain.Config{
		Component: component,
		Params: map[string]any{
			"identityId": identityID.String(),
			"thingId":    "t3_xyz789",
			"text":       "Retry comment",
		},
	}}

	if _, err := exec.Execute(context.Background(), area, link); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if repo.updated == nil || repo.updated.AccessToken != "new-access" {
		t.Fatalf("expected identity to be updated with new access token")
	}
	if len(client.requests) != 2 {
		t.Fatalf("expected two HTTP requests, got %d", len(client.requests))
	}
	if provider.refreshCalls == 0 {
		t.Fatalf("expected refresh token to be used")
	}
	if auth := client.requests[1].Header.Get("Authorization"); auth != "Bearer new-access" {
		t.Fatalf("second request should use refreshed token, got %s", auth)
	}
}

type stubIdentityRepo struct {
	identity identitydomain.Identity
	updated  *identitydomain.Identity
}

func (s *stubIdentityRepo) Create(ctx context.Context, identity identitydomain.Identity) (identitydomain.Identity, error) {
	s.identity = identity
	return identity, nil
}

func (s *stubIdentityRepo) Update(ctx context.Context, identity identitydomain.Identity) error {
	s.identity = identity
	s.updated = &identity
	return nil
}

func (s *stubIdentityRepo) FindByID(ctx context.Context, id uuid.UUID) (identitydomain.Identity, error) {
	if s.identity.ID != id {
		return identitydomain.Identity{}, outbound.ErrNotFound
	}
	return s.identity, nil
}

func (s *stubIdentityRepo) FindByUserAndProvider(ctx context.Context, userID uuid.UUID, provider string) (identitydomain.Identity, error) {
	return identitydomain.Identity{}, outbound.ErrNotFound
}

func (s *stubIdentityRepo) FindByProviderSubject(ctx context.Context, provider string, subject string) (identitydomain.Identity, error) {
	return identitydomain.Identity{}, outbound.ErrNotFound
}

func (s *stubIdentityRepo) ListByUser(ctx context.Context, userID uuid.UUID) ([]identitydomain.Identity, error) {
	return nil, nil
}

func (s *stubIdentityRepo) Delete(ctx context.Context, id uuid.UUID) error {
	return nil
}

type stubProviderResolver struct {
	provider identityport.Provider
}

func (s stubProviderResolver) Provider(name string) (identityport.Provider, bool) {
	if s.provider == nil {
		return nil, false
	}
	return s.provider, true
}

type stubProvider struct {
	token        string
	refreshCalls int
}

func (s *stubProvider) Name() string { return redditProviderName }

func (s *stubProvider) AuthorizationURL(ctx context.Context, req identityport.AuthorizationRequest) (identityport.AuthorizationResponse, error) {
	return identityport.AuthorizationResponse{}, fmt.Errorf("not implemented")
}

func (s *stubProvider) Exchange(ctx context.Context, code string, req identityport.ExchangeRequest) (identityport.TokenExchange, error) {
	return identityport.TokenExchange{}, fmt.Errorf("not implemented")
}

func (s *stubProvider) Refresh(ctx context.Context, identity identitydomain.Identity) (identityport.TokenExchange, error) {
	s.refreshCalls++
	return tokenExchange(s.token, time.Minute), nil
}

type stubHTTPClient struct {
	responses []*http.Response
	requests  []*http.Request
}

func (s *stubHTTPClient) Do(req *http.Request) (*http.Response, error) {
	bodyBytes, _ := io.ReadAll(req.Body)
	req.Body.Close()
	req.Body = io.NopCloser(strings.NewReader(string(bodyBytes)))
	s.requests = append(s.requests, req)
	if len(s.responses) == 0 {
		return &http.Response{
			StatusCode: http.StatusOK,
			Body:       ioNopCloser(`{"json":{}}`),
			Header:     make(http.Header),
		}, nil
	}
	resp := s.responses[0]
	s.responses = s.responses[1:]
	if resp.Body == nil {
		resp.Body = ioNopCloser("")
	}
	return resp, nil
}

type stubClock struct{ now time.Time }

func (s stubClock) Now() time.Time { return s.now }

func tokenExchange(accessToken string, ttl time.Duration) identityport.TokenExchange {
	expires := time.Now().Add(ttl)
	return identityport.TokenExchange{Token: oauth2.Token{AccessToken: accessToken, RefreshToken: "refresh", ExpiresAt: expires}}
}

func ioNopCloser(body string) io.ReadCloser {
	return io.NopCloser(strings.NewReader(body))
}

// Ensure helper usage
var (
	_ = oauth2.Token{}
)

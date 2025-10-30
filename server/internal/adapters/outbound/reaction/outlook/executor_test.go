package outlook

import (
	"context"
	"encoding/json"
	"fmt"
	areadomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/area"
	componentdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/component"
	identitydomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/identity"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/oauth2"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
	identityport "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound/identity"
	"github.com/google/uuid"
	"io"
	"net/http"
	"strings"
	"testing"
	"time"
)

func TestExecutorSupports(t *testing.T) {
	exec := NewExecutor(nil, nil, nil, nil, nil)

	component := &componentdomain.Component{Name: outlookComponentName, Provider: componentdomain.Provider{Name: outlookProviderName}}
	if !exec.Supports(component) {
		t.Fatalf("expected support for outlook component")
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
		Provider:     outlookProviderName,
		Subject:      "subject",
		AccessToken:  "token-123",
		RefreshToken: "refresh-456",
		Scopes:       []string{"Mail.Send"},
	}

	repo := &stubIdentityRepo{identity: identity}
	client := &stubHTTPClient{}
	exec := NewExecutor(repo, stubProviderResolver{}, client, stubClock{now: time.Now()}, nil)

	area := areadomain.Area{ID: uuid.New(), UserID: userID}
	component := &componentdomain.Component{Name: outlookComponentName, Provider: componentdomain.Provider{Name: outlookProviderName}}
	link := areadomain.Link{Config: componentdomain.Config{
		Component: component,
		Params: map[string]any{
			"identityId": identityID.String(),
			"to":         "user@example.com",
			"subject":    "Greetings",
			"body":       "Hello world",
		},
	}}

	result, err := exec.Execute(context.Background(), area, link)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if result.Endpoint != outlookSendMailEndpoint {
		t.Fatalf("unexpected endpoint %s", result.Endpoint)
	}
	if len(client.authHeaders) != 1 {
		t.Fatalf("expected one request")
	}
	if client.authHeaders[0] != "Bearer token-123" {
		t.Fatalf("unexpected authorization header %s", client.authHeaders[0])
	}
	var payload map[string]any
	if err := json.Unmarshal([]byte(client.bodies[0]), &payload); err != nil {
		t.Fatalf("failed to decode payload: %v", err)
	}
	message, ok := payload["message"].(map[string]any)
	if !ok {
		t.Fatalf("expected message object in payload")
	}
	if got := message["subject"]; got != "Greetings" {
		t.Fatalf("unexpected subject %v", got)
	}
	body, ok := message["body"].(map[string]any)
	if !ok {
		t.Fatalf("expected body object")
	}
	if got := body["content"]; got != "Hello world" {
		t.Fatalf("unexpected body content %v", got)
	}
	recipients, ok := message["toRecipients"].([]any)
	if !ok || len(recipients) != 1 {
		t.Fatalf("expected one recipient, got %v", recipients)
	}
	if save, ok := payload["saveToSentItems"].(bool); !ok || !save {
		t.Fatalf("expected saveToSentItems true")
	}
}

func TestExecutorExecuteRefreshOnUnauthorized(t *testing.T) {
	identityID := uuid.New()
	userID := uuid.New()
	expires := time.Now().Add(-time.Hour)
	identity := identitydomain.Identity{
		ID:           identityID,
		UserID:       userID,
		Provider:     outlookProviderName,
		Subject:      "subject",
		AccessToken:  "expired-token",
		RefreshToken: "refresh-456",
		Scopes:       []string{"Mail.Send"},
		ExpiresAt:    &expires,
	}

	repo := &stubIdentityRepo{identity: identity}
	provider := &stubProvider{token: "new-access"}
	client := &stubHTTPClient{
		responses: []*http.Response{
			{StatusCode: http.StatusUnauthorized, Body: ioNopCloser("unauthorized")},
			{StatusCode: http.StatusAccepted, Body: ioNopCloser("")},
		},
	}
	exec := NewExecutor(repo, stubProviderResolver{provider: provider}, client, stubClock{now: time.Now()}, nil)

	area := areadomain.Area{ID: uuid.New(), UserID: userID}
	component := &componentdomain.Component{Name: outlookComponentName, Provider: componentdomain.Provider{Name: outlookProviderName}}
	link := areadomain.Link{Config: componentdomain.Config{
		Component: component,
		Params: map[string]any{
			"identityId": identityID.String(),
			"to":         "user@example.com",
			"subject":    "Hi",
			"body":       "Test",
		},
	}}

	if _, err := exec.Execute(context.Background(), area, link); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if repo.updated == nil || repo.updated.AccessToken != "new-access" {
		t.Fatalf("expected identity to be updated with new token")
	}
	if len(client.authHeaders) != 2 {
		t.Fatalf("expected two requests")
	}
	if client.authHeaders[1] != "Bearer new-access" {
		t.Fatalf("second request should use refreshed token, got %s", client.authHeaders[1])
	}
	if provider.refreshCalls == 0 {
		t.Fatalf("expected refresh to be called")
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
	s.updated = &identity
	s.identity = identity
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

func (s *stubProvider) Name() string { return outlookProviderName }

func (s *stubProvider) AuthorizationURL(ctx context.Context, req identityport.AuthorizationRequest) (identityport.AuthorizationResponse, error) {
	return identityport.AuthorizationResponse{}, fmt.Errorf("not implemented")
}

func (s *stubProvider) Exchange(ctx context.Context, code string, req identityport.ExchangeRequest) (identityport.TokenExchange, error) {
	return identityport.TokenExchange{}, fmt.Errorf("not implemented")
}

func (s *stubProvider) Refresh(ctx context.Context, identity identitydomain.Identity) (identityport.TokenExchange, error) {
	s.refreshCalls++
	return oauthToken(s.token, 30*time.Minute), nil
}

type stubHTTPClient struct {
	responses   []*http.Response
	authHeaders []string
	bodies      []string
}

func (s *stubHTTPClient) Do(req *http.Request) (*http.Response, error) {
	body, _ := io.ReadAll(req.Body)
	req.Body.Close()
	s.authHeaders = append(s.authHeaders, req.Header.Get("Authorization"))
	s.bodies = append(s.bodies, string(body))
	if len(s.responses) == 0 {
		return &http.Response{StatusCode: http.StatusAccepted, Body: ioNopCloser("")}, nil
	}
	resp := s.responses[0]
	s.responses = s.responses[1:]
	return resp, nil
}

type stubClock struct{ now time.Time }

func (s stubClock) Now() time.Time { return s.now }

func oauthToken(accessToken string, ttl time.Duration) identityport.TokenExchange {
	expires := time.Now().Add(ttl)
	return identityport.TokenExchange{Token: oauth2Token(accessToken, expires)}
}

func oauth2Token(accessToken string, expires time.Time) oauth2.Token {
	return oauth2.Token{AccessToken: accessToken, ExpiresAt: expires}
}

func ioNopCloser(body string) io.ReadCloser {
	return io.NopCloser(strings.NewReader(body))
}

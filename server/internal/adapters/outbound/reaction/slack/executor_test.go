package slack

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
	identityport "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound/identity"
	"github.com/google/uuid"
	"go.uber.org/zap"
)

func TestMessageExecutorSupports(t *testing.T) {
	exec := NewMessageExecutor(nil, providerResolverStub{}, nil, nil, nil)

	component := &componentdomain.Component{
		Name: postMessageComponentName,
		Provider: componentdomain.Provider{
			Name: slackProviderName,
		},
	}
	if !exec.Supports(component) {
		t.Fatal("expected component to be supported")
	}

	if exec.Supports(nil) {
		t.Fatal("nil component should not be supported")
	}

	component.Name = "other"
	if exec.Supports(component) {
		t.Fatal("unexpected support for different component")
	}
}

func TestMessageExecutorExecutePostsMessage(t *testing.T) {
	userID := uuid.New()
	identityID := uuid.New()
	componentID := uuid.New()
	areaID := uuid.New()

	future := time.Now().Add(2 * time.Hour).UTC()
	identity := identitydomain.Identity{
		ID:           identityID,
		UserID:       userID,
		Provider:     slackProviderName,
		AccessToken:  "xoxb-old-token",
		RefreshToken: "refresh-token",
		ExpiresAt:    &future,
	}

	repo := &identityRepoStub{identity: identity}
	client := &httpClientStub{
		responses: []http.Response{
			{
				StatusCode: http.StatusOK,
				Header: http.Header{
					"Content-Type": []string{"application/json"},
				},
				Body: io.NopCloser(strings.NewReader(`{"ok":true,"ts":"123"}`)),
			},
		},
	}

	exec := NewMessageExecutor(repo, providerResolverStub{}, client, clockStub{now: future.Add(-time.Minute)}, zap.NewNop())

	component := &componentdomain.Component{
		ID:       componentID,
		Name:     postMessageComponentName,
		Provider: componentdomain.Provider{Name: slackProviderName},
	}

	link := areadomain.Link{
		ID:     uuid.New(),
		AreaID: areaID,
		Role:   areadomain.LinkRoleReaction,
		Config: componentdomain.Config{
			ID:          uuid.New(),
			UserID:      userID,
			ComponentID: componentID,
			Name:        "Send message",
			Params: map[string]any{
				"identityId": identityID.String(),
				"channelId":  "C12345678",
				"text":       "Hello world",
			},
			Component: component,
		},
	}

	area := areadomain.Area{
		ID:        areaID,
		UserID:    userID,
		Name:      "Test area",
		Reactions: []areadomain.Link{link},
	}

	result, err := exec.Execute(context.Background(), area, link)
	if err != nil {
		t.Fatalf("Execute returned error: %v", err)
	}
	if result.StatusCode == nil || *result.StatusCode != http.StatusOK {
		t.Fatalf("unexpected status code %+v", result.StatusCode)
	}
	if repo.updateCalled {
		t.Fatal("identity update should not be called when token valid")
	}
	if len(client.requests) != 1 {
		t.Fatalf("expected one request, got %d", len(client.requests))
	}
	if auth := client.requests[0].Header.Get("Authorization"); auth != "Bearer xoxb-old-token" {
		t.Fatalf("unexpected authorization header %q", auth)
	}
	bodyBytes, err := io.ReadAll(client.requests[0].Body)
	if err != nil {
		t.Fatalf("read body: %v", err)
	}
	if !strings.Contains(string(bodyBytes), `"channel":"C12345678"`) {
		t.Fatalf("expected channel in request body, got %s", string(bodyBytes))
	}
	if !strings.Contains(string(bodyBytes), `"text":"Hello world"`) {
		t.Fatalf("expected text in request body, got %s", string(bodyBytes))
	}
}

func TestMessageExecutorExecuteRefreshesOnUnauthorized(t *testing.T) {
	userID := uuid.New()
	identityID := uuid.New()
	componentID := uuid.New()
	areaID := uuid.New()

	now := time.Now().UTC()
	expires := now.Add(30 * time.Minute)
	identity := identitydomain.Identity{
		ID:           identityID,
		UserID:       userID,
		Provider:     slackProviderName,
		AccessToken:  "xoxb-expired",
		RefreshToken: "refresh-token",
		ExpiresAt:    &expires,
	}

	repo := &identityRepoStub{identity: identity}

	client := &httpClientStub{
		responses: []http.Response{
			{
				StatusCode: http.StatusOK,
				Header:     http.Header{"Content-Type": []string{"application/json"}},
				Body:       io.NopCloser(strings.NewReader(`{"ok":false,"error":"invalid_auth"}`)),
			},
			{
				StatusCode: http.StatusOK,
				Header:     http.Header{"Content-Type": []string{"application/json"}},
				Body:       io.NopCloser(strings.NewReader(`{"ok":true,"ts":"456"}`)),
			},
		},
	}

	provider := &providerStub{
		exchange: identityport.TokenExchange{
			Token: oauth2.Token{
				AccessToken:  "xoxb-new-token",
				RefreshToken: "new-refresh",
				ExpiresAt:    now.Add(1 * time.Hour),
				Scope:        []string{"chat:write"},
			},
		},
	}

	exec := NewMessageExecutor(repo, providerResolverStub{provider: provider}, client, clockStub{now: now}, zap.NewNop())

	component := &componentdomain.Component{
		ID:       componentID,
		Name:     postMessageComponentName,
		Provider: componentdomain.Provider{Name: slackProviderName},
	}

	link := areadomain.Link{
		ID:     uuid.New(),
		AreaID: areaID,
		Role:   areadomain.LinkRoleReaction,
		Config: componentdomain.Config{
			ID:          uuid.New(),
			UserID:      userID,
			ComponentID: componentID,
			Name:        "Send message",
			Params: map[string]any{
				"identityId": identityID.String(),
				"channelId":  "C23456789",
				"text":       "Hello again",
			},
			Component: component,
		},
	}

	area := areadomain.Area{ID: areaID, UserID: userID}

	result, err := exec.Execute(context.Background(), area, link)
	if err != nil {
		t.Fatalf("Execute returned error: %v", err)
	}
	if result.StatusCode == nil || *result.StatusCode != http.StatusOK {
		t.Fatalf("unexpected status code %+v", result.StatusCode)
	}
	if !repo.updateCalled {
		t.Fatal("expected identity update after refresh")
	}
	if repo.identity.AccessToken != "xoxb-new-token" {
		t.Fatalf("expected access token to be refreshed, got %s", repo.identity.AccessToken)
	}
	if len(client.requests) != 2 {
		t.Fatalf("expected two requests, got %d", len(client.requests))
	}
	if auth := client.requests[0].Header.Get("Authorization"); auth != "Bearer xoxb-expired" {
		t.Fatalf("unexpected first auth header %q", auth)
	}
	if auth := client.requests[1].Header.Get("Authorization"); auth != "Bearer xoxb-new-token" {
		t.Fatalf("unexpected second auth header %q", auth)
	}
	if !provider.refreshed {
		t.Fatal("expected refresh to be called")
	}
}

type identityRepoStub struct {
	identity     identitydomain.Identity
	updateCalled bool
}

func (s *identityRepoStub) Create(context.Context, identitydomain.Identity) (identitydomain.Identity, error) {
	return identitydomain.Identity{}, fmt.Errorf("not implemented")
}

func (s *identityRepoStub) Update(ctx context.Context, identity identitydomain.Identity) error {
	s.updateCalled = true
	s.identity = identity
	return nil
}

func (s *identityRepoStub) FindByID(ctx context.Context, id uuid.UUID) (identitydomain.Identity, error) {
	if id != s.identity.ID {
		return identitydomain.Identity{}, fmt.Errorf("identity not found")
	}
	return s.identity, nil
}

func (s *identityRepoStub) FindByUserAndProvider(context.Context, uuid.UUID, string) (identitydomain.Identity, error) {
	return identitydomain.Identity{}, fmt.Errorf("not implemented")
}

func (s *identityRepoStub) FindByProviderSubject(context.Context, string, string) (identitydomain.Identity, error) {
	return identitydomain.Identity{}, fmt.Errorf("not implemented")
}

func (s *identityRepoStub) ListByUser(context.Context, uuid.UUID) ([]identitydomain.Identity, error) {
	return nil, fmt.Errorf("not implemented")
}

func (s *identityRepoStub) Delete(context.Context, uuid.UUID) error {
	return fmt.Errorf("not implemented")
}

type providerResolverStub struct {
	provider identityport.Provider
}

func (s providerResolverStub) Provider(name string) (identityport.Provider, bool) {
	if s.provider == nil {
		return nil, false
	}
	if strings.EqualFold(name, slackProviderName) {
		return s.provider, true
	}
	return nil, false
}

type providerStub struct {
	refreshed bool
	exchange  identityport.TokenExchange
	err       error
}

func (p *providerStub) Name() string {
	return slackProviderName
}

func (p *providerStub) AuthorizationURL(context.Context, identityport.AuthorizationRequest) (identityport.AuthorizationResponse, error) {
	return identityport.AuthorizationResponse{}, fmt.Errorf("not implemented")
}

func (p *providerStub) Exchange(context.Context, string, identityport.ExchangeRequest) (identityport.TokenExchange, error) {
	return identityport.TokenExchange{}, fmt.Errorf("not implemented")
}

func (p *providerStub) Refresh(ctx context.Context, identity identitydomain.Identity) (identityport.TokenExchange, error) {
	p.refreshed = true
	if p.err != nil {
		return identityport.TokenExchange{}, p.err
	}
	return p.exchange, nil
}

type httpClientStub struct {
	responses []http.Response
	requests  []*http.Request
}

func (c *httpClientStub) Do(req *http.Request) (*http.Response, error) {
	c.requests = append(c.requests, req)
	if len(c.responses) == 0 {
		return nil, fmt.Errorf("no response configured")
	}
	resp := c.responses[0]
	c.responses = c.responses[1:]
	if resp.Body == nil {
		resp.Body = io.NopCloser(strings.NewReader("{}"))
	}
	return &resp, nil
}

type clockStub struct {
	now time.Time
}

func (c clockStub) Now() time.Time {
	return c.now
}

package gitlab

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
	identityport "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound/identity"
	"github.com/google/uuid"
	"go.uber.org/zap"
)

func TestIssueExecutorSupports(t *testing.T) {
	exec := NewIssueExecutor(nil, nil, nil, nil, nil)

	component := &componentdomain.Component{
		Name: createIssueComponentName,
		Provider: componentdomain.Provider{
			Name: gitlabProviderName,
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

func TestIssueExecutorExecuteCreatesIssue(t *testing.T) {
	userID := uuid.New()
	identityID := uuid.New()
	componentID := uuid.New()
	areaID := uuid.New()

	future := time.Now().Add(2 * time.Hour).UTC()
	identity := identitydomain.Identity{
		ID:           identityID,
		UserID:       userID,
		Provider:     gitlabProviderName,
		AccessToken:  "access-token",
		RefreshToken: "refresh-token",
		ExpiresAt:    &future,
	}

	repo := &identityRepoStub{identity: identity}
	client := &httpClientStub{
		response: http.Response{
			StatusCode: http.StatusCreated,
			Header: http.Header{
				"Content-Type": []string{"application/json"},
			},
			Body: io.NopCloser(strings.NewReader(`{"iid":7}`)),
		},
	}

	exec := NewIssueExecutor(repo, providerResolverStub{}, client, clockStub{now: future.Add(-time.Minute)}, zap.NewNop())

	component := &componentdomain.Component{
		ID:       componentID,
		Name:     createIssueComponentName,
		Provider: componentdomain.Provider{Name: gitlabProviderName},
	}

	link := areadomain.Link{
		ID:     uuid.New(),
		AreaID: areaID,
		Role:   areadomain.LinkRoleReaction,
		Config: componentdomain.Config{
			ID:          uuid.New(),
			UserID:      userID,
			ComponentID: componentID,
			Name:        "Create issue",
			Params: map[string]any{
				"identityId": identityID.String(),
				"owner":      "my-group",
				"repository": "demo-app",
				"title":      "Bug report",
				"body":       "Please investigate",
				"labels":     "bug, urgent",
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

	if result.StatusCode == nil || *result.StatusCode != http.StatusCreated {
		t.Fatalf("unexpected status code %+v", result.StatusCode)
	}

	expectedEndpoint := "https://gitlab.com/api/v4/projects/my-group%2Fdemo-app/issues"
	if result.Endpoint != expectedEndpoint {
		t.Fatalf("unexpected endpoint %s", result.Endpoint)
	}

	if repo.updateCalled {
		t.Fatal("identity update should not be called when token valid")
	}

	if client.lastRequest == nil {
		t.Fatal("expected request to be issued")
	}

	if auth := client.lastRequest.Header.Get("Authorization"); auth != "Bearer access-token" {
		t.Fatalf("unexpected authorization header %q", auth)
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

type providerResolverStub struct{}

func (providerResolverStub) Provider(string) (identityport.Provider, bool) {
	return nil, false
}

type httpClientStub struct {
	response    http.Response
	lastRequest *http.Request
	err         error
}

func (c *httpClientStub) Do(req *http.Request) (*http.Response, error) {
	c.lastRequest = req
	if c.err != nil {
		return nil, c.err
	}
	resp := c.response
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

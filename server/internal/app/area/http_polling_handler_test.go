package area

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"testing"
	"time"

	actiondomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/action"
	componentdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/component"
	identitydomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/identity"
	"github.com/google/uuid"
	"go.uber.org/zap"
)

type recordingTransport struct {
	status    int
	body      []byte
	requests  []*http.Request
	responses int
}

func (r *recordingTransport) RoundTrip(req *http.Request) (*http.Response, error) {
	r.requests = append(r.requests, cloneRequest(req))

	status := r.status
	if status == 0 {
		status = http.StatusOK
	}
	body := r.body
	if body == nil {
		body = []byte(`{}`)
	}

	resp := &http.Response{
		StatusCode: status,
		Header:     http.Header{"Content-Type": []string{"application/json"}},
		Body:       io.NopCloser(bytes.NewReader(body)),
		Request:    req,
	}
	return resp, nil
}

func cloneRequest(req *http.Request) *http.Request {
	cloned := req.Clone(req.Context())
	if req.Body != nil {
		data, _ := io.ReadAll(req.Body)
		_ = req.Body.Close()
		req.Body = io.NopCloser(bytes.NewReader(data))
		cloned.Body = io.NopCloser(bytes.NewReader(data))
	}
	return cloned
}

type identityRepoStub struct {
	identity identitydomain.Identity
	updated  *identitydomain.Identity
}

func (s *identityRepoStub) Create(ctx context.Context, identity identitydomain.Identity) (identitydomain.Identity, error) {
	return identitydomain.Identity{}, fmt.Errorf("not implemented")
}

func (s *identityRepoStub) Update(ctx context.Context, identity identitydomain.Identity) error {
	copyIdentity := identity
	s.updated = &copyIdentity
	s.identity = identity
	return nil
}

func (s *identityRepoStub) FindByID(ctx context.Context, id uuid.UUID) (identitydomain.Identity, error) {
	if s.identity.ID == id {
		return s.identity, nil
	}
	return identitydomain.Identity{}, fmt.Errorf("not found")
}

func (s *identityRepoStub) FindByUserAndProvider(ctx context.Context, userID uuid.UUID, provider string) (identitydomain.Identity, error) {
	return identitydomain.Identity{}, fmt.Errorf("not implemented")
}

func (s *identityRepoStub) FindByProviderSubject(ctx context.Context, provider string, subject string) (identitydomain.Identity, error) {
	return identitydomain.Identity{}, fmt.Errorf("not implemented")
}

func (s *identityRepoStub) ListByUser(ctx context.Context, userID uuid.UUID) ([]identitydomain.Identity, error) {
	return nil, fmt.Errorf("not implemented")
}

func (s *identityRepoStub) Delete(ctx context.Context, id uuid.UUID) error {
	return fmt.Errorf("not implemented")
}

func TestHTTPPollingHandlerSupports(t *testing.T) {
	handler := NewHTTPPollingHandler(nil, zap.NewNop(), nil, nil)

	component := componentdomain.Component{
		Name: "github_new_issue",
		Provider: componentdomain.Provider{
			Name: "github",
		},
		Metadata: map[string]any{
			"ingestion": map[string]any{
				"mode":             "polling",
				"handler":          "http",
				"endpoint":         "https://example.com/events",
				"fingerprintField": "id",
			},
		},
	}

	if !handler.Supports(&component) {
		t.Fatalf("expected handler to support component")
	}

	unsupported := componentdomain.Component{
		Name: "gmail_send",
		Metadata: map[string]any{
			"ingestion": map[string]any{
				"mode":    "webhook",
				"handler": "http",
			},
		},
	}

	if handler.Supports(&unsupported) {
		t.Fatalf("expected handler to ignore webhook component")
	}
}

func TestHTTPPollingHandlerPoll(t *testing.T) {
	payload := map[string]any{
		"items": []any{
			map[string]any{
				"id":        "42",
				"timestamp": "2024-05-01T12:00:00Z",
				"title":     "Demo",
			},
		},
		"next": "cursor-42",
	}
	body, err := json.Marshal(payload)
	if err != nil {
		t.Fatalf("marshal payload: %v", err)
	}

	transport := &recordingTransport{
		body: body,
	}
	client := &http.Client{Transport: transport}
	handler := NewHTTPPollingHandler(client, zap.NewNop(), nil, nil)

	component := componentdomain.Component{
		Name: "demo_issue",
		Provider: componentdomain.Provider{
			Name: "demo",
		},
		Metadata: map[string]any{
			"ingestion": map[string]any{
				"mode":             "polling",
				"handler":          "http",
				"endpoint":         "https://example.local/events",
				"itemsPath":        "items",
				"fingerprintField": "id",
				"occurredAtField":  "timestamp",
				"initialCursor":    "1970-01-01T00:00:00Z",
				"cursorField":      "timestamp",
				"query": []any{
					map[string]any{
						"name":    "since",
						"cursor":  "demo_issue_cursor",
						"default": "1970-01-01T00:00:00Z",
					},
					map[string]any{
						"name":  "type",
						"param": "type",
					},
				},
				"headers": []any{
					map[string]any{
						"name":  "X-Demo",
						"value": "static",
					},
				},
				"cursor": map[string]any{
					"key":     "demo_issue_cursor",
					"source":  "item",
					"path":    "timestamp",
					"initial": "1970-01-01T00:00:00Z",
				},
			},
		},
	}

	binding := actiondomain.PollingBinding{
		Source: actiondomain.Source{},
		Config: componentdomain.Config{
			Params: map[string]any{
				"type": "issue",
			},
		},
	}

	req := PollingRequest{
		Binding:   binding,
		Component: component,
		Cursor:    map[string]any{},
		Now:       time.Unix(1720000000, 0).UTC(),
	}

	result, err := handler.Poll(context.Background(), req)
	if err != nil {
		t.Fatalf("Poll returned error: %v", err)
	}

	if len(result.Events) != 1 {
		t.Fatalf("expected 1 event got %d", len(result.Events))
	}
	event := result.Events[0]
	if event.Fingerprint != "42" {
		t.Fatalf("unexpected fingerprint %q", event.Fingerprint)
	}
	if event.OccurredAt.IsZero() {
		t.Fatalf("expected occurredAt to be parsed")
	}
	if got := result.Cursor["demo_issue_cursor"]; got != "2024-05-01T12:00:00Z" {
		t.Fatalf("unexpected cursor value %v", got)
	}

	if len(transport.requests) != 1 {
		t.Fatalf("expected a single HTTP request")
	}
	request := transport.requests[0]
	if header := request.Header.Get("X-Demo"); header != "static" {
		t.Fatalf("unexpected header value %q", header)
	}
	if request.URL.Query().Get("type") != "issue" {
		t.Fatalf("missing query param type")
	}
	if request.URL.Query().Get("since") == "" {
		t.Fatalf("missing since query param")
	}
}

func TestHTTPPollingHandlerErrorStatus(t *testing.T) {
	transport := &recordingTransport{
		status: http.StatusBadGateway,
		body:   []byte(`{"error":"bad_gateway"}`),
	}
	client := &http.Client{Transport: transport}
	handler := NewHTTPPollingHandler(client, zap.NewNop(), nil, nil)

	component := componentdomain.Component{
		Name: "test_component",
		Provider: componentdomain.Provider{
			Name: "demo",
		},
		Metadata: map[string]any{
			"ingestion": map[string]any{
				"mode":             "polling",
				"endpoint":         "https://example.local",
				"fingerprintField": "id",
				"cursor": map[string]any{
					"source": "fingerprint",
				},
			},
		},
	}

	req := PollingRequest{
		Binding: actiondomain.PollingBinding{
			Config: componentdomain.Config{
				Params: map[string]any{},
			},
		},
		Component: component,
		Cursor:    map[string]any{},
		Now:       time.Now().UTC(),
	}

	if _, err := handler.Poll(context.Background(), req); err == nil {
		t.Fatalf("expected error for non-2xx response")
	}
}

func TestHTTPPollingHandlerPollWithIdentity(t *testing.T) {
	identityID := uuid.New()
	userID := uuid.New()
	identity := identitydomain.Identity{
		ID:          identityID,
		UserID:      userID,
		Provider:    "github",
		AccessToken: "token-xyz",
	}
	repo := &identityRepoStub{identity: identity}

	payload := map[string]any{
		"items": []any{
			map[string]any{
				"id": "1",
			},
		},
	}
	body, err := json.Marshal(payload)
	if err != nil {
		t.Fatalf("marshal payload: %v", err)
	}

	transport := &recordingTransport{
		body: body,
	}
	client := &http.Client{Transport: transport}
	handler := NewHTTPPollingHandler(client, zap.NewNop(), repo, nil)

	component := componentdomain.Component{
		ID:   uuid.New(),
		Name: "repo_new_stars",
		Provider: componentdomain.Provider{
			Name: "github",
		},
		Metadata: map[string]any{
			"ingestion": map[string]any{
				"mode":    "polling",
				"handler": "http",
				"http": map[string]any{
					"endpoint": "https://api.github.com/repos/{{params.owner}}/{{params.repository}}/stargazers",
					"auth": map[string]any{
						"type":          "oauth",
						"identityParam": "identityId",
						"provider":      "github",
					},
					"headers": []any{
						map[string]any{
							"name":     "Authorization",
							"template": "Bearer {{identity.accessToken}}",
						},
					},
					"itemsPath":        "items",
					"fingerprintField": "id",
				},
			},
		},
	}

	req := PollingRequest{
		Binding: actiondomain.PollingBinding{
			Source: actiondomain.Source{
				ID:                uuid.New(),
				ComponentConfigID: uuid.New(),
				Mode:              actiondomain.ModePolling,
				Cursor:            map[string]any{},
			},
			AreaID: userID,
			UserID: userID,
			Config: componentdomain.Config{
				ID:          uuid.New(),
				ComponentID: component.ID,
				Params: map[string]any{
					"identityId": identityID.String(),
					"owner":      "octocat",
					"repository": "hello-world",
				},
			},
		},
		Component: component,
		Cursor:    map[string]any{},
		Now:       time.Now().UTC(),
	}

	result, err := handler.Poll(context.Background(), req)
	if err != nil {
		t.Fatalf("poll returned error: %v", err)
	}
	if len(result.Events) != 1 {
		t.Fatalf("expected 1 event got %d", len(result.Events))
	}
	if len(transport.requests) != 1 {
		t.Fatalf("expected a single HTTP request")
	}
	request := transport.requests[0]
	if auth := request.Header.Get("Authorization"); auth != "Bearer token-xyz" {
		t.Fatalf("unexpected authorization header %q", auth)
	}
	if repo.updated != nil {
		t.Fatalf("identity should not be updated when token is valid")
	}
}

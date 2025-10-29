package spotify

import (
	"context"
	"encoding/json"
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
)

func TestAddTrackExecutorSupports(t *testing.T) {
	exec := NewAddTrackExecutor(nil, nil, nil, nil, nil)

	component := &componentdomain.Component{
		Name: addTrackComponentName,
		Provider: componentdomain.Provider{
			Name: spotifyProviderName,
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

func TestAddTrackExecutorExecuteAddsTrack(t *testing.T) {
	userID := uuid.New()
	identityID := uuid.New()
	componentID := uuid.New()
	areaID := uuid.New()

	future := time.Now().Add(2 * time.Hour).UTC()
	identity := identitydomain.Identity{
		ID:           identityID,
		UserID:       userID,
		Provider:     spotifyProviderName,
		AccessToken:  "spotify-access-token",
		RefreshToken: "spotify-refresh-token",
		ExpiresAt:    &future,
	}

	repo := &identityRepoStub{identity: identity}
	client := &httpClientStub{
		response: http.Response{
			StatusCode: http.StatusCreated,
			Header: http.Header{
				"Content-Type": []string{"application/json"},
			},
			Body: io.NopCloser(strings.NewReader(`{"snapshot_id":"abc123"}`)),
		},
	}

	exec := NewAddTrackExecutor(repo, providerResolverStub{}, client, clockStub{now: future.Add(-time.Minute)}, nil)

	component := &componentdomain.Component{
		ID:       componentID,
		Name:     addTrackComponentName,
		Provider: componentdomain.Provider{Name: spotifyProviderName},
	}

	link := areadomain.Link{
		ID:     uuid.New(),
		AreaID: areaID,
		Role:   areadomain.LinkRoleReaction,
		Config: componentdomain.Config{
			ID:          uuid.New(),
			UserID:      userID,
			ComponentID: componentID,
			Name:        "Add liked song to playlist",
			Params: map[string]any{
				"identityId": identityID.String(),
				"playlistId": "https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M",
				"trackUri":   "11dFghVXANMlKmJXsNCbNl",
				"position":   0,
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

	if repo.updateCalled {
		t.Fatal("identity update should not be called when token valid")
	}

	if client.lastRequest == nil {
		t.Fatal("expected request to be issued")
	}

	expectedEndpoint := "https://api.spotify.com/v1/playlists/37i9dQZF1DXcBWIGoYBM5M/tracks"
	if client.lastRequest.URL.String() != expectedEndpoint {
		t.Fatalf("unexpected endpoint %s", client.lastRequest.URL.String())
	}

	if auth := client.lastRequest.Header.Get("Authorization"); auth != "Bearer spotify-access-token" {
		t.Fatalf("unexpected authorization header %q", auth)
	}

	defer client.lastRequest.Body.Close()
	bodyBytes, err := io.ReadAll(client.lastRequest.Body)
	if err != nil {
		t.Fatalf("read body: %v", err)
	}
	var payload map[string]any
	if err := json.Unmarshal(bodyBytes, &payload); err != nil {
		t.Fatalf("unmarshal request body: %v", err)
	}

	uris, ok := payload["uris"].([]any)
	if !ok || len(uris) != 1 {
		t.Fatalf("expected single uri entry got %v", payload["uris"])
	}
	if uri, ok := uris[0].(string); !ok || uri != "spotify:track:11dFghVXANMlKmJXsNCbNl" {
		t.Fatalf("unexpected track uri %v", uris[0])
	}
	if pos, ok := payload["position"].(float64); !ok || pos != 0 {
		t.Fatalf("unexpected position %v", payload["position"])
	}
}

func TestNormalizePlaylistID(t *testing.T) {
	cases := map[string]string{
		"37i9dQZF1DXcBWIGoYBM5M":                                          "37i9dQZF1DXcBWIGoYBM5M",
		"spotify:playlist:37i9dQZF1DXcBWIGoYBM5M":                         "37i9dQZF1DXcBWIGoYBM5M",
		"spotify:user:userid:playlist:37i9dQZF1DXcBWIGoYBM5M":             "37i9dQZF1DXcBWIGoYBM5M",
		"https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M?si=123": "37i9dQZF1DXcBWIGoYBM5M",
	}

	for input, expected := range cases {
		got, err := normalizePlaylistID(input)
		if err != nil {
			t.Fatalf("normalizePlaylistID(%q) returned error %v", input, err)
		}
		if got != expected {
			t.Fatalf("normalizePlaylistID(%q) = %q want %q", input, got, expected)
		}
	}
}

func TestNormalizeTrackURI(t *testing.T) {
	cases := map[string]string{
		"spotify:track:11dFghVXANMlKmJXsNCbNl":                         "spotify:track:11dFghVXANMlKmJXsNCbNl",
		"11dFghVXANMlKmJXsNCbNl":                                       "spotify:track:11dFghVXANMlKmJXsNCbNl",
		"https://open.spotify.com/track/11dFghVXANMlKmJXsNCbNl?si=123": "spotify:track:11dFghVXANMlKmJXsNCbNl",
		" spotify:track:11dFghVXANMlKmJXsNCbNl ":                       "spotify:track:11dFghVXANMlKmJXsNCbNl",
	}

	for input, expected := range cases {
		got, err := normalizeTrackURI(input)
		if err != nil {
			t.Fatalf("normalizeTrackURI(%q) returned error %v", input, err)
		}
		if got != expected {
			t.Fatalf("normalizeTrackURI(%q) = %q want %q", input, got, expected)
		}
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

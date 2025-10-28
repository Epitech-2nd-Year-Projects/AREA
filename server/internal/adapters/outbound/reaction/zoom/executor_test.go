package zoom

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"strings"
	"testing"
	"time"

	componentdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/component"
	"github.com/google/uuid"
	"go.uber.org/zap"
)

func TestMeetingExecutor_Supports(t *testing.T) {
	executor := NewMeetingExecutor(nil, nil, nil, nil, zap.NewNop())

	component := &componentdomain.Component{
		Name: createMeetingComponentName,
		Provider: componentdomain.Provider{
			Name: zoomProviderName,
		},
	}
	if !executor.Supports(component) {
		t.Fatalf("expected component to be supported")
	}

	unsupported := &componentdomain.Component{
		Name: "other",
		Provider: componentdomain.Provider{
			Name: zoomProviderName,
		},
	}
	if executor.Supports(unsupported) {
		t.Fatalf("expected component to be unsupported")
	}
}

func TestParseMeetingConfigScheduled(t *testing.T) {
	identityID := uuid.New()
	params := map[string]any{
		"identityId": identityID.String(),
		"userId":     "alice@example.com",
		"topic":      "Sprint planning",
		"startTime":  "2024-05-12T10:00:00Z",
		"timeZone":   "Europe/Paris",
		"duration":   json.Number("45"),
		"agenda":     strings.Repeat("A", 10),
		"password":   "secret",
	}

	cfg, err := parseMeetingConfig(params)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if cfg.identityID != identityID {
		t.Fatalf("unexpected identityID %s", cfg.identityID)
	}
	if cfg.userID != "alice@example.com" {
		t.Fatalf("unexpected userID %s", cfg.userID)
	}
	if cfg.topic != "Sprint planning" {
		t.Fatalf("unexpected topic %s", cfg.topic)
	}
	if cfg.startTime != "2024-05-12T10:00:00Z" {
		t.Fatalf("unexpected startTime %s", cfg.startTime)
	}
	if cfg.timeZone != "Europe/Paris" {
		t.Fatalf("unexpected timeZone %s", cfg.timeZone)
	}
	if cfg.duration != 45 {
		t.Fatalf("unexpected duration %d", cfg.duration)
	}
	if cfg.agenda != strings.Repeat("A", 10) {
		t.Fatalf("unexpected agenda %s", cfg.agenda)
	}
	if cfg.password != "secret" {
		t.Fatalf("unexpected password %s", cfg.password)
	}
	if cfg.meetingType != scheduledMeetingType {
		t.Fatalf("unexpected meetingType %d", cfg.meetingType)
	}
}

func TestParseMeetingConfigInstant(t *testing.T) {
	identityID := uuid.New()
	params := map[string]any{
		"identityId": identityID.String(),
		"topic":      "Standup",
	}

	cfg, err := parseMeetingConfig(params)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if cfg.userID != defaultZoomUserIdentifier {
		t.Fatalf("expected default userID, got %s", cfg.userID)
	}
	if cfg.meetingType != instantMeetingType {
		t.Fatalf("unexpected meetingType %d", cfg.meetingType)
	}
	if cfg.startTime != "" {
		t.Fatalf("expected empty startTime, got %s", cfg.startTime)
	}
}

func TestMeetingExecutor_CreateMeetingSuccess(t *testing.T) {
	client := &recordingClient{
		response: &http.Response{
			StatusCode: http.StatusCreated,
			Body:       io.NopCloser(strings.NewReader(`{"id":12345}`)),
			Header:     make(http.Header),
		},
	}
	clock := &staticClock{now: time.Unix(0, 0)}
	executor := NewMeetingExecutor(nil, nil, client, clock, zap.NewNop())

	cfg := meetingConfig{
		userID:      "alice@example.com",
		topic:       "Sprint planning",
		startTime:   "2024-05-12T10:00:00Z",
		duration:    30,
		meetingType: scheduledMeetingType,
	}

	result, unauthorized, err := executor.createMeeting(context.Background(), "token-123", cfg)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if unauthorized {
		t.Fatalf("expected authorized flow")
	}
	if !strings.Contains(result.Endpoint, "alice@example.com") {
		t.Fatalf("unexpected endpoint %s", result.Endpoint)
	}
	if client.lastRequest == nil {
		t.Fatalf("expected request to be recorded")
	}
	if client.lastRequest.Method != http.MethodPost {
		t.Fatalf("unexpected method %s", client.lastRequest.Method)
	}
	if got := client.lastRequest.Header.Get("Authorization"); got != "Bearer token-123" {
		t.Fatalf("unexpected authorization header %s", got)
	}
	if client.lastRequest.Header.Get("Content-Type") != contentTypeApplicationJSON {
		t.Fatalf("unexpected content type %s", client.lastRequest.Header.Get("Content-Type"))
	}

	bodyBytes, err := io.ReadAll(client.lastRequest.Body)
	if err != nil {
		t.Fatalf("failed to read request body: %v", err)
	}
	body := string(bodyBytes)
	if !strings.Contains(body, `"topic":"Sprint planning"`) {
		t.Fatalf("expected body to contain topic, got %s", body)
	}
	if !strings.Contains(body, `"duration":30`) {
		t.Fatalf("expected body to contain duration, got %s", body)
	}
}

func TestMeetingExecutor_CreateMeetingUnauthorized(t *testing.T) {
	client := &recordingClient{
		response: &http.Response{
			StatusCode: http.StatusUnauthorized,
			Body:       io.NopCloser(strings.NewReader(`{"code":124,"message":"Invalid token"}`)),
			Header:     make(http.Header),
		},
	}
	executor := NewMeetingExecutor(nil, nil, client, &staticClock{now: time.Unix(0, 0)}, zap.NewNop())
	cfg := meetingConfig{
		userID:      "me",
		topic:       "Instant",
		meetingType: instantMeetingType,
	}

	_, unauthorized, err := executor.createMeeting(context.Background(), "expired", cfg)
	if err == nil {
		t.Fatalf("expected error")
	}
	if !unauthorized {
		t.Fatalf("expected unauthorized flag")
	}
}

type recordingClient struct {
	lastRequest *http.Request
	response    *http.Response
	err         error
}

func (c *recordingClient) Do(req *http.Request) (*http.Response, error) {
	c.lastRequest = req
	if c.err != nil {
		return nil, c.err
	}
	return c.response, nil
}

type staticClock struct {
	now time.Time
}

func (c *staticClock) Now() time.Time {
	return c.now
}

package zoom

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"

	areadomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/area"
	componentdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/component"
	identitydomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/identity"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
	identityport "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound/identity"
	"github.com/google/uuid"
	"go.uber.org/zap"
)

const (
	zoomProviderName            = "zoom"
	createMeetingComponentName  = "zoom_create_meeting"
	zoomCreateMeetingEndpoint   = "https://api.zoom.us/v2/users/%s/meetings"
	defaultZoomUserIdentifier   = "me"
	scheduledMeetingType        = 2
	instantMeetingType          = 1
	maxAllowedAgendaLength      = 2000
	maxAllowedPasswordLength    = 10
	maxAllowedTopicLength       = 200
	minimumMeetingDuration      = 1
	maximumMeetingDuration      = 1440
	contentTypeApplicationJSON  = "application/json"
	userAgentHeaderValue        = "AREA-Server"
	authorizationHeaderTemplate = "Bearer %s"
)

// ProviderResolver exposes OAuth providers by name
type ProviderResolver interface {
	Provider(name string) (identityport.Provider, bool)
}

// HTTPClient models the subset of http.Client used by the executor
type HTTPClient interface {
	Do(req *http.Request) (*http.Response, error)
}

// Clock abstracts time retrieval for deterministic tests
type Clock interface {
	Now() time.Time
}

type systemClock struct{}

func (systemClock) Now() time.Time {
	return time.Now().UTC()
}

// MeetingExecutor delivers Zoom reactions that create meetings
type MeetingExecutor struct {
	identities identityport.Repository
	providers  ProviderResolver
	http       HTTPClient
	clock      Clock
	logger     *zap.Logger
}

// NewMeetingExecutor constructs a MeetingExecutor from its dependencies
func NewMeetingExecutor(identities identityport.Repository, providers ProviderResolver, client HTTPClient, clock Clock, logger *zap.Logger) *MeetingExecutor {
	if client == nil {
		client = http.DefaultClient
	}
	if clock == nil {
		clock = systemClock{}
	}
	if logger == nil {
		logger = zap.NewNop()
	}
	return &MeetingExecutor{
		identities: identities,
		providers:  providers,
		http:       client,
		clock:      clock,
		logger:     logger,
	}
}

// Supports reports whether the executor can handle the provided component
func (e *MeetingExecutor) Supports(component *componentdomain.Component) bool {
	if component == nil || component.Provider.Name == "" {
		return false
	}
	return strings.EqualFold(component.Name, createMeetingComponentName) &&
		strings.EqualFold(component.Provider.Name, zoomProviderName)
}

// Execute creates a Zoom meeting using the linked identity
func (e *MeetingExecutor) Execute(ctx context.Context, area areadomain.Area, link areadomain.Link) (outbound.ReactionResult, error) {
	if !e.Supports(link.Config.Component) {
		return outbound.ReactionResult{}, fmt.Errorf("zoom.MeetingExecutor: unsupported component")
	}
	if e.identities == nil || e.providers == nil {
		return outbound.ReactionResult{}, fmt.Errorf("zoom.MeetingExecutor: resolver not configured")
	}

	cfg, err := parseMeetingConfig(link.Config.Params)
	if err != nil {
		return outbound.ReactionResult{}, fmt.Errorf("zoom.MeetingExecutor: %w", err)
	}

	identity, err := e.identities.FindByID(ctx, cfg.identityID)
	if err != nil {
		return outbound.ReactionResult{}, fmt.Errorf("zoom.MeetingExecutor: identity lookup: %w", err)
	}
	if identity.UserID != area.UserID {
		return outbound.ReactionResult{}, fmt.Errorf("zoom.MeetingExecutor: identity not owned by user")
	}

	identity, accessToken, err := e.ensureAccessToken(ctx, identity, false)
	if err != nil {
		return outbound.ReactionResult{}, err
	}

	result, unauthorized, err := e.createMeeting(ctx, accessToken, cfg)
	if err != nil && unauthorized {
		identity, accessToken, err = e.ensureAccessToken(ctx, identity, true)
		if err != nil {
			return outbound.ReactionResult{}, err
		}
		result, unauthorized, err = e.createMeeting(ctx, accessToken, cfg)
	}
	if err != nil {
		return result, err
	}
	if unauthorized {
		return result, fmt.Errorf("zoom.MeetingExecutor: unauthorized after refresh")
	}

	e.logger.Info("zoom meeting created",
		zap.String("area_id", area.ID.String()),
		zap.String("identity_id", identity.ID.String()),
		zap.String("user_id", cfg.userID),
		zap.String("topic", cfg.topic),
	)
	return result, nil
}

func (e *MeetingExecutor) createMeeting(ctx context.Context, accessToken string, cfg meetingConfig) (outbound.ReactionResult, bool, error) {
	urlUser := url.PathEscape(cfg.userID)
	endpoint := fmt.Sprintf(zoomCreateMeetingEndpoint, urlUser)

	payload := map[string]any{
		"topic": cfg.topic,
		"type":  cfg.meetingType,
	}
	if cfg.startTime != "" {
		payload["start_time"] = cfg.startTime
	}
	if cfg.timeZone != "" {
		payload["timezone"] = cfg.timeZone
	}
	if cfg.duration > 0 {
		payload["duration"] = cfg.duration
	}
	if cfg.agenda != "" {
		payload["agenda"] = cfg.agenda
	}
	if cfg.password != "" {
		payload["password"] = cfg.password
	}

	bodyBytes, err := json.Marshal(payload)
	if err != nil {
		return outbound.ReactionResult{}, false, fmt.Errorf("zoom.MeetingExecutor: marshal payload: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint, bytes.NewReader(bodyBytes))
	if err != nil {
		return outbound.ReactionResult{}, false, fmt.Errorf("zoom.MeetingExecutor: build request: %w", err)
	}
	req.Header.Set("Authorization", fmt.Sprintf(authorizationHeaderTemplate, accessToken))
	req.Header.Set("Content-Type", contentTypeApplicationJSON)
	req.Header.Set("Accept", contentTypeApplicationJSON)
	req.Header.Set("User-Agent", userAgentHeaderValue)

	start := e.now()
	resp, err := e.http.Do(req)
	if err != nil {
		return outbound.ReactionResult{}, false, fmt.Errorf("zoom.MeetingExecutor: request failed: %w", err)
	}
	defer resp.Body.Close()

	respBody, _ := io.ReadAll(resp.Body)
	duration := e.now().Sub(start)

	requestHeaders := copyHeaders(req.Header)
	responseHeaders := copyHeaders(resp.Header)

	result := outbound.ReactionResult{
		Endpoint: endpoint,
		Request: map[string]any{
			"method":  http.MethodPost,
			"url":     endpoint,
			"headers": requestHeaders,
			"body":    string(bodyBytes),
		},
		Response: map[string]any{
			"body":    string(respBody),
			"headers": responseHeaders,
		},
		StatusCode: &resp.StatusCode,
		Duration:   duration,
	}

	if resp.StatusCode >= http.StatusBadRequest {
		if resp.StatusCode == http.StatusUnauthorized || resp.StatusCode == http.StatusForbidden {
			return result, true, fmt.Errorf("zoom.MeetingExecutor: received status %d", resp.StatusCode)
		}
		return result, false, fmt.Errorf("zoom.MeetingExecutor: received status %d", resp.StatusCode)
	}

	return result, false, nil
}

func (e *MeetingExecutor) ensureAccessToken(ctx context.Context, identity identitydomain.Identity, force bool) (identitydomain.Identity, string, error) {
	now := e.now()
	if identity.AccessToken != "" && !force && !identity.TokenExpired(now) {
		return identity, identity.AccessToken, nil
	}

	provider, ok := e.providers.Provider(zoomProviderName)
	if !ok {
		return identity, "", fmt.Errorf("zoom.MeetingExecutor: provider %s not configured", zoomProviderName)
	}

	exchange, err := provider.Refresh(ctx, identity)
	if err != nil {
		return identity, "", fmt.Errorf("zoom.MeetingExecutor: refresh token: %w", err)
	}

	refreshToken := exchange.Token.RefreshToken
	if refreshToken == "" {
		refreshToken = identity.RefreshToken
	}
	expiresAt := identity.ExpiresAt
	if !exchange.Token.ExpiresAt.IsZero() {
		expires := exchange.Token.ExpiresAt.UTC()
		expiresAt = &expires
	}
	scopes := exchange.Token.Scope
	if len(scopes) == 0 {
		scopes = identity.Scopes
	}

	updated := identity.WithTokens(exchange.Token.AccessToken, refreshToken, expiresAt, scopes)
	updated.UpdatedAt = now

	if err := e.identities.Update(ctx, updated); err != nil {
		return identity, "", fmt.Errorf("zoom.MeetingExecutor: update identity: %w", err)
	}

	return updated, updated.AccessToken, nil
}

func (e *MeetingExecutor) now() time.Time {
	if e.clock == nil {
		return time.Now().UTC()
	}
	return e.clock.Now().UTC()
}

type meetingConfig struct {
	identityID  uuid.UUID
	userID      string
	topic       string
	startTime   string
	timeZone    string
	duration    int
	agenda      string
	password    string
	meetingType int
}

func parseMeetingConfig(params map[string]any) (meetingConfig, error) {
	var cfg meetingConfig
	if params == nil {
		return cfg, fmt.Errorf("parse meeting config: params missing")
	}

	rawIdentity, ok := params["identityId"]
	if !ok {
		return cfg, fmt.Errorf("parse meeting config: identityId missing")
	}
	identityStr, err := toString(rawIdentity)
	if err != nil {
		return cfg, fmt.Errorf("parse meeting config: identityId invalid: %w", err)
	}
	identityID, err := uuid.Parse(strings.TrimSpace(identityStr))
	if err != nil {
		return cfg, fmt.Errorf("parse meeting config: identityId parse: %w", err)
	}
	cfg.identityID = identityID

	userID, err := optionalString(params, "userId", defaultZoomUserIdentifier)
	if err != nil {
		return cfg, fmt.Errorf("parse meeting config: userId invalid: %w", err)
	}
	if userID == "" {
		userID = defaultZoomUserIdentifier
	}
	cfg.userID = userID

	topic, err := requiredTrimmedString(params, "topic")
	if err != nil {
		return cfg, err
	}
	if len(topic) > maxAllowedTopicLength {
		return cfg, fmt.Errorf("parse meeting config: topic exceeds %d characters", maxAllowedTopicLength)
	}
	cfg.topic = topic

	startTime, err := optionalString(params, "startTime", "")
	if err != nil {
		return cfg, fmt.Errorf("parse meeting config: startTime invalid: %w", err)
	}
	if startTime != "" {
		if _, parseErr := time.Parse(time.RFC3339, startTime); parseErr != nil {
			return cfg, fmt.Errorf("parse meeting config: startTime parse: %w", parseErr)
		}
		cfg.meetingType = scheduledMeetingType
		cfg.startTime = startTime
	} else {
		cfg.meetingType = instantMeetingType
	}

	timeZone, err := optionalString(params, "timeZone", "")
	if err != nil {
		return cfg, fmt.Errorf("parse meeting config: timeZone invalid: %w", err)
	}
	cfg.timeZone = timeZone

	duration, err := optionalInt(params, "duration", 0)
	if err != nil {
		return cfg, fmt.Errorf("parse meeting config: duration invalid: %w", err)
	}
	if duration != 0 && (duration < minimumMeetingDuration || duration > maximumMeetingDuration) {
		return cfg, fmt.Errorf("parse meeting config: duration out of bounds")
	}
	cfg.duration = duration

	agenda, err := optionalString(params, "agenda", "")
	if err != nil {
		return cfg, fmt.Errorf("parse meeting config: agenda invalid: %w", err)
	}
	if len(agenda) > maxAllowedAgendaLength {
		return cfg, fmt.Errorf("parse meeting config: agenda exceeds %d characters", maxAllowedAgendaLength)
	}
	cfg.agenda = agenda

	password, err := optionalString(params, "password", "")
	if err != nil {
		return cfg, fmt.Errorf("parse meeting config: password invalid: %w", err)
	}
	if len(password) > maxAllowedPasswordLength {
		return cfg, fmt.Errorf("parse meeting config: password exceeds %d characters", maxAllowedPasswordLength)
	}
	cfg.password = password
	return cfg, nil
}

func requiredTrimmedString(params map[string]any, key string) (string, error) {
	value, ok := params[key]
	if !ok {
		return "", fmt.Errorf("parse meeting config: %s missing", key)
	}
	raw, err := toString(value)
	if err != nil {
		return "", fmt.Errorf("parse meeting config: %s invalid: %w", key, err)
	}
	trimmed := strings.TrimSpace(raw)
	if trimmed == "" {
		return "", fmt.Errorf("parse meeting config: %s empty", key)
	}
	return trimmed, nil
}

func optionalString(params map[string]any, key string, defaultValue string) (string, error) {
	value, ok := params[key]
	if !ok || value == nil {
		return defaultValue, nil
	}
	str, err := toString(value)
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(str), nil
}

func optionalInt(params map[string]any, key string, defaultValue int) (int, error) {
	value, ok := params[key]
	if !ok || value == nil {
		return defaultValue, nil
	}
	switch v := value.(type) {
	case int:
		return v, nil
	case int64:
		return int(v), nil
	case float64:
		return int(v), nil
	case json.Number:
		parsed, err := v.Int64()
		if err != nil {
			return 0, fmt.Errorf("unexpected number: %w", err)
		}
		return int(parsed), nil
	case string:
		trimmed := strings.TrimSpace(v)
		if trimmed == "" {
			return defaultValue, nil
		}
		parsed, err := strconv.Atoi(trimmed)
		if err != nil {
			return 0, fmt.Errorf("unexpected string: %w", err)
		}
		return parsed, nil
	default:
		return 0, fmt.Errorf("unexpected type %T", value)
	}
}

func toString(value any) (string, error) {
	switch v := value.(type) {
	case string:
		return v, nil
	case fmt.Stringer:
		return v.String(), nil
	default:
		return "", fmt.Errorf("expected string got %T", value)
	}
}

func copyHeaders(headers http.Header) map[string][]string {
	copied := make(map[string][]string, len(headers))
	for key, values := range headers {
		copied[key] = append([]string(nil), values...)
	}
	return copied
}

// Ensure MeetingExecutor satisfies the ComponentReactionHandler contract
var _ interface {
	Supports(*componentdomain.Component) bool
	Execute(context.Context, areadomain.Area, areadomain.Link) (outbound.ReactionResult, error)
} = (*MeetingExecutor)(nil)

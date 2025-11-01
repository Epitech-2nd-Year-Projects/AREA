package gcalendar

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
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
	gcalendarComponentName = "gcalendar_create_event"
	gcalendarProviderName  = "google"
	gcalendarAPIEndpoint   = "https://www.googleapis.com/calendar/v3/calendars/{{calendarId}}/events"
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

// Executor delivers Google Calendar reactions on behalf of the user through OAuth tokens
type Executor struct {
	identities identityport.Repository
	providers  ProviderResolver
	http       HTTPClient
	clock      Clock
	logger     *zap.Logger
}

// NewExecutor constructs a Google Calendar executor from its dependencies
func NewExecutor(identities identityport.Repository, providers ProviderResolver, client HTTPClient, clock Clock, logger *zap.Logger) *Executor {
	if client == nil {
		client = http.DefaultClient
	}
	if clock == nil {
		clock = systemClock{}
	}
	if logger == nil {
		logger = zap.NewNop()
	}
	return &Executor{identities: identities, providers: providers, http: client, clock: clock, logger: logger}
}

// Supports reports whether the executor can handle the provided component
func (e *Executor) Supports(component *componentdomain.Component) bool {
	if component == nil {
		return false
	}
	if strings.EqualFold(component.Name, gcalendarComponentName) && strings.EqualFold(component.Provider.Name, gcalendarProviderName) {
		return true
	}
	return false
}

// Execute creates a Google Calendar event
func (e *Executor) Execute(ctx context.Context, area areadomain.Area, link areadomain.Link) (outbound.ReactionResult, error) {
	if !e.Supports(link.Config.Component) {
		return outbound.ReactionResult{}, fmt.Errorf("gcalendar.Executor: unsupported component")
	}
	if e.identities == nil || e.providers == nil {
		return outbound.ReactionResult{}, fmt.Errorf("gcalendar.Executor: resolver not configured")
	}

	cfg, err := parseEventConfig(link.Config.Params)
	if err != nil {
		return outbound.ReactionResult{}, fmt.Errorf("gcalendar.Executor: %w", err)
	}

	identity, err := e.identities.FindByID(ctx, cfg.identityID)
	if err != nil {
		return outbound.ReactionResult{}, fmt.Errorf("gcalendar.Executor: identity lookup: %w", err)
	}
	if identity.UserID != area.UserID {
		return outbound.ReactionResult{}, fmt.Errorf("gcalendar.Executor: identity not owned by user")
	}

	identity, accessToken, err := e.ensureAccessToken(ctx, identity, false)
	if err != nil {
		return outbound.ReactionResult{}, err
	}

	endpoint := strings.ReplaceAll(gcalendarAPIEndpoint, "{{calendarId}}", cfg.calendarID)
	
	payload, err := buildEventPayload(cfg)
	if err != nil {
		return outbound.ReactionResult{}, fmt.Errorf("gcalendar.Executor: build payload: %w", err)
	}

	requestInfo := map[string]any{
		"summary":     cfg.summary,
		"description": cfg.description,
		"location":    cfg.location,
		"startTime":   cfg.startTime.Format(time.RFC3339),
		"endTime":     cfg.endTime.Format(time.RFC3339),
		"attendees":   append([]string(nil), cfg.attendees...),
	}

	result, unauthorized, err := e.createEvent(ctx, endpoint, accessToken, payload, requestInfo)
	if err != nil && unauthorized {
		identity, accessToken, err = e.ensureAccessToken(ctx, identity, true)
		if err != nil {
			return outbound.ReactionResult{}, err
		}
		result, unauthorized, err = e.createEvent(ctx, endpoint, accessToken, payload, requestInfo)
	}
	if err != nil {
		return result, err
	}
	if unauthorized {
		return result, fmt.Errorf("gcalendar.Executor: unauthorized after refresh")
	}

	e.logger.Info("gcalendar reaction delivered",
		zap.String("area_id", area.ID.String()),
		zap.String("identity_id", identity.ID.String()),
		zap.String("summary", cfg.summary),
	)
	return result, nil
}

func (e *Executor) ensureAccessToken(ctx context.Context, identity identitydomain.Identity, force bool) (identitydomain.Identity, string, error) {
	now := e.now()
	if identity.AccessToken != "" && !force && !identity.TokenExpired(now) {
		return identity, identity.AccessToken, nil
	}

	provider, ok := e.providers.Provider(gcalendarProviderName)
	if !ok {
		return identity, "", fmt.Errorf("gcalendar.Executor: provider %s not configured", gcalendarProviderName)
	}

	exchange, err := provider.Refresh(ctx, identity)
	if err != nil {
		return identity, "", fmt.Errorf("gcalendar.Executor: refresh token: %w", err)
	}

	refToken := exchange.Token.RefreshToken
	if refToken == "" {
		refToken = identity.RefreshToken
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

	updated := identity.WithTokens(exchange.Token.AccessToken, refToken, expiresAt, scopes)
	updated.UpdatedAt = now
	if err := e.identities.Update(ctx, updated); err != nil {
		return identity, "", fmt.Errorf("gcalendar.Executor: update identity: %w", err)
	}
	return updated, updated.AccessToken, nil
}

func (e *Executor) createEvent(ctx context.Context, endpoint string, accessToken string, payload []byte, request map[string]any) (outbound.ReactionResult, bool, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint, bytes.NewReader(payload))
	if err != nil {
		return outbound.ReactionResult{}, false, fmt.Errorf("gcalendar.Executor: build request: %w", err)
	}
	req.Header.Set("Authorization", "Bearer "+accessToken)
	req.Header.Set("Content-Type", "application/json")

	start := time.Now()
	resp, err := e.http.Do(req)
	if err != nil {
		return outbound.ReactionResult{}, false, fmt.Errorf("gcalendar.Executor: request failed: %w", err)
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	duration := time.Since(start)

	responseHeaders := map[string][]string{}
	for key, values := range resp.Header {
		responseHeaders[key] = append([]string(nil), values...)
	}

	result := outbound.ReactionResult{
		Endpoint: endpoint,
		Request:  cloneMap(request),
		Response: map[string]any{
			"body":    strings.TrimSpace(string(body)),
			"headers": responseHeaders,
		},
		StatusCode: &resp.StatusCode,
		Duration:   duration,
	}

	switch {
	case resp.StatusCode == http.StatusUnauthorized:
		return result, true, fmt.Errorf("gcalendar.Executor: unauthorized: %s", strings.TrimSpace(string(body)))
	case resp.StatusCode >= 400:
		return result, false, fmt.Errorf("gcalendar.Executor: api error %d: %s", resp.StatusCode, strings.TrimSpace(string(body)))
	default:
		return result, false, nil
	}
}

func (e *Executor) now() time.Time {
	if e.clock == nil {
		return time.Now().UTC()
	}
	return e.clock.Now().UTC()
}

func cloneMap(source map[string]any) map[string]any {
	if len(source) == 0 {
		return map[string]any{}
	}
	result := make(map[string]any, len(source))
	for key, value := range source {
		switch v := value.(type) {
		case []string:
			result[key] = append([]string(nil), v...)
		case map[string]any:
			result[key] = cloneMap(v)
		default:
			result[key] = v
		}
	}
	return result
}

func buildEventPayload(cfg eventConfig) ([]byte, error) {
	event := map[string]any{
		"summary": cfg.summary,
		"start": map[string]string{
			"dateTime": cfg.startTime.Format(time.RFC3339),
			"timeZone": "UTC",
		},
		"end": map[string]string{
			"dateTime": cfg.endTime.Format(time.RFC3339),
			"timeZone": "UTC",
		},
	}

	if cfg.description != "" {
		event["description"] = cfg.description
	}

	if cfg.location != "" {
		event["location"] = cfg.location
	}

	if len(cfg.attendees) > 0 {
		attendees := make([]map[string]string, len(cfg.attendees))
		for i, email := range cfg.attendees {
			attendees[i] = map[string]string{"email": email}
		}
		event["attendees"] = attendees
	}

	return json.Marshal(event)
}

type eventConfig struct {
	identityID           uuid.UUID
	calendarID           string
	summary              string
	description          string
	location             string
	startTime            time.Time
	endTime              time.Time
	attendees            []string
}

func parseEventConfig(params map[string]any) (eventConfig, error) {
	cfg := eventConfig{
		calendarID: "primary",
	}

	// Parse identity ID
	identityRaw, ok := params["identityId"]
	if !ok {
		return cfg, fmt.Errorf("identityId missing")
	}
	identityStr, err := toString(identityRaw)
	if err != nil {
		return cfg, fmt.Errorf("identityId invalid")
	}
	identityID, err := uuid.Parse(strings.TrimSpace(identityStr))
	if err != nil {
		return cfg, fmt.Errorf("identityId parse: %w", err)
	}
	cfg.identityID = identityID

	// Parse calendar ID
	if calendarRaw, ok := params["calendarId"]; ok {
		calendarID, err := toString(calendarRaw)
		if err == nil && strings.TrimSpace(calendarID) != "" {
			cfg.calendarID = strings.TrimSpace(calendarID)
		}
	}

	// Parse summary
	summaryRaw, ok := params["summary"]
	if !ok {
		return cfg, fmt.Errorf("summary missing")
	}
	summary, err := toString(summaryRaw)
	if err != nil {
		return cfg, fmt.Errorf("summary invalid")
	}
	cfg.summary = strings.TrimSpace(summary)
	if cfg.summary == "" {
		return cfg, fmt.Errorf("summary cannot be empty")
	}

	// Parse description
	if descRaw, ok := params["description"]; ok {
		if desc, err := toString(descRaw); err == nil {
			cfg.description = strings.TrimSpace(desc)
		}
	}

	// Parse location
	if locRaw, ok := params["location"]; ok {
		if loc, err := toString(locRaw); err == nil {
			cfg.location = strings.TrimSpace(loc)
		}
	}

	// Parse start time
	startRaw, ok := params["startTime"]
	if !ok {
		return cfg, fmt.Errorf("startTime missing")
	}
	startStr, err := toString(startRaw)
	if err != nil {
		return cfg, fmt.Errorf("startTime invalid")
	}
	startTime, err := time.Parse(time.RFC3339, strings.TrimSpace(startStr))
	if err != nil {
		return cfg, fmt.Errorf("startTime parse: %w", err)
	}
	cfg.startTime = startTime

	// Parse end time
	endRaw, ok := params["endTime"]
	if !ok {
		return cfg, fmt.Errorf("endTime missing")
	}
	endStr, err := toString(endRaw)
	if err != nil {
		return cfg, fmt.Errorf("endTime invalid")
	}
	endTime, err := time.Parse(time.RFC3339, strings.TrimSpace(endStr))
	if err != nil {
		return cfg, fmt.Errorf("endTime parse: %w", err)
	}
	cfg.endTime = endTime

	// Validate that end time is after start time
	if endTime.Before(startTime) || endTime.Equal(startTime) {
		return cfg, fmt.Errorf("endTime must be after startTime")
	}

	// Parse attendees
	if attendeesRaw, ok := params["attendees"]; ok {
		if attendees, err := parseList(attendeesRaw); err == nil {
			cfg.attendees = attendees
		}
	}

	return cfg, nil
}

func toString(v any) (string, error) {
	switch val := v.(type) {
	case string:
		return val, nil
	case float64:
		return fmt.Sprintf("%.0f", val), nil
	case bool:
		return fmt.Sprintf("%v", val), nil
	default:
		return "", fmt.Errorf("cannot convert %T to string", v)
	}
}

func parseList(v any) ([]string, error) {
	switch val := v.(type) {
	case []string:
		return val, nil
	case string:
		if val == "" {
			return []string{}, nil
		}
		return strings.Split(val, ","), nil
	case []any:
		result := make([]string, 0, len(val))
		for _, item := range val {
			if str, ok := item.(string); ok {
				result = append(result, strings.TrimSpace(str))
			}
		}
		return result, nil
	default:
		return nil, fmt.Errorf("cannot convert %T to string list", v)
	}
}

type systemClock struct{}

func (systemClock) Now() time.Time { return time.Now().UTC() }

// Ensure Executor satisfies the ComponentReactionHandler contract
var _ interface {
	Supports(*componentdomain.Component) bool
	Execute(context.Context, areadomain.Area, areadomain.Link) (outbound.ReactionResult, error)
} = (*Executor)(nil)
package reddit

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"net/url"
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
	redditComponentName      = "reddit_comment_post"
	redditProviderName       = "reddit"
	redditCommentAPIEndpoint = "https://oauth.reddit.com/api/comment"
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

// Executor posts comments to Reddit submissions using OAuth identities
type Executor struct {
	identities identityport.Repository
	providers  ProviderResolver
	http       HTTPClient
	clock      Clock
	logger     *zap.Logger
}

// NewExecutor constructs a Reddit executor from its dependencies
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
	return &Executor{
		identities: identities,
		providers:  providers,
		http:       client,
		clock:      clock,
		logger:     logger,
	}
}

// Supports reports whether the executor can handle the provided component
func (e *Executor) Supports(component *componentdomain.Component) bool {
	if component == nil {
		return false
	}
	return strings.EqualFold(component.Name, redditComponentName) &&
		strings.EqualFold(component.Provider.Name, redditProviderName)
}

// Execute delivers the Reddit comment reaction payload
func (e *Executor) Execute(ctx context.Context, area areadomain.Area, link areadomain.Link) (outbound.ReactionResult, error) {
	if !e.Supports(link.Config.Component) {
		return outbound.ReactionResult{}, fmt.Errorf("reddit.Executor: unsupported component")
	}
	if e.identities == nil || e.providers == nil {
		return outbound.ReactionResult{}, fmt.Errorf("reddit.Executor: resolver not configured")
	}

	cfg, err := parseCommentConfig(link.Config.Params)
	if err != nil {
		return outbound.ReactionResult{}, fmt.Errorf("reddit.Executor: %w", err)
	}

	identity, err := e.identities.FindByID(ctx, cfg.identityID)
	if err != nil {
		return outbound.ReactionResult{}, fmt.Errorf("reddit.Executor: identity lookup: %w", err)
	}
	if identity.UserID != area.UserID {
		return outbound.ReactionResult{}, fmt.Errorf("reddit.Executor: identity not owned by user")
	}

	identity, accessToken, err := e.ensureAccessToken(ctx, identity, false)
	if err != nil {
		return outbound.ReactionResult{}, err
	}

	payload := url.Values{}
	payload.Set("thing_id", cfg.thingID)
	payload.Set("text", cfg.text)
	payload.Set("api_type", "json")

	requestInfo := map[string]any{
		"thing_id": cfg.thingID,
		"text":     cfg.text,
	}

	result, unauthorized, err := e.postComment(ctx, accessToken, payload, requestInfo)
	if err != nil && unauthorized {
		identity, accessToken, err = e.ensureAccessToken(ctx, identity, true)
		if err != nil {
			return outbound.ReactionResult{}, err
		}
		result, unauthorized, err = e.postComment(ctx, accessToken, payload, requestInfo)
	}
	if err != nil {
		return result, err
	}
	if unauthorized {
		return result, fmt.Errorf("reddit.Executor: unauthorized after refresh")
	}

	e.logger.Info("reddit comment posted",
		zap.String("area_id", area.ID.String()),
		zap.String("identity_id", identity.ID.String()),
		zap.String("thing_id", cfg.thingID),
	)

	return result, nil
}

func (e *Executor) ensureAccessToken(ctx context.Context, identity identitydomain.Identity, force bool) (identitydomain.Identity, string, error) {
	now := e.now()
	if identity.AccessToken != "" && !force && !identity.TokenExpired(now) {
		return identity, identity.AccessToken, nil
	}

	provider, ok := e.providers.Provider(redditProviderName)
	if !ok {
		return identity, "", fmt.Errorf("reddit.Executor: provider %s not configured", redditProviderName)
	}

	exchange, err := provider.Refresh(ctx, identity)
	if err != nil {
		return identity, "", fmt.Errorf("reddit.Executor: refresh token: %w", err)
	}

	refreshToken := exchange.Token.RefreshToken
	if refreshToken == "" {
		refreshToken = identity.RefreshToken
	}
	expiresAt := identity.ExpiresAt
	if !exchange.Token.ExpiresAt.IsZero() {
		exp := exchange.Token.ExpiresAt.UTC()
		expiresAt = &exp
	}
	scopes := exchange.Token.Scope
	if len(scopes) == 0 {
		scopes = identity.Scopes
	}

	updated := identity.WithTokens(exchange.Token.AccessToken, refreshToken, expiresAt, scopes)
	updated.UpdatedAt = now
	if err := e.identities.Update(ctx, updated); err != nil {
		return identity, "", fmt.Errorf("reddit.Executor: update identity: %w", err)
	}
	return updated, updated.AccessToken, nil
}

func (e *Executor) postComment(ctx context.Context, accessToken string, payload url.Values, request map[string]any) (outbound.ReactionResult, bool, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, redditCommentAPIEndpoint, strings.NewReader(payload.Encode()))
	if err != nil {
		return outbound.ReactionResult{}, false, fmt.Errorf("reddit.Executor: build request: %w", err)
	}
	req.Header.Set("Authorization", "Bearer "+accessToken)
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	req.Header.Set("Accept", "application/json")
	req.Header.Set("User-Agent", "AREA-Server")

	start := time.Now()
	resp, err := e.http.Do(req)
	if err != nil {
		return outbound.ReactionResult{}, false, fmt.Errorf("reddit.Executor: request failed: %w", err)
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	duration := time.Since(start)

	responseHeaders := map[string][]string{}
	for key, values := range resp.Header {
		responseHeaders[key] = append([]string(nil), values...)
	}

	result := outbound.ReactionResult{
		Endpoint: redditCommentAPIEndpoint,
		Request:  cloneMap(request),
		Response: map[string]any{
			"body":    strings.TrimSpace(string(body)),
			"headers": responseHeaders,
		},
		StatusCode: &resp.StatusCode,
		Duration:   duration,
	}

	thingID, _ := request["thing_id"].(string)

	switch {
	case resp.StatusCode == http.StatusUnauthorized:
		e.logger.Warn("reddit comment request unauthorized",
			zap.String("thing_id", thingID),
			zap.Int("status", resp.StatusCode),
			zap.String("body", strings.TrimSpace(string(body))))
		return result, true, fmt.Errorf("reddit.Executor: unauthorized: %s", strings.TrimSpace(string(body)))
	case resp.StatusCode >= 400:
		e.logger.Error("reddit comment request failed",
			zap.String("thing_id", thingID),
			zap.Int("status", resp.StatusCode),
			zap.String("body", strings.TrimSpace(string(body))))
		return result, false, fmt.Errorf("reddit.Executor: api error %d: %s", resp.StatusCode, strings.TrimSpace(string(body)))
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

type commentConfig struct {
	identityID uuid.UUID
	thingID    string
	text       string
}

func parseCommentConfig(params map[string]any) (commentConfig, error) {
	cfg := commentConfig{}

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

	thingRaw, ok := params["thingId"]
	if !ok {
		return cfg, fmt.Errorf("thingId missing")
	}
	cfg.thingID, err = toString(thingRaw)
	if err != nil {
		return cfg, fmt.Errorf("thingId invalid")
	}
	cfg.thingID = strings.TrimSpace(cfg.thingID)
	if cfg.thingID == "" {
		return cfg, fmt.Errorf("thingId empty")
	}
	if !strings.HasPrefix(strings.ToLower(cfg.thingID), "t3_") {
		cfg.thingID = "t3_" + cfg.thingID
	}

	textRaw, ok := params["text"]
	if !ok {
		return cfg, fmt.Errorf("text missing")
	}
	cfg.text, err = toString(textRaw)
	if err != nil {
		return cfg, fmt.Errorf("text invalid")
	}
	cfg.text = strings.TrimSpace(cfg.text)
	if cfg.text == "" {
		return cfg, fmt.Errorf("text empty")
	}

	return cfg, nil
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

func toString(value any) (string, error) {
	switch v := value.(type) {
	case string:
		return v, nil
	case fmt.Stringer:
		return v.String(), nil
	default:
		return "", fmt.Errorf("not a string")
	}
}

type systemClock struct{}

func (systemClock) Now() time.Time { return time.Now().UTC() }

// Ensure Executor satisfies the ComponentReactionHandler contract
var _ interface {
	Supports(*componentdomain.Component) bool
	Execute(context.Context, areadomain.Area, areadomain.Link) (outbound.ReactionResult, error)
} = (*Executor)(nil)

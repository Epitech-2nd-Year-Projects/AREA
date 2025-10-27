package slack

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
	slackProviderName        = "slack"
	postMessageComponentName = "slack_post_message"
	slackPostMessageEndpoint = "https://slack.com/api/chat.postMessage"
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

// MessageExecutor delivers Slack reactions that send channel messages
type MessageExecutor struct {
	identities identityport.Repository
	providers  ProviderResolver
	http       HTTPClient
	clock      Clock
	logger     *zap.Logger
}

// NewMessageExecutor constructs a MessageExecutor from its dependencies
func NewMessageExecutor(identities identityport.Repository, providers ProviderResolver, client HTTPClient, clock Clock, logger *zap.Logger) *MessageExecutor {
	if client == nil {
		client = http.DefaultClient
	}
	if clock == nil {
		clock = systemClock{}
	}
	if logger == nil {
		logger = zap.NewNop()
	}
	return &MessageExecutor{
		identities: identities,
		providers:  providers,
		http:       client,
		clock:      clock,
		logger:     logger,
	}
}

// Supports reports whether the executor can handle the provided component
func (e *MessageExecutor) Supports(component *componentdomain.Component) bool {
	if component == nil || component.Provider.Name == "" {
		return false
	}
	return strings.EqualFold(component.Name, postMessageComponentName) &&
		strings.EqualFold(component.Provider.Name, slackProviderName)
}

// Execute posts a Slack message using the linked identity
func (e *MessageExecutor) Execute(ctx context.Context, area areadomain.Area, link areadomain.Link) (outbound.ReactionResult, error) {
	if !e.Supports(link.Config.Component) {
		return outbound.ReactionResult{}, fmt.Errorf("slack.MessageExecutor: unsupported component")
	}
	if e.identities == nil || e.providers == nil {
		return outbound.ReactionResult{}, fmt.Errorf("slack.MessageExecutor: resolver not configured")
	}

	cfg, err := parseMessageConfig(link.Config.Params)
	if err != nil {
		return outbound.ReactionResult{}, fmt.Errorf("slack.MessageExecutor: %w", err)
	}

	identity, err := e.identities.FindByID(ctx, cfg.identityID)
	if err != nil {
		return outbound.ReactionResult{}, fmt.Errorf("slack.MessageExecutor: identity lookup: %w", err)
	}
	if identity.UserID != area.UserID {
		return outbound.ReactionResult{}, fmt.Errorf("slack.MessageExecutor: identity not owned by user")
	}

	identity, accessToken, err := e.ensureAccessToken(ctx, identity, false)
	if err != nil {
		return outbound.ReactionResult{}, err
	}

	result, unauthorized, err := e.postMessage(ctx, accessToken, cfg)
	if err != nil && unauthorized {
		identity, accessToken, err = e.ensureAccessToken(ctx, identity, true)
		if err != nil {
			return outbound.ReactionResult{}, err
		}
		result, unauthorized, err = e.postMessage(ctx, accessToken, cfg)
	}
	if err != nil {
		return result, err
	}
	if unauthorized {
		return result, fmt.Errorf("slack.MessageExecutor: unauthorized after refresh")
	}

	e.logger.Info("slack message sent",
		zap.String("area_id", area.ID.String()),
		zap.String("identity_id", identity.ID.String()),
		zap.String("channel_id", cfg.channelID),
	)
	return result, nil
}

func (e *MessageExecutor) postMessage(ctx context.Context, accessToken string, cfg messageConfig) (outbound.ReactionResult, bool, error) {
	payload := map[string]any{
		"channel": cfg.channelID,
		"text":    cfg.text,
	}
	if cfg.threadTs != "" {
		payload["thread_ts"] = cfg.threadTs
	}

	bodyBytes, err := json.Marshal(payload)
	if err != nil {
		return outbound.ReactionResult{}, false, fmt.Errorf("slack.MessageExecutor: marshal payload: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, slackPostMessageEndpoint, bytes.NewReader(bodyBytes))
	if err != nil {
		return outbound.ReactionResult{}, false, fmt.Errorf("slack.MessageExecutor: build request: %w", err)
	}
	req.Header.Set("Authorization", "Bearer "+accessToken)
	req.Header.Set("Content-Type", "application/json; charset=utf-8")
	req.Header.Set("Accept", "application/json")
	req.Header.Set("User-Agent", "AREA-Server")

	start := e.now()
	resp, err := e.http.Do(req)
	if err != nil {
		return outbound.ReactionResult{}, false, fmt.Errorf("slack.MessageExecutor: request failed: %w", err)
	}
	defer resp.Body.Close()

	respBody, _ := io.ReadAll(resp.Body)
	duration := e.now().Sub(start)

	requestHeaders := copyHeaders(req.Header)
	responseHeaders := copyHeaders(resp.Header)

	result := outbound.ReactionResult{
		Endpoint: slackPostMessageEndpoint,
		Request: map[string]any{
			"method":  http.MethodPost,
			"url":     slackPostMessageEndpoint,
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

	var ack slackResponse
	if len(respBody) > 0 {
		_ = json.Unmarshal(respBody, &ack)
	}

	if resp.StatusCode >= 400 || !ack.OK {
		unauthorized := isSlackUnauthorized(resp.StatusCode, ack.Error)
		errMsg := strings.TrimSpace(ack.Error)
		if errMsg == "" {
			errMsg = strings.TrimSpace(string(respBody))
		}
		if errMsg == "" {
			errMsg = fmt.Sprintf("received status %d", resp.StatusCode)
		}
		return result, unauthorized, fmt.Errorf("slack.MessageExecutor: %s", errMsg)
	}

	return result, false, nil
}

func (e *MessageExecutor) ensureAccessToken(ctx context.Context, identity identitydomain.Identity, force bool) (identitydomain.Identity, string, error) {
	now := e.now()
	if identity.AccessToken != "" && !force && !identity.TokenExpired(now) {
		return identity, identity.AccessToken, nil
	}

	provider, ok := e.providers.Provider(slackProviderName)
	if !ok {
		return identity, "", fmt.Errorf("slack.MessageExecutor: provider %s not configured", slackProviderName)
	}

	exchange, err := provider.Refresh(ctx, identity)
	if err != nil {
		return identity, "", fmt.Errorf("slack.MessageExecutor: refresh token: %w", err)
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
	updated := identity.WithTokens(exchange.Token.AccessToken, refreshToken, expiresAt, exchange.Token.Scope)

	if err := e.identities.Update(ctx, updated); err != nil {
		return identity, "", fmt.Errorf("slack.MessageExecutor: update identity: %w", err)
	}

	return updated, updated.AccessToken, nil
}

func (e *MessageExecutor) now() time.Time {
	if e.clock == nil {
		return time.Now().UTC()
	}
	return e.clock.Now().UTC()
}

type slackResponse struct {
	OK    bool   `json:"ok"`
	Error string `json:"error"`
}

func isSlackUnauthorized(status int, code string) bool {
	if status == http.StatusUnauthorized || status == http.StatusForbidden {
		return true
	}
	switch strings.TrimSpace(code) {
	case "invalid_auth", "token_revoked", "account_inactive", "not_authed", "invalid_token", "expired_token":
		return true
	default:
		return false
	}
}

type messageConfig struct {
	identityID uuid.UUID
	channelID  string
	text       string
	threadTs   string
}

func parseMessageConfig(params map[string]any) (messageConfig, error) {
	var cfg messageConfig
	if params == nil {
		return cfg, fmt.Errorf("parse message config: params missing")
	}

	rawIdentity, ok := params["identityId"]
	if !ok {
		return cfg, fmt.Errorf("parse message config: identityId missing")
	}
	identityStr, err := toString(rawIdentity)
	if err != nil {
		return cfg, fmt.Errorf("parse message config: identityId invalid: %w", err)
	}
	identityID, err := uuid.Parse(identityStr)
	if err != nil {
		return cfg, fmt.Errorf("parse message config: parse identityId: %w", err)
	}
	cfg.identityID = identityID

	channelID, err := requiredString(params, "channelId")
	if err != nil {
		return cfg, err
	}
	cfg.channelID = channelID

	text, err := requiredString(params, "text")
	if err != nil {
		return cfg, err
	}
	cfg.text = text

	threadTs, err := optionalString(params, "threadTs")
	if err != nil {
		return cfg, fmt.Errorf("parse message config: threadTs invalid: %w", err)
	}
	cfg.threadTs = threadTs

	return cfg, nil
}

func requiredString(params map[string]any, key string) (string, error) {
	value, ok := params[key]
	if !ok {
		return "", fmt.Errorf("parse message config: %s missing", key)
	}
	str, err := toString(value)
	if err != nil {
		return "", fmt.Errorf("parse message config: %s invalid: %w", key, err)
	}
	trimmed := strings.TrimSpace(str)
	if trimmed == "" {
		return "", fmt.Errorf("parse message config: %s empty", key)
	}
	return trimmed, nil
}

func optionalString(params map[string]any, key string) (string, error) {
	value, ok := params[key]
	if !ok {
		return "", nil
	}
	str, err := toString(value)
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(str), nil
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

// Ensure MessageExecutor satisfies the ComponentReactionHandler contract
var _ interface {
	Supports(*componentdomain.Component) bool
	Execute(context.Context, areadomain.Area, areadomain.Link) (outbound.ReactionResult, error)
} = (*MessageExecutor)(nil)

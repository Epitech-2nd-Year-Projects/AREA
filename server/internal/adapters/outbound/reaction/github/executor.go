package github

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
	githubProviderName        = "github"
	createIssueComponentName  = "github_create_issue"
	githubCreateIssueEndpoint = "https://api.github.com/repos/%s/%s/issues"
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

// IssueExecutor delivers GitHub reactions that create issues
type IssueExecutor struct {
	identities identityport.Repository
	providers  ProviderResolver
	http       HTTPClient
	clock      Clock
	logger     *zap.Logger
}

// NewIssueExecutor constructs an IssueExecutor from its dependencies
func NewIssueExecutor(identities identityport.Repository, providers ProviderResolver, client HTTPClient, clock Clock, logger *zap.Logger) *IssueExecutor {
	if client == nil {
		client = http.DefaultClient
	}
	if clock == nil {
		clock = systemClock{}
	}
	if logger == nil {
		logger = zap.NewNop()
	}
	return &IssueExecutor{
		identities: identities,
		providers:  providers,
		http:       client,
		clock:      clock,
		logger:     logger,
	}
}

// Supports reports whether the executor can handle the provided component
func (e *IssueExecutor) Supports(component *componentdomain.Component) bool {
	if component == nil || component.Provider.Name == "" {
		return false
	}
	return strings.EqualFold(component.Name, createIssueComponentName) &&
		strings.EqualFold(component.Provider.Name, githubProviderName)
}

// Execute creates a GitHub issue using the linked identity
func (e *IssueExecutor) Execute(ctx context.Context, area areadomain.Area, link areadomain.Link) (outbound.ReactionResult, error) {
	if !e.Supports(link.Config.Component) {
		return outbound.ReactionResult{}, fmt.Errorf("github.IssueExecutor: unsupported component")
	}
	if e.identities == nil || e.providers == nil {
		return outbound.ReactionResult{}, fmt.Errorf("github.IssueExecutor: resolver not configured")
	}

	cfg, err := parseIssueConfig(link.Config.Params)
	if err != nil {
		return outbound.ReactionResult{}, fmt.Errorf("github.IssueExecutor: %w", err)
	}

	identity, err := e.identities.FindByID(ctx, cfg.identityID)
	if err != nil {
		return outbound.ReactionResult{}, fmt.Errorf("github.IssueExecutor: identity lookup: %w", err)
	}
	if identity.UserID != area.UserID {
		return outbound.ReactionResult{}, fmt.Errorf("github.IssueExecutor: identity not owned by user")
	}

	identity, accessToken, err := e.ensureAccessToken(ctx, identity, false)
	if err != nil {
		return outbound.ReactionResult{}, err
	}

	result, unauthorized, err := e.createIssue(ctx, accessToken, cfg)
	if err != nil && unauthorized {
		identity, accessToken, err = e.ensureAccessToken(ctx, identity, true)
		if err != nil {
			return outbound.ReactionResult{}, err
		}
		result, unauthorized, err = e.createIssue(ctx, accessToken, cfg)
	}
	if err != nil {
		return result, err
	}
	if unauthorized {
		return result, fmt.Errorf("github.IssueExecutor: unauthorized after refresh")
	}

	e.logger.Info("github issue created",
		zap.String("area_id", area.ID.String()),
		zap.String("identity_id", identity.ID.String()),
		zap.String("repository", cfg.owner+"/"+cfg.repository),
	)
	return result, nil
}

func (e *IssueExecutor) createIssue(ctx context.Context, accessToken string, cfg issueConfig) (outbound.ReactionResult, bool, error) {
	endpoint := fmt.Sprintf(githubCreateIssueEndpoint, cfg.owner, cfg.repository)

	payload := map[string]any{
		"title": cfg.title,
	}
	if cfg.body != "" {
		payload["body"] = cfg.body
	}
	if len(cfg.labels) > 0 {
		payload["labels"] = append([]string(nil), cfg.labels...)
	}

	bodyBytes, err := json.Marshal(payload)
	if err != nil {
		return outbound.ReactionResult{}, false, fmt.Errorf("github.IssueExecutor: marshal payload: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint, bytes.NewReader(bodyBytes))
	if err != nil {
		return outbound.ReactionResult{}, false, fmt.Errorf("github.IssueExecutor: build request: %w", err)
	}
	req.Header.Set("Authorization", "Bearer "+accessToken)
	req.Header.Set("Accept", "application/vnd.github+json")
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("User-Agent", "AREA-Server")

	start := time.Now()
	resp, err := e.http.Do(req)
	if err != nil {
		return outbound.ReactionResult{}, false, fmt.Errorf("github.IssueExecutor: request failed: %w", err)
	}
	defer resp.Body.Close()

	respBody, _ := io.ReadAll(resp.Body)
	duration := time.Since(start)

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

	if resp.StatusCode >= 400 {
		if resp.StatusCode == http.StatusUnauthorized {
			return result, true, fmt.Errorf("github.IssueExecutor: received status %d", resp.StatusCode)
		}
		return result, false, fmt.Errorf("github.IssueExecutor: received status %d", resp.StatusCode)
	}

	return result, false, nil
}

func (e *IssueExecutor) ensureAccessToken(ctx context.Context, identity identitydomain.Identity, force bool) (identitydomain.Identity, string, error) {
	now := e.now()
	if identity.AccessToken != "" && !force && !identity.TokenExpired(now) {
		return identity, identity.AccessToken, nil
	}

	provider, ok := e.providers.Provider(githubProviderName)
	if !ok {
		return identity, "", fmt.Errorf("github.IssueExecutor: provider %s not configured", githubProviderName)
	}

	exchange, err := provider.Refresh(ctx, identity)
	if err != nil {
		return identity, "", fmt.Errorf("github.IssueExecutor: refresh token: %w", err)
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
		return identity, "", fmt.Errorf("github.IssueExecutor: update identity: %w", err)
	}

	return updated, updated.AccessToken, nil
}

func (e *IssueExecutor) now() time.Time {
	if e.clock == nil {
		return time.Now().UTC()
	}
	return e.clock.Now().UTC()
}

type issueConfig struct {
	identityID uuid.UUID
	owner      string
	repository string
	title      string
	body       string
	labels     []string
}

func parseIssueConfig(params map[string]any) (issueConfig, error) {
	var cfg issueConfig
	if params == nil {
		return cfg, fmt.Errorf("parse issue config: params missing")
	}

	rawIdentity, ok := params["identityId"]
	if !ok {
		return cfg, fmt.Errorf("parse issue config: identityId missing")
	}
	identityStr, err := toString(rawIdentity)
	if err != nil {
		return cfg, fmt.Errorf("parse issue config: identityId invalid: %w", err)
	}
	identityID, err := uuid.Parse(identityStr)
	if err != nil {
		return cfg, fmt.Errorf("parse issue config: parse identityId: %w", err)
	}
	cfg.identityID = identityID

	owner, err := requiredString(params, "owner")
	if err != nil {
		return cfg, err
	}
	cfg.owner = owner

	repository, err := requiredString(params, "repository")
	if err != nil {
		return cfg, err
	}
	cfg.repository = repository

	title, err := requiredString(params, "title")
	if err != nil {
		return cfg, err
	}
	cfg.title = title

	if body, ok := params["body"]; ok {
		bodyStr, err := toString(body)
		if err != nil {
			return cfg, fmt.Errorf("parse issue config: body invalid: %w", err)
		}
		cfg.body = bodyStr
	}

	labels, err := parseLabels(params["labels"])
	if err != nil {
		return cfg, fmt.Errorf("parse issue config: labels invalid: %w", err)
	}
	cfg.labels = labels
	return cfg, nil
}

func requiredString(params map[string]any, key string) (string, error) {
	value, ok := params[key]
	if !ok {
		return "", fmt.Errorf("parse issue config: %s missing", key)
	}
	str, err := toString(value)
	if err != nil {
		return "", fmt.Errorf("parse issue config: %s invalid: %w", key, err)
	}
	if trimmed := strings.TrimSpace(str); trimmed != "" {
		return trimmed, nil
	}
	return "", fmt.Errorf("parse issue config: %s empty", key)
}

func parseLabels(value any) ([]string, error) {
	if value == nil {
		return nil, nil
	}

	switch v := value.(type) {
	case string:
		return splitLabels(v), nil
	case []string:
		out := make([]string, 0, len(v))
		for _, item := range v {
			if trimmed := strings.TrimSpace(item); trimmed != "" {
				out = append(out, trimmed)
			}
		}
		return out, nil
	case []any:
		out := make([]string, 0, len(v))
		for _, item := range v {
			str, err := toString(item)
			if err != nil {
				return nil, err
			}
			if trimmed := strings.TrimSpace(str); trimmed != "" {
				out = append(out, trimmed)
			}
		}
		return out, nil
	default:
		return nil, fmt.Errorf("unexpected type %T", value)
	}
}

func splitLabels(input string) []string {
	trimmed := strings.TrimSpace(input)
	if trimmed == "" {
		return nil
	}
	raw := strings.Split(trimmed, ",")
	labels := make([]string, 0, len(raw))
	for _, item := range raw {
		if candidate := strings.TrimSpace(item); candidate != "" {
			labels = append(labels, candidate)
		}
	}
	return labels
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

// Ensure IssueExecutor satisfies the ComponentReactionHandler contract
var _ interface {
	Supports(*componentdomain.Component) bool
	Execute(context.Context, areadomain.Area, areadomain.Link) (outbound.ReactionResult, error)
} = (*IssueExecutor)(nil)

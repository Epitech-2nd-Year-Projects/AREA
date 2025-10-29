package notion

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
	notionProviderName        = "notion"
	createPageComponentName   = "notion_create_page"
	notionCreatePageEndpoint  = "https://api.notion.com/v1/pages"
	notionVersionHeader       = "2022-06-28"
	notionDefaultTitlePropKey = "title"
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

// CreatePageExecutor delivers Notion reactions that create new pages
type CreatePageExecutor struct {
	identities identityport.Repository
	providers  ProviderResolver
	http       HTTPClient
	clock      Clock
	logger     *zap.Logger
}

// NewCreatePageExecutor constructs a CreatePageExecutor from its dependencies
func NewCreatePageExecutor(identities identityport.Repository, providers ProviderResolver, client HTTPClient, clock Clock, logger *zap.Logger) *CreatePageExecutor {
	if client == nil {
		client = http.DefaultClient
	}
	if clock == nil {
		clock = systemClock{}
	}
	if logger == nil {
		logger = zap.NewNop()
	}
	return &CreatePageExecutor{
		identities: identities,
		providers:  providers,
		http:       client,
		clock:      clock,
		logger:     logger,
	}
}

// Supports reports whether the executor can handle the provided component
func (e *CreatePageExecutor) Supports(component *componentdomain.Component) bool {
	if component == nil || component.Provider.Name == "" {
		return false
	}
	return strings.EqualFold(component.Name, createPageComponentName) &&
		strings.EqualFold(component.Provider.Name, notionProviderName)
}

// Execute creates a Notion page using the linked identity
func (e *CreatePageExecutor) Execute(ctx context.Context, area areadomain.Area, link areadomain.Link) (outbound.ReactionResult, error) {
	if !e.Supports(link.Config.Component) {
		return outbound.ReactionResult{}, fmt.Errorf("notion.CreatePageExecutor: unsupported component")
	}
	if e.identities == nil || e.providers == nil {
		return outbound.ReactionResult{}, fmt.Errorf("notion.CreatePageExecutor: resolver not configured")
	}

	cfg, err := parsePageConfig(link.Config.Params)
	if err != nil {
		return outbound.ReactionResult{}, fmt.Errorf("notion.CreatePageExecutor: %w", err)
	}

	identity, err := e.identities.FindByID(ctx, cfg.identityID)
	if err != nil {
		return outbound.ReactionResult{}, fmt.Errorf("notion.CreatePageExecutor: identity lookup: %w", err)
	}
	if identity.UserID != area.UserID {
		return outbound.ReactionResult{}, fmt.Errorf("notion.CreatePageExecutor: identity not owned by user")
	}

	identity, accessToken, err := e.ensureAccessToken(ctx, identity, false)
	if err != nil {
		return outbound.ReactionResult{}, err
	}

	result, unauthorized, err := e.createPage(ctx, accessToken, cfg)
	if err != nil && unauthorized {
		identity, accessToken, err = e.ensureAccessToken(ctx, identity, true)
		if err != nil {
			return outbound.ReactionResult{}, err
		}
		result, unauthorized, err = e.createPage(ctx, accessToken, cfg)
	}
	if err != nil {
		return result, err
	}
	if unauthorized {
		return result, fmt.Errorf("notion.CreatePageExecutor: unauthorized after refresh")
	}

	e.logger.Info("notion page created",
		zap.String("area_id", area.ID.String()),
		zap.String("identity_id", identity.ID.String()),
		zap.String("database_id", cfg.databaseID),
	)
	return result, nil
}

func (e *CreatePageExecutor) createPage(ctx context.Context, accessToken string, cfg pageConfig) (outbound.ReactionResult, bool, error) {
	properties := map[string]any{}
	titlePropName := firstNonEmpty(cfg.titleProperty, notionDefaultTitlePropKey, "Name")
	properties[titlePropName] = map[string]any{
		"title": []map[string]any{
			{
				"text": map[string]any{
					"content": cfg.title,
				},
			},
		},
	}

	payload := map[string]any{
		"parent": map[string]any{
			"database_id": cfg.databaseID,
		},
		"properties": properties,
	}

	if cfg.content != "" {
		payload["children"] = []map[string]any{
			{
				"object": "block",
				"type":   "paragraph",
				"paragraph": map[string]any{
					"rich_text": []map[string]any{
						{
							"type": "text",
							"text": map[string]any{
								"content": cfg.content,
							},
						},
					},
				},
			},
		}
	}

	bodyBytes, err := json.Marshal(payload)
	if err != nil {
		return outbound.ReactionResult{}, false, fmt.Errorf("notion.CreatePageExecutor: marshal payload: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, notionCreatePageEndpoint, bytes.NewReader(bodyBytes))
	if err != nil {
		return outbound.ReactionResult{}, false, fmt.Errorf("notion.CreatePageExecutor: build request: %w", err)
	}
	req.Header.Set("Authorization", "Bearer "+accessToken)
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "application/json")
	req.Header.Set("User-Agent", "AREA-Server")
	req.Header.Set("Notion-Version", notionVersionHeader)

	start := e.now()
	resp, err := e.http.Do(req)
	if err != nil {
		return outbound.ReactionResult{}, false, fmt.Errorf("notion.CreatePageExecutor: request failed: %w", err)
	}
	defer resp.Body.Close()

	respBody, _ := io.ReadAll(resp.Body)
	duration := e.now().Sub(start)

	requestHeaders := copyHeaders(req.Header)
	responseHeaders := copyHeaders(resp.Header)

	result := outbound.ReactionResult{
		Endpoint: notionCreatePageEndpoint,
		Request: map[string]any{
			"method":  http.MethodPost,
			"url":     notionCreatePageEndpoint,
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
		if resp.StatusCode == http.StatusUnauthorized || resp.StatusCode == http.StatusForbidden {
			return result, true, fmt.Errorf("notion.CreatePageExecutor: received status %d", resp.StatusCode)
		}
		return result, false, fmt.Errorf("notion.CreatePageExecutor: received status %d", resp.StatusCode)
	}

	return result, false, nil
}

func (e *CreatePageExecutor) ensureAccessToken(ctx context.Context, identity identitydomain.Identity, force bool) (identitydomain.Identity, string, error) {
	now := e.now()
	if identity.AccessToken != "" && !force && !identity.TokenExpired(now) {
		return identity, identity.AccessToken, nil
	}

	provider, ok := e.providers.Provider(notionProviderName)
	if !ok {
		return identity, "", fmt.Errorf("notion.CreatePageExecutor: provider %s not configured", notionProviderName)
	}

	exchange, err := provider.Refresh(ctx, identity)
	if err != nil {
		return identity, "", fmt.Errorf("notion.CreatePageExecutor: refresh token: %w", err)
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
		return identity, "", fmt.Errorf("notion.CreatePageExecutor: update identity: %w", err)
	}

	return updated, updated.AccessToken, nil
}

func (e *CreatePageExecutor) now() time.Time {
	if e.clock == nil {
		return time.Now().UTC()
	}
	return e.clock.Now().UTC()
}

type pageConfig struct {
	identityID    uuid.UUID
	databaseID    string
	title         string
	content       string
	titleProperty string
}

func parsePageConfig(params map[string]any) (pageConfig, error) {
	var cfg pageConfig
	if params == nil {
		return cfg, fmt.Errorf("parse page config: params missing")
	}

	rawIdentity, ok := params["identityId"]
	if !ok {
		return cfg, fmt.Errorf("parse page config: identityId missing")
	}
	identityStr, err := toString(rawIdentity)
	if err != nil {
		return cfg, fmt.Errorf("parse page config: identityId invalid: %w", err)
	}
	identityID, err := uuid.Parse(identityStr)
	if err != nil {
		return cfg, fmt.Errorf("parse page config: parse identityId: %w", err)
	}
	cfg.identityID = identityID

	databaseID, err := requiredString(params, "databaseId")
	if err != nil {
		return cfg, err
	}
	cfg.databaseID = databaseID

	title, err := requiredString(params, "title")
	if err != nil {
		return cfg, err
	}
	cfg.title = title

	content, err := optionalString(params, "content")
	if err != nil {
		return cfg, fmt.Errorf("parse page config: content invalid: %w", err)
	}
	cfg.content = content
	titleProp, err := optionalString(params, "titleProperty")
	if err != nil {
		return cfg, fmt.Errorf("parse page config: titleProperty invalid: %w", err)
	}
	cfg.titleProperty = titleProp

	return cfg, nil
}

func requiredString(params map[string]any, key string) (string, error) {
	value, ok := params[key]
	if !ok {
		return "", fmt.Errorf("parse page config: %s missing", key)
	}
	str, err := toString(value)
	if err != nil {
		return "", fmt.Errorf("parse page config: %s invalid: %w", key, err)
	}
	trimmed := strings.TrimSpace(str)
	if trimmed == "" {
		return "", fmt.Errorf("parse page config: %s empty", key)
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

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if trimmed := strings.TrimSpace(value); trimmed != "" {
			return trimmed
		}
	}
	return ""
}

// Ensure CreatePageExecutor satisfies the ComponentReactionHandler contract
var _ interface {
	Supports(*componentdomain.Component) bool
	Execute(context.Context, areadomain.Area, areadomain.Link) (outbound.ReactionResult, error)
} = (*CreatePageExecutor)(nil)

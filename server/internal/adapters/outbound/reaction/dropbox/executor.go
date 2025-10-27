package dropbox

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
	dropboxProviderName         = "dropbox"
	createFolderComponentName   = "dropbox_create_folder"
	dropboxCreateFolderEndpoint = "https://api.dropboxapi.com/2/files/create_folder_v2"
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

// FolderExecutor delivers Dropbox reactions that create folders
type FolderExecutor struct {
	identities identityport.Repository
	providers  ProviderResolver
	http       HTTPClient
	clock      Clock
	logger     *zap.Logger
}

// NewFolderExecutor constructs a FolderExecutor from its dependencies
func NewFolderExecutor(identities identityport.Repository, providers ProviderResolver, client HTTPClient, clock Clock, logger *zap.Logger) *FolderExecutor {
	if client == nil {
		client = http.DefaultClient
	}
	if clock == nil {
		clock = systemClock{}
	}
	if logger == nil {
		logger = zap.NewNop()
	}
	return &FolderExecutor{
		identities: identities,
		providers:  providers,
		http:       client,
		clock:      clock,
		logger:     logger,
	}
}

// Supports reports whether the executor can handle the provided component
func (e *FolderExecutor) Supports(component *componentdomain.Component) bool {
	if component == nil || component.Provider.Name == "" {
		return false
	}
	return strings.EqualFold(component.Name, createFolderComponentName) &&
		strings.EqualFold(component.Provider.Name, dropboxProviderName)
}

// Execute creates a Dropbox folder using the linked identity
func (e *FolderExecutor) Execute(ctx context.Context, area areadomain.Area, link areadomain.Link) (outbound.ReactionResult, error) {
	if !e.Supports(link.Config.Component) {
		return outbound.ReactionResult{}, fmt.Errorf("dropbox.FolderExecutor: unsupported component")
	}
	if e.identities == nil || e.providers == nil {
		return outbound.ReactionResult{}, fmt.Errorf("dropbox.FolderExecutor: resolver not configured")
	}

	cfg, err := parseFolderConfig(link.Config.Params)
	if err != nil {
		return outbound.ReactionResult{}, fmt.Errorf("dropbox.FolderExecutor: %w", err)
	}

	identity, err := e.identities.FindByID(ctx, cfg.identityID)
	if err != nil {
		return outbound.ReactionResult{}, fmt.Errorf("dropbox.FolderExecutor: identity lookup: %w", err)
	}
	if identity.UserID != area.UserID {
		return outbound.ReactionResult{}, fmt.Errorf("dropbox.FolderExecutor: identity not owned by user")
	}

	identity, accessToken, err := e.ensureAccessToken(ctx, identity, false)
	if err != nil {
		return outbound.ReactionResult{}, err
	}

	result, unauthorized, err := e.createFolder(ctx, accessToken, cfg)
	if err != nil && unauthorized {
		identity, accessToken, err = e.ensureAccessToken(ctx, identity, true)
		if err != nil {
			return outbound.ReactionResult{}, err
		}
		result, unauthorized, err = e.createFolder(ctx, accessToken, cfg)
	}
	if err != nil {
		return result, err
	}
	if unauthorized {
		return result, fmt.Errorf("dropbox.FolderExecutor: unauthorized after refresh")
	}

	e.logger.Info("dropbox folder created",
		zap.String("area_id", area.ID.String()),
		zap.String("identity_id", identity.ID.String()),
		zap.String("path", cfg.path),
	)
	return result, nil
}

func (e *FolderExecutor) createFolder(ctx context.Context, accessToken string, cfg folderConfig) (outbound.ReactionResult, bool, error) {
	payload := map[string]any{
		"path":       cfg.path,
		"autorename": cfg.autorename,
	}

	bodyBytes, err := json.Marshal(payload)
	if err != nil {
		return outbound.ReactionResult{}, false, fmt.Errorf("dropbox.FolderExecutor: marshal payload: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, dropboxCreateFolderEndpoint, bytes.NewReader(bodyBytes))
	if err != nil {
		return outbound.ReactionResult{}, false, fmt.Errorf("dropbox.FolderExecutor: build request: %w", err)
	}
	req.Header.Set("Authorization", "Bearer "+accessToken)
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "application/json")
	req.Header.Set("User-Agent", "AREA-Server")

	start := time.Now()
	resp, err := e.http.Do(req)
	if err != nil {
		return outbound.ReactionResult{}, false, fmt.Errorf("dropbox.FolderExecutor: request failed: %w", err)
	}
	defer resp.Body.Close()

	respBody, _ := io.ReadAll(resp.Body)
	duration := time.Since(start)

	requestHeaders := copyHeaders(req.Header)
	responseHeaders := copyHeaders(resp.Header)

	result := outbound.ReactionResult{
		Endpoint: dropboxCreateFolderEndpoint,
		Request: map[string]any{
			"method":  http.MethodPost,
			"url":     dropboxCreateFolderEndpoint,
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
			return result, true, fmt.Errorf("dropbox.FolderExecutor: received status %d", resp.StatusCode)
		}
		return result, false, fmt.Errorf("dropbox.FolderExecutor: received status %d", resp.StatusCode)
	}

	return result, false, nil
}

func (e *FolderExecutor) ensureAccessToken(ctx context.Context, identity identitydomain.Identity, force bool) (identitydomain.Identity, string, error) {
	now := e.now()
	if identity.AccessToken != "" && !force && !identity.TokenExpired(now) {
		return identity, identity.AccessToken, nil
	}

	provider, ok := e.providers.Provider(dropboxProviderName)
	if !ok {
		return identity, "", fmt.Errorf("dropbox.FolderExecutor: provider %s not configured", dropboxProviderName)
	}

	exchange, err := provider.Refresh(ctx, identity)
	if err != nil {
		return identity, "", fmt.Errorf("dropbox.FolderExecutor: refresh token: %w", err)
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
		return identity, "", fmt.Errorf("dropbox.FolderExecutor: update identity: %w", err)
	}

	return updated, updated.AccessToken, nil
}

func (e *FolderExecutor) now() time.Time {
	if e.clock == nil {
		return time.Now().UTC()
	}
	return e.clock.Now().UTC()
}

type folderConfig struct {
	identityID uuid.UUID
	path       string
	autorename bool
}

func parseFolderConfig(params map[string]any) (folderConfig, error) {
	var cfg folderConfig
	if params == nil {
		return cfg, fmt.Errorf("parse folder config: params missing")
	}

	rawIdentity, ok := params["identityId"]
	if !ok {
		return cfg, fmt.Errorf("parse folder config: identityId missing")
	}
	identityStr, err := toString(rawIdentity)
	if err != nil {
		return cfg, fmt.Errorf("parse folder config: identityId invalid: %w", err)
	}
	identityID, err := uuid.Parse(identityStr)
	if err != nil {
		return cfg, fmt.Errorf("parse folder config: parse identityId: %w", err)
	}
	cfg.identityID = identityID

	path, err := requiredString(params, "path")
	if err != nil {
		return cfg, err
	}
	if !strings.HasPrefix(path, "/") {
		path = "/" + path
	}
	cfg.path = path

	autorename, err := optionalBool(params, "autorename", false)
	if err != nil {
		return cfg, fmt.Errorf("parse folder config: autorename invalid: %w", err)
	}
	cfg.autorename = autorename
	return cfg, nil
}

func requiredString(params map[string]any, key string) (string, error) {
	value, ok := params[key]
	if !ok {
		return "", fmt.Errorf("parse folder config: %s missing", key)
	}
	str, err := toString(value)
	if err != nil {
		return "", fmt.Errorf("parse folder config: %s invalid: %w", key, err)
	}
	if trimmed := strings.TrimSpace(str); trimmed != "" {
		return trimmed, nil
	}
	return "", fmt.Errorf("parse folder config: %s empty", key)
}

func optionalBool(params map[string]any, key string, defaultValue bool) (bool, error) {
	value, ok := params[key]
	if !ok {
		return defaultValue, nil
	}
	switch v := value.(type) {
	case bool:
		return v, nil
	case string:
		trimmed := strings.TrimSpace(v)
		if trimmed == "" {
			return defaultValue, nil
		}
		lower := strings.ToLower(trimmed)
		if lower == "true" || lower == "1" || lower == "yes" {
			return true, nil
		}
		if lower == "false" || lower == "0" || lower == "no" {
			return false, nil
		}
		return false, fmt.Errorf("unexpected string %q", v)
	default:
		return false, fmt.Errorf("unexpected type %T", value)
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

// Ensure FolderExecutor satisfies the ComponentReactionHandler contract
var _ interface {
	Supports(*componentdomain.Component) bool
	Execute(context.Context, areadomain.Area, areadomain.Link) (outbound.ReactionResult, error)
} = (*FolderExecutor)(nil)

package gdrive

import (
	"bytes"
	"context"
	"encoding/json"
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
	gdriveComponentName = "gdrive_move_file"
	gdriveProviderName  = "google"
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

// Executor delivers Google Drive reactions on behalf of the user through OAuth tokens
type Executor struct {
	identities identityport.Repository
	providers  ProviderResolver
	http       HTTPClient
	clock      Clock
	logger     *zap.Logger
}

// NewExecutor constructs a Google Drive executor from its dependencies
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
	if strings.EqualFold(component.Name, gdriveComponentName) && strings.EqualFold(component.Provider.Name, gdriveProviderName) {
		return true
	}
	return false
}

// Execute moves a Google Drive file to a specified folder
func (e *Executor) Execute(ctx context.Context, area areadomain.Area, link areadomain.Link) (outbound.ReactionResult, error) {
	if !e.Supports(link.Config.Component) {
		return outbound.ReactionResult{}, fmt.Errorf("gdrive.Executor: unsupported component")
	}
	if e.identities == nil || e.providers == nil {
		return outbound.ReactionResult{}, fmt.Errorf("gdrive.Executor: resolver not configured")
	}

	cfg, err := parseMoveFileConfig(link.Config.Params)
	if err != nil {
		return outbound.ReactionResult{}, fmt.Errorf("gdrive.Executor: %w", err)
	}

	identity, err := e.identities.FindByID(ctx, cfg.identityID)
	if err != nil {
		return outbound.ReactionResult{}, fmt.Errorf("gdrive.Executor: identity lookup: %w", err)
	}
	if identity.UserID != area.UserID {
		return outbound.ReactionResult{}, fmt.Errorf("gdrive.Executor: identity not owned by user")
	}

	identity, accessToken, err := e.ensureAccessToken(ctx, identity, false)
	if err != nil {
		return outbound.ReactionResult{}, err
	}

	endpoint := fmt.Sprintf("https://www.googleapis.com/drive/v3/files/%s", cfg.fileID)
	
	// Fetch current file to get its parents
	currentFile, result, unauthorized, err := e.getFile(ctx, endpoint, accessToken, cfg.fileID)
	if err != nil {
		return result, err
	}
	if unauthorized {
		return result, fmt.Errorf("gdrive.Executor: unauthorized during fetch")
	}
	
	// Extract current parent IDs
	var currentParents []string
	if parents, ok := currentFile["parents"].([]any); ok {
		for _, p := range parents {
			if parentID, ok := p.(string); ok {
				currentParents = append(currentParents, parentID)
			}
		}
	}

	requestInfo := map[string]any{
		"fileId":                  cfg.fileID,
		"destinationFolderId":     cfg.destinationFolderId,
		"previousParents":         currentParents,
	}

	result, unauthorized, err = e.moveFileWithParents(ctx, endpoint, accessToken, cfg.destinationFolderId, currentParents, requestInfo)
	if err != nil && unauthorized {
		identity, accessToken, err = e.ensureAccessToken(ctx, identity, true)
		if err != nil {
			return outbound.ReactionResult{}, err
		}
		result, unauthorized, err = e.moveFileWithParents(ctx, endpoint, accessToken, cfg.destinationFolderId, currentParents, requestInfo)
	}
	if err != nil {
		return result, err
	}
	if unauthorized {
		return result, fmt.Errorf("gdrive.Executor: unauthorized after refresh")
	}

	e.logger.Info("gdrive reaction delivered",
		zap.String("area_id", area.ID.String()),
		zap.String("identity_id", identity.ID.String()),
		zap.String("fileId", cfg.fileID),
	)
	return result, nil
}

func (e *Executor) ensureAccessToken(ctx context.Context, identity identitydomain.Identity, force bool) (identitydomain.Identity, string, error) {
	now := e.now()
	if identity.AccessToken != "" && !force && !identity.TokenExpired(now) {
		return identity, identity.AccessToken, nil
	}

	provider, ok := e.providers.Provider(gdriveProviderName)
	if !ok {
		return identity, "", fmt.Errorf("gdrive.Executor: provider %s not configured", gdriveProviderName)
	}

	exchange, err := provider.Refresh(ctx, identity)
	if err != nil {
		return identity, "", fmt.Errorf("gdrive.Executor: refresh token: %w", err)
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
		return identity, "", fmt.Errorf("gdrive.Executor: update identity: %w", err)
	}
	return updated, updated.AccessToken, nil
}

func (e *Executor) getFile(ctx context.Context, endpoint string, accessToken string, fileID string) (map[string]any, outbound.ReactionResult, bool, error) {
	// Query to get the parents field
	getEndpoint := fmt.Sprintf("%s?fields=parents", endpoint)
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, getEndpoint, nil)
	if err != nil {
		return nil, outbound.ReactionResult{}, false, fmt.Errorf("gdrive.Executor: build get request: %w", err)
	}
	req.Header.Set("Authorization", "Bearer "+accessToken)

	start := time.Now()
	resp, err := e.http.Do(req)
	if err != nil {
		return nil, outbound.ReactionResult{}, false, fmt.Errorf("gdrive.Executor: get request failed: %w", err)
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	duration := time.Since(start)

	responseHeaders := map[string][]string{}
	for key, values := range resp.Header {
		responseHeaders[key] = append([]string(nil), values...)
	}

	result := outbound.ReactionResult{
		Endpoint: getEndpoint,
		Request:  map[string]any{"fileId": fileID},
		Response: map[string]any{
			"body":    strings.TrimSpace(string(body)),
			"headers": responseHeaders,
		},
		StatusCode: &resp.StatusCode,
		Duration:   duration,
	}

	if resp.StatusCode == http.StatusUnauthorized {
		return nil, result, true, fmt.Errorf("gdrive.Executor: unauthorized: %s", strings.TrimSpace(string(body)))
	}
	if resp.StatusCode >= 400 {
		return nil, result, false, fmt.Errorf("gdrive.Executor: api error %d: %s", resp.StatusCode, strings.TrimSpace(string(body)))
	}

	var fileData map[string]any
	if err := json.Unmarshal(body, &fileData); err != nil {
		return nil, result, false, fmt.Errorf("gdrive.Executor: decode file response: %w", err)
	}

	return fileData, result, false, nil
}

func (e *Executor) moveFileWithParents(ctx context.Context, endpoint string, accessToken string, destinationFolderId string, currentParents []string, request map[string]any) (outbound.ReactionResult, bool, error) {
	// Build query parameters for addParents and removeParents
	query := "?"
	query += fmt.Sprintf("addParents=%s", url.QueryEscape(destinationFolderId))
	
	// Remove all current parents
	for _, parent := range currentParents {
		query += fmt.Sprintf("&removeParents=%s", url.QueryEscape(parent))
	}

	// Use an empty body for move operation (Google Drive API doesn't require a body for parent changes)
	payload := []byte("{}")

	moveEndpoint := endpoint + query
	req, err := http.NewRequestWithContext(ctx, http.MethodPatch, moveEndpoint, bytes.NewReader(payload))
	if err != nil {
		return outbound.ReactionResult{}, false, fmt.Errorf("gdrive.Executor: build move request: %w", err)
	}
	req.Header.Set("Authorization", "Bearer "+accessToken)
	req.Header.Set("Content-Type", "application/json")

	start := time.Now()
	resp, err := e.http.Do(req)
	if err != nil {
		return outbound.ReactionResult{}, false, fmt.Errorf("gdrive.Executor: move request failed: %w", err)
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
		return result, true, fmt.Errorf("gdrive.Executor: unauthorized: %s", strings.TrimSpace(string(body)))
	case resp.StatusCode >= 400:
		return result, false, fmt.Errorf("gdrive.Executor: api error %d: %s", resp.StatusCode, strings.TrimSpace(string(body)))
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

type moveFileConfig struct {
	identityID           uuid.UUID
	fileID               string
	destinationFolderId  string
}

func parseMoveFileConfig(params map[string]any) (moveFileConfig, error) {
	cfg := moveFileConfig{}

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

	// Parse file ID
	fileIDRaw, ok := params["fileId"]
	if !ok {
		return cfg, fmt.Errorf("fileId missing")
	}
	fileID, err := toString(fileIDRaw)
	if err != nil {
		return cfg, fmt.Errorf("fileId invalid")
	}
	cfg.fileID = strings.TrimSpace(fileID)
	if cfg.fileID == "" {
		return cfg, fmt.Errorf("fileId cannot be empty")
	}

	// Parse destination folder ID
	destFolderRaw, ok := params["destinationFolderId"]
	if !ok {
		return cfg, fmt.Errorf("destinationFolderId missing")
	}
	destFolder, err := toString(destFolderRaw)
	if err != nil {
		return cfg, fmt.Errorf("destinationFolderId invalid")
	}
	cfg.destinationFolderId = strings.TrimSpace(destFolder)
	if cfg.destinationFolderId == "" {
		return cfg, fmt.Errorf("destinationFolderId cannot be empty")
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

type systemClock struct{}

func (systemClock) Now() time.Time { return time.Now().UTC() }

// Ensure Executor satisfies the ComponentReactionHandler contract
var _ interface {
	Supports(*componentdomain.Component) bool
	Execute(context.Context, areadomain.Area, areadomain.Link) (outbound.ReactionResult, error)
} = (*Executor)(nil)
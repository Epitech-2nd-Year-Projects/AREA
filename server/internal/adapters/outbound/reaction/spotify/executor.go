package spotify

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
	spotifyProviderName         = "spotify"
	addTrackComponentName       = "spotify_add_track_to_playlist"
	spotifyAddTrackEndpointTmpl = "https://api.spotify.com/v1/playlists/%s/tracks"
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

// AddTrackExecutor delivers Spotify reactions that append tracks to playlists
type AddTrackExecutor struct {
	identities identityport.Repository
	providers  ProviderResolver
	http       HTTPClient
	clock      Clock
	logger     *zap.Logger
}

// NewAddTrackExecutor constructs an AddTrackExecutor from its dependencies
func NewAddTrackExecutor(identities identityport.Repository, providers ProviderResolver, client HTTPClient, clock Clock, logger *zap.Logger) *AddTrackExecutor {
	if client == nil {
		client = http.DefaultClient
	}
	if clock == nil {
		clock = systemClock{}
	}
	if logger == nil {
		logger = zap.NewNop()
	}
	return &AddTrackExecutor{
		identities: identities,
		providers:  providers,
		http:       client,
		clock:      clock,
		logger:     logger,
	}
}

// Supports reports whether the executor can handle the provided component
func (e *AddTrackExecutor) Supports(component *componentdomain.Component) bool {
	if component == nil || component.Provider.Name == "" {
		return false
	}
	return strings.EqualFold(component.Name, addTrackComponentName) &&
		strings.EqualFold(component.Provider.Name, spotifyProviderName)
}

// Execute appends a track to the target Spotify playlist using the linked identity
func (e *AddTrackExecutor) Execute(ctx context.Context, area areadomain.Area, link areadomain.Link) (outbound.ReactionResult, error) {
	if !e.Supports(link.Config.Component) {
		return outbound.ReactionResult{}, fmt.Errorf("spotify.AddTrackExecutor: unsupported component")
	}
	if e.identities == nil || e.providers == nil {
		return outbound.ReactionResult{}, fmt.Errorf("spotify.AddTrackExecutor: resolver not configured")
	}

	cfg, err := parseAddTrackConfig(link.Config.Params)
	if err != nil {
		return outbound.ReactionResult{}, fmt.Errorf("spotify.AddTrackExecutor: %w", err)
	}

	identity, err := e.identities.FindByID(ctx, cfg.identityID)
	if err != nil {
		return outbound.ReactionResult{}, fmt.Errorf("spotify.AddTrackExecutor: identity lookup: %w", err)
	}
	if identity.UserID != area.UserID {
		return outbound.ReactionResult{}, fmt.Errorf("spotify.AddTrackExecutor: identity not owned by user")
	}

	identity, accessToken, err := e.ensureAccessToken(ctx, identity, false)
	if err != nil {
		return outbound.ReactionResult{}, err
	}

	result, unauthorized, err := e.addTrack(ctx, accessToken, cfg)
	if err != nil && unauthorized {
		identity, accessToken, err = e.ensureAccessToken(ctx, identity, true)
		if err != nil {
			return outbound.ReactionResult{}, err
		}
		result, unauthorized, err = e.addTrack(ctx, accessToken, cfg)
	}
	if err != nil {
		return result, err
	}
	if unauthorized {
		return result, fmt.Errorf("spotify.AddTrackExecutor: unauthorized after refresh")
	}

	e.logger.Info("spotify track added to playlist",
		zap.String("area_id", area.ID.String()),
		zap.String("identity_id", identity.ID.String()),
		zap.String("playlist_id", cfg.playlistID),
	)
	return result, nil
}

func (e *AddTrackExecutor) addTrack(ctx context.Context, accessToken string, cfg addTrackConfig) (outbound.ReactionResult, bool, error) {
	endpoint := fmt.Sprintf(spotifyAddTrackEndpointTmpl, url.PathEscape(cfg.playlistID))

	payload := map[string]any{
		"uris": []string{cfg.trackURI},
	}
	if cfg.position != nil {
		payload["position"] = *cfg.position
	}

	bodyBytes, err := json.Marshal(payload)
	if err != nil {
		return outbound.ReactionResult{}, false, fmt.Errorf("spotify.AddTrackExecutor: marshal payload: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint, bytes.NewReader(bodyBytes))
	if err != nil {
		return outbound.ReactionResult{}, false, fmt.Errorf("spotify.AddTrackExecutor: build request: %w", err)
	}
	req.Header.Set("Authorization", "Bearer "+accessToken)
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "application/json")
	req.Header.Set("User-Agent", "AREA-Server")

	start := e.now()
	resp, err := e.http.Do(req)
	if err != nil {
		return outbound.ReactionResult{}, false, fmt.Errorf("spotify.AddTrackExecutor: request failed: %w", err)
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

	if resp.StatusCode >= 400 {
		if resp.StatusCode == http.StatusUnauthorized || resp.StatusCode == http.StatusForbidden {
			return result, true, fmt.Errorf("spotify.AddTrackExecutor: received status %d", resp.StatusCode)
		}
		return result, false, fmt.Errorf("spotify.AddTrackExecutor: received status %d", resp.StatusCode)
	}

	return result, false, nil
}

func (e *AddTrackExecutor) ensureAccessToken(ctx context.Context, identity identitydomain.Identity, force bool) (identitydomain.Identity, string, error) {
	now := e.now()
	if identity.AccessToken != "" && !force && !identity.TokenExpired(now) {
		return identity, identity.AccessToken, nil
	}

	provider, ok := e.providers.Provider(spotifyProviderName)
	if !ok {
		return identity, "", fmt.Errorf("spotify.AddTrackExecutor: provider %s not configured", spotifyProviderName)
	}

	exchange, err := provider.Refresh(ctx, identity)
	if err != nil {
		return identity, "", fmt.Errorf("spotify.AddTrackExecutor: refresh token: %w", err)
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
		return identity, "", fmt.Errorf("spotify.AddTrackExecutor: update identity: %w", err)
	}

	return updated, updated.AccessToken, nil
}

func (e *AddTrackExecutor) now() time.Time {
	if e.clock == nil {
		return time.Now().UTC()
	}
	return e.clock.Now().UTC()
}

type addTrackConfig struct {
	identityID uuid.UUID
	playlistID string
	trackURI   string
	position   *int
}

func parseAddTrackConfig(params map[string]any) (addTrackConfig, error) {
	var cfg addTrackConfig
	if params == nil {
		return cfg, fmt.Errorf("parse add track config: params missing")
	}

	rawIdentity, ok := params["identityId"]
	if !ok {
		return cfg, fmt.Errorf("parse add track config: identityId missing")
	}
	identityStr, err := toString(rawIdentity)
	if err != nil {
		return cfg, fmt.Errorf("parse add track config: identityId invalid: %w", err)
	}
	identityID, err := uuid.Parse(identityStr)
	if err != nil {
		return cfg, fmt.Errorf("parse add track config: parse identityId: %w", err)
	}
	cfg.identityID = identityID

	playlistValue, err := requiredString(params, "playlistId")
	if err != nil {
		return cfg, err
	}
	playlistID, err := normalizePlaylistID(playlistValue)
	if err != nil {
		return cfg, fmt.Errorf("parse add track config: playlistId invalid: %w", err)
	}
	cfg.playlistID = playlistID

	trackValue, err := requiredString(params, "trackUri")
	if err != nil {
		return cfg, err
	}
	trackURI, err := normalizeTrackURI(trackValue)
	if err != nil {
		return cfg, fmt.Errorf("parse add track config: trackUri invalid: %w", err)
	}
	cfg.trackURI = trackURI

	if positionValue, ok := params["position"]; ok {
		position, err := toInt(positionValue)
		if err != nil {
			return cfg, fmt.Errorf("parse add track config: position invalid: %w", err)
		}
		if position < 0 {
			return cfg, fmt.Errorf("parse add track config: position must be non-negative")
		}
		cfg.position = &position
	}

	return cfg, nil
}

func normalizePlaylistID(value string) (string, error) {
	trimmed := strings.TrimSpace(value)
	if trimmed == "" {
		return "", fmt.Errorf("playlist reference empty")
	}
	lower := strings.ToLower(trimmed)
	if strings.HasPrefix(lower, "spotify:playlist:") {
		id := strings.TrimSpace(trimmed[len("spotify:playlist:"):])
		if id == "" {
			return "", fmt.Errorf("playlist id missing")
		}
		return id, nil
	}
	if strings.HasPrefix(lower, "http://") || strings.HasPrefix(lower, "https://") {
		parsed, err := url.Parse(trimmed)
		if err == nil {
			segments := strings.Split(strings.Trim(parsed.Path, "/"), "/")
			for idx := 0; idx < len(segments); idx++ {
				if strings.EqualFold(segments[idx], "playlist") && idx+1 < len(segments) {
					id := segments[idx+1]
					if q := strings.Index(id, "?"); q >= 0 {
						id = id[:q]
					}
					id = strings.TrimSpace(id)
					if id != "" {
						return id, nil
					}
				}
			}
		}
	}
	if strings.HasPrefix(lower, "spotify:") {
		parts := strings.Split(trimmed, ":")
		if len(parts) >= 3 && strings.TrimSpace(parts[len(parts)-1]) != "" {
			return strings.TrimSpace(parts[len(parts)-1]), nil
		}
	}
	return trimmed, nil
}

func normalizeTrackURI(value string) (string, error) {
	trimmed := strings.TrimSpace(value)
	if trimmed == "" {
		return "", fmt.Errorf("track reference empty")
	}
	lower := strings.ToLower(trimmed)
	if strings.HasPrefix(lower, "spotify:track:") {
		return trimmed, nil
	}
	if strings.HasPrefix(lower, "spotify:") {
		parts := strings.Split(trimmed, ":")
		if len(parts) >= 3 && strings.EqualFold(parts[1], "track") && strings.TrimSpace(parts[2]) != "" {
			return "spotify:track:" + strings.TrimSpace(parts[2]), nil
		}
	}
	if strings.HasPrefix(lower, "http://") || strings.HasPrefix(lower, "https://") {
		parsed, err := url.Parse(trimmed)
		if err == nil {
			segments := strings.Split(strings.Trim(parsed.Path, "/"), "/")
			for idx := 0; idx < len(segments); idx++ {
				if strings.EqualFold(segments[idx], "track") && idx+1 < len(segments) {
					id := segments[idx+1]
					if q := strings.Index(id, "?"); q >= 0 {
						id = id[:q]
					}
					id = strings.TrimSpace(id)
					if id != "" {
						return "spotify:track:" + id, nil
					}
				}
			}
		}
	}
	if !strings.Contains(trimmed, ":") && !strings.Contains(trimmed, "/") {
		return "spotify:track:" + trimmed, nil
	}
	return "", fmt.Errorf("unrecognised track reference %q", value)
}

func toInt(value any) (int, error) {
	switch v := value.(type) {
	case int:
		return v, nil
	case int8:
		return int(v), nil
	case int16:
		return int(v), nil
	case int32:
		return int(v), nil
	case int64:
		return int(v), nil
	case float32:
		return int(v), nil
	case float64:
		return int(v), nil
	case json.Number:
		parsed, err := v.Int64()
		if err != nil {
			return 0, err
		}
		return int(parsed), nil
	case string:
		trimmed := strings.TrimSpace(v)
		if trimmed == "" {
			return 0, fmt.Errorf("empty string")
		}
		parsed, err := strconv.Atoi(trimmed)
		if err != nil {
			return 0, err
		}
		return parsed, nil
	default:
		return 0, fmt.Errorf("unexpected type %T", value)
	}
}

func requiredString(params map[string]any, key string) (string, error) {
	value, ok := params[key]
	if !ok {
		return "", fmt.Errorf("parse add track config: %s missing", key)
	}
	str, err := toString(value)
	if err != nil {
		return "", fmt.Errorf("parse add track config: %s invalid: %w", key, err)
	}
	trimmed := strings.TrimSpace(str)
	if trimmed == "" {
		return "", fmt.Errorf("parse add track config: %s empty", key)
	}
	return trimmed, nil
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

// Ensure AddTrackExecutor satisfies the ComponentReactionHandler contract
var _ interface {
	Supports(*componentdomain.Component) bool
	Execute(context.Context, areadomain.Area, areadomain.Link) (outbound.ReactionResult, error)
} = (*AddTrackExecutor)(nil)

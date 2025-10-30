package gmail

import (
	"bytes"
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	mailutils "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/adapters/outbound/reaction/mail"
	areadomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/area"
	componentdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/component"
	identitydomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/identity"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
	identityport "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound/identity"
	"github.com/google/uuid"
	"go.uber.org/zap"
)

const (
	gmailComponentName = "gmail_send_email"
	gmailProviderName  = "google"
	gmailAPIEndpoint   = "https://gmail.googleapis.com/gmail/v1/users/me/messages/send"
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

// Executor delivers Gmail reactions on behalf of the user through OAuth tokens
type Executor struct {
	identities identityport.Repository
	providers  ProviderResolver
	http       HTTPClient
	clock      Clock
	logger     *zap.Logger
}

// NewExecutor constructs a Gmail executor from its dependencies
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
	if strings.EqualFold(component.Name, gmailComponentName) && strings.EqualFold(component.Provider.Name, gmailProviderName) {
		return true
	}
	return false
}

// Execute delivers the Gmail reaction payload for the provided area
func (e *Executor) Execute(ctx context.Context, area areadomain.Area, link areadomain.Link) (outbound.ReactionResult, error) {
	if !e.Supports(link.Config.Component) {
		return outbound.ReactionResult{}, fmt.Errorf("gmail.Executor: unsupported component")
	}
	if e.identities == nil || e.providers == nil {
		return outbound.ReactionResult{}, fmt.Errorf("gmail.Executor: resolver not configured")
	}

	cfg, err := parseMessageConfig(link.Config.Params)
	if err != nil {
		return outbound.ReactionResult{}, fmt.Errorf("gmail.Executor: %w", err)
	}

	identity, err := e.identities.FindByID(ctx, cfg.identityID)
	if err != nil {
		return outbound.ReactionResult{}, fmt.Errorf("gmail.Executor: identity lookup: %w", err)
	}
	if identity.UserID != area.UserID {
		return outbound.ReactionResult{}, fmt.Errorf("gmail.Executor: identity not owned by user")
	}

	identity, accessToken, err := e.ensureAccessToken(ctx, identity, false)
	if err != nil {
		return outbound.ReactionResult{}, err
	}

	payload, err := buildRawMessage(cfg)
	if err != nil {
		return outbound.ReactionResult{}, fmt.Errorf("gmail.Executor: build payload: %w", err)
	}

	requestInfo := map[string]any{
		"to":      append([]string(nil), cfg.to...),
		"cc":      append([]string(nil), cfg.cc...),
		"bcc":     append([]string(nil), cfg.bcc...),
		"subject": cfg.subject,
		"payload": string(payload),
	}

	result, unauthorized, err := e.sendMessage(ctx, accessToken, payload, requestInfo)
	if err != nil && unauthorized {
		identity, accessToken, err = e.ensureAccessToken(ctx, identity, true)
		if err != nil {
			return outbound.ReactionResult{}, err
		}
		result, unauthorized, err = e.sendMessage(ctx, accessToken, payload, requestInfo)
	}
	if err != nil {
		return result, err
	}
	if unauthorized {
		return result, fmt.Errorf("gmail.Executor: unauthorized after refresh")
	}

	e.logger.Info("gmail reaction delivered",
		zap.String("area_id", area.ID.String()),
		zap.String("identity_id", identity.ID.String()),
		zap.Int("recipient_count", len(cfg.to)+len(cfg.cc)+len(cfg.bcc)),
	)
	return result, nil
}

func (e *Executor) ensureAccessToken(ctx context.Context, identity identitydomain.Identity, force bool) (identitydomain.Identity, string, error) {
	now := e.now()
	if identity.AccessToken != "" && !force && !identity.TokenExpired(now) {
		return identity, identity.AccessToken, nil
	}

	provider, ok := e.providers.Provider(gmailProviderName)
	if !ok {
		return identity, "", fmt.Errorf("gmail.Executor: provider %s not configured", gmailProviderName)
	}

	exchange, err := provider.Refresh(ctx, identity)
	if err != nil {
		return identity, "", fmt.Errorf("gmail.Executor: refresh token: %w", err)
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
		return identity, "", fmt.Errorf("gmail.Executor: update identity: %w", err)
	}
	return updated, updated.AccessToken, nil
}

func (e *Executor) sendMessage(ctx context.Context, accessToken string, payload []byte, request map[string]any) (outbound.ReactionResult, bool, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, gmailAPIEndpoint, bytes.NewReader(payload))
	if err != nil {
		return outbound.ReactionResult{}, false, fmt.Errorf("gmail.Executor: build request: %w", err)
	}
	req.Header.Set("Authorization", "Bearer "+accessToken)
	req.Header.Set("Content-Type", "application/json")

	start := time.Now()
	resp, err := e.http.Do(req)
	if err != nil {
		return outbound.ReactionResult{}, false, fmt.Errorf("gmail.Executor: request failed: %w", err)
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	duration := time.Since(start)

	responseHeaders := map[string][]string{}
	for key, values := range resp.Header {
		responseHeaders[key] = append([]string(nil), values...)
	}

	result := outbound.ReactionResult{
		Endpoint: gmailAPIEndpoint,
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
		return result, true, fmt.Errorf("gmail.Executor: unauthorized: %s", strings.TrimSpace(string(body)))
	case resp.StatusCode >= 400:
		return result, false, fmt.Errorf("gmail.Executor: api error %d: %s", resp.StatusCode, strings.TrimSpace(string(body)))
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

func buildRawMessage(cfg messageConfig) ([]byte, error) {
	headers := []string{
		"To: " + strings.Join(cfg.to, ", "),
	}
	if len(cfg.cc) > 0 {
		headers = append(headers, "Cc: "+strings.Join(cfg.cc, ", "))
	}
	if len(cfg.bcc) > 0 {
		headers = append(headers, "Bcc: "+strings.Join(cfg.bcc, ", "))
	}
	headers = append(headers,
		"Subject: "+sanitizeHeader(cfg.subject),
		"MIME-Version: 1.0",
		"Content-Type: text/plain; charset=\"UTF-8\"",
	)

	payload := strings.Join(headers, "\r\n") + "\r\n\r\n" + cfg.body
	encoded := base64.URLEncoding.WithPadding(base64.NoPadding).EncodeToString([]byte(payload))
	return json.Marshal(map[string]string{"raw": encoded})
}

type messageConfig struct {
	identityID uuid.UUID
	to         []string
	cc         []string
	bcc        []string
	subject    string
	body       string
}

func parseMessageConfig(params map[string]any) (messageConfig, error) {
	cfg := messageConfig{}

	identityRaw, ok := params["identityId"]
	if !ok {
		return cfg, fmt.Errorf("identityId missing")
	}
	identityStr, err := mailutils.ToString(identityRaw)
	if err != nil {
		return cfg, fmt.Errorf("identityId invalid")
	}
	identityID, err := uuid.Parse(strings.TrimSpace(identityStr))
	if err != nil {
		return cfg, fmt.Errorf("identityId parse: %w", err)
	}
	cfg.identityID = identityID

	toRaw, ok := params["to"]
	if !ok {
		return cfg, fmt.Errorf("to missing")
	}
	cfg.to, err = mailutils.ParseList(toRaw, false)
	if err != nil {
		return cfg, fmt.Errorf("to invalid: %w", err)
	}

	if ccRaw, ok := params["cc"]; ok {
		cfg.cc, err = mailutils.ParseList(ccRaw, true)
		if err != nil {
			return cfg, fmt.Errorf("cc invalid: %w", err)
		}
	}
	if bccRaw, ok := params["bcc"]; ok {
		cfg.bcc, err = mailutils.ParseList(bccRaw, true)
		if err != nil {
			return cfg, fmt.Errorf("bcc invalid: %w", err)
		}
	}

	subjectRaw, ok := params["subject"]
	if !ok {
		return cfg, fmt.Errorf("subject missing")
	}
	cfg.subject, err = mailutils.ToString(subjectRaw)
	if err != nil {
		return cfg, fmt.Errorf("subject invalid")
	}

	bodyRaw, ok := params["body"]
	if !ok {
		return cfg, fmt.Errorf("body missing")
	}
	cfg.body, err = mailutils.ToString(bodyRaw)
	if err != nil {
		return cfg, fmt.Errorf("body invalid")
	}

	cfg.subject = strings.TrimSpace(cfg.subject)

	return cfg, nil
}

func sanitizeHeader(value string) string {
	replacer := strings.NewReplacer("\r", " ", "\n", " ")
	return strings.TrimSpace(replacer.Replace(value))
}

type systemClock struct{}

func (systemClock) Now() time.Time { return time.Now().UTC() }

// Ensure Executor satisfies the ComponentReactionHandler contract
var _ interface {
	Supports(*componentdomain.Component) bool
	Execute(context.Context, areadomain.Area, areadomain.Link) (outbound.ReactionResult, error)
} = (*Executor)(nil)

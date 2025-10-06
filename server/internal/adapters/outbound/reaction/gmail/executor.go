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

	areadomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/area"
	componentdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/component"
	identitydomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/identity"
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
func (e *Executor) Execute(ctx context.Context, area areadomain.Area, link areadomain.Link) error {
	if !e.Supports(link.Config.Component) {
		return fmt.Errorf("gmail.Executor: unsupported component")
	}
	if e.identities == nil || e.providers == nil {
		return fmt.Errorf("gmail.Executor: resolver not configured")
	}

	cfg, err := parseMessageConfig(link.Config.Params)
	if err != nil {
		return fmt.Errorf("gmail.Executor: %w", err)
	}

	identity, err := e.identities.FindByID(ctx, cfg.identityID)
	if err != nil {
		return fmt.Errorf("gmail.Executor: identity lookup: %w", err)
	}
	if identity.UserID != area.UserID {
		return fmt.Errorf("gmail.Executor: identity not owned by user")
	}

	identity, accessToken, err := e.ensureAccessToken(ctx, identity, false)
	if err != nil {
		return err
	}

	payload, err := buildRawMessage(cfg)
	if err != nil {
		return fmt.Errorf("gmail.Executor: build payload: %w", err)
	}

	unauthorized, err := e.sendMessage(ctx, accessToken, payload)
	if err != nil && unauthorized {
		identity, accessToken, err = e.ensureAccessToken(ctx, identity, true)
		if err != nil {
			return err
		}
		unauthorized, err = e.sendMessage(ctx, accessToken, payload)
	}
	if err != nil {
		return err
	}
	if unauthorized {
		return fmt.Errorf("gmail.Executor: unauthorized after refresh")
	}

	e.logger.Info("gmail reaction delivered",
		zap.String("area_id", area.ID.String()),
		zap.String("identity_id", identity.ID.String()),
		zap.Int("recipient_count", len(cfg.to)+len(cfg.cc)+len(cfg.bcc)),
	)
	return nil
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

func (e *Executor) sendMessage(ctx context.Context, accessToken string, payload []byte) (bool, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, gmailAPIEndpoint, bytes.NewReader(payload))
	if err != nil {
		return false, fmt.Errorf("gmail.Executor: build request: %w", err)
	}
	req.Header.Set("Authorization", "Bearer "+accessToken)
	req.Header.Set("Content-Type", "application/json")

	resp, err := e.http.Do(req)
	if err != nil {
		return false, fmt.Errorf("gmail.Executor: request failed: %w", err)
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)

	switch {
	case resp.StatusCode == http.StatusUnauthorized:
		return true, fmt.Errorf("gmail.Executor: unauthorized: %s", strings.TrimSpace(string(body)))
	case resp.StatusCode >= 400:
		return false, fmt.Errorf("gmail.Executor: api error %d: %s", resp.StatusCode, strings.TrimSpace(string(body)))
	default:
		return false, nil
	}
}

func (e *Executor) now() time.Time {
	if e.clock == nil {
		return time.Now().UTC()
	}
	return e.clock.Now().UTC()
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
	identityStr, err := toString(identityRaw)
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
	cfg.to, err = toEmailList(toRaw)
	if err != nil {
		return cfg, fmt.Errorf("to invalid: %w", err)
	}

	if ccRaw, ok := params["cc"]; ok {
		cfg.cc, err = toEmailList(ccRaw)
		if err != nil {
			return cfg, fmt.Errorf("cc invalid: %w", err)
		}
	}
	if bccRaw, ok := params["bcc"]; ok {
		cfg.bcc, err = toEmailList(bccRaw)
		if err != nil {
			return cfg, fmt.Errorf("bcc invalid: %w", err)
		}
	}

	subjectRaw, ok := params["subject"]
	if !ok {
		return cfg, fmt.Errorf("subject missing")
	}
	cfg.subject, err = toString(subjectRaw)
	if err != nil {
		return cfg, fmt.Errorf("subject invalid")
	}

	bodyRaw, ok := params["body"]
	if !ok {
		return cfg, fmt.Errorf("body missing")
	}
	cfg.body, err = toString(bodyRaw)
	if err != nil {
		return cfg, fmt.Errorf("body invalid")
	}

	cfg.subject = strings.TrimSpace(cfg.subject)
	cfg.body = cfg.body

	return cfg, nil
}

func sanitizeHeader(value string) string {
	replacer := strings.NewReplacer("\r", " ", "\n", " ")
	return strings.TrimSpace(replacer.Replace(value))
}

func toEmailList(value any) ([]string, error) {
	if value == nil {
		return nil, nil
	}
	if list, ok := value.([]any); ok {
		emails := make([]string, 0, len(list))
		for _, item := range list {
			address, err := toString(item)
			if err != nil {
				return nil, err
			}
			emails = append(emails, normalizeEmail(address))
		}
		return filterEmpty(emails), nil
	}
	str, err := toString(value)
	if err != nil {
		return nil, err
	}
	replacer := strings.NewReplacer(";", ",", "\n", ",")
	parts := strings.Split(replacer.Replace(str), ",")
	emails := make([]string, 0, len(parts))
	for _, part := range parts {
		address := normalizeEmail(part)
		if address != "" {
			emails = append(emails, address)
		}
	}
	if len(emails) == 0 {
		return nil, fmt.Errorf("no recipients provided")
	}
	return emails, nil
}

func normalizeEmail(raw string) string {
	return strings.TrimSpace(raw)
}

func filterEmpty(values []string) []string {
	result := make([]string, 0, len(values))
	for _, value := range values {
		if trimmed := strings.TrimSpace(value); trimmed != "" {
			result = append(result, trimmed)
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
	Execute(context.Context, areadomain.Area, areadomain.Link) error
} = (*Executor)(nil)

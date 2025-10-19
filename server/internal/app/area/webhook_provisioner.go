package area

import (
	"context"
	"crypto/rand"
	"encoding/base64"
	"fmt"
	"strings"
	"time"

	areadomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/area"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
)

const (
	defaultWebhookSecretBytes = 32
)

// SecretGenerator returns a secret string to authenticate webhook payloads
type SecretGenerator func() (string, error)

// PathGenerator returns the webhook URL path segment used to route events
type PathGenerator func(area areadomain.Area) (string, error)

// WebhookProvisioner provisions webhook action sources with deterministic routing metadata
type WebhookProvisioner struct {
	sources         outbound.ActionSourceRepository
	secretGenerator SecretGenerator
	pathGenerator   PathGenerator
	clock           Clock
}

// NewWebhookProvisioner constructs a WebhookProvisioner with optional generators
func NewWebhookProvisioner(sources outbound.ActionSourceRepository, secretGen SecretGenerator, pathGen PathGenerator, clock Clock) *WebhookProvisioner {
	if secretGen == nil {
		secretGen = defaultWebhookSecret
	}
	if pathGen == nil {
		pathGen = defaultWebhookPath
	}
	return &WebhookProvisioner{sources: sources, secretGenerator: secretGen, pathGenerator: pathGen, clock: clock}
}

// Provision materialises webhook metadata when the action declares a webhook ingestion mode
func (p *WebhookProvisioner) Provision(ctx context.Context, area areadomain.Area) error {
	if p == nil || p.sources == nil {
		return nil
	}
	if area.Status != areadomain.StatusEnabled || area.Action == nil {
		return nil
	}

	component := area.Action.Config.Component
	if component == nil {
		return nil
	}

	cfg, ok, err := decodeWebhookConfig(component.Metadata, area)
	if err != nil {
		return fmt.Errorf("area.WebhookProvisioner.Provision: decode webhook config: %w", err)
	}
	if !ok {
		return nil
	}

	secret := cfg.secret
	if secret == "" {
		generated, err := p.secretGenerator()
		if err != nil {
			return fmt.Errorf("area.WebhookProvisioner.Provision: generate secret: %w", err)
		}
		secret = generated
	}

	path := cfg.path
	if path == "" {
		generated, err := p.pathGenerator(area)
		if err != nil {
			return fmt.Errorf("area.WebhookProvisioner.Provision: generate path: %w", err)
		}
		path = generated
	}

	cursor := map[string]any{}
	if cfg.cursor != nil {
		cursor = cloneMapAny(cfg.cursor)
	}
	cursor["created_at"] = p.now().Format(time.RFC3339Nano)

	if _, err := p.sources.UpsertWebhookSource(ctx, area.Action.Config.ID, secret, path, cursor); err != nil {
		return fmt.Errorf("area.WebhookProvisioner.Provision: upsert webhook source: %w", err)
	}
	return nil
}

func (p *WebhookProvisioner) now() time.Time {
	if p.clock == nil {
		return time.Now().UTC()
	}
	return p.clock.Now().UTC()
}

type webhookConfig struct {
	secret string
	path   string
	cursor map[string]any
}

func decodeWebhookConfig(metadata map[string]any, area areadomain.Area) (webhookConfig, bool, error) {
	cfg := webhookConfig{}

	ingestRaw, ok := metadata["ingestion"]
	if !ok {
		return cfg, false, nil
	}

	ingest, err := toMapStringAny(ingestRaw)
	if err != nil {
		return cfg, false, err
	}

	mode, err := toStringLower(ingest["mode"])
	if err != nil {
		return cfg, false, nil
	}
	if mode != "webhook" {
		return cfg, false, nil
	}

	if secretRaw, ok := ingest["sharedSecret"]; ok {
		if secret, err := toString(secretRaw); err == nil && strings.TrimSpace(secret) != "" {
			cfg.secret = secret
		}
	}

	if pathRaw, ok := ingest["path"]; ok {
		if path, err := toString(pathRaw); err == nil && strings.TrimSpace(path) != "" {
			cfg.path = sanitizePath(path)
		}
	}

	if cursorRaw, ok := ingest["initialCursor"]; ok {
		if cursor, err := toMapStringAny(cursorRaw); err == nil {
			cfg.cursor = cursor
		}
	}

	return cfg, true, nil
}

func defaultWebhookSecret() (string, error) {
	buf := make([]byte, defaultWebhookSecretBytes)
	if _, err := rand.Read(buf); err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(buf), nil
}

func defaultWebhookPath(area areadomain.Area) (string, error) {
	return buildDefaultWebhookPath(area), nil
}

func buildDefaultWebhookPath(area areadomain.Area) string {
	var segments []string
	segments = append(segments, "hooks")

	if provider := displayProvider(area); provider != "" {
		segments = append(segments, provider)
	}

	if component := displayComponent(area); component != "" {
		segments = append(segments, component)
	}

	if area.Action != nil {
		id := strings.ReplaceAll(area.Action.Config.ID.String(), "-", "")
		segments = append(segments, id)
	}

	return strings.Join(segments, "/")
}

func displayProvider(area areadomain.Area) string {
	if area.Action == nil || area.Action.Config.Component == nil {
		return ""
	}
	return sanitizePath(area.Action.Config.Component.Provider.Name)
}

func displayComponent(area areadomain.Area) string {
	if area.Action == nil || area.Action.Config.Component == nil {
		return ""
	}
	return sanitizePath(area.Action.Config.Component.Name)
}

func sanitizePath(input string) string {
	trimmed := strings.ToLower(strings.TrimSpace(input))
	if trimmed == "" {
		return ""
	}
	builder := strings.Builder{}
	for _, r := range trimmed {
		switch {
		case r >= 'a' && r <= 'z':
			builder.WriteRune(r)
		case r >= '0' && r <= '9':
			builder.WriteRune(r)
		case r == '-' || r == '_':
			builder.WriteRune(r)
		case r == ' ':
			builder.WriteRune('-')
		default:
			// skip other characters
		}
	}
	result := builder.String()
	if result == "" {
		return "component"
	}
	return result
}

// Ensure WebhookProvisioner implements ActionProvisioner
var _ ActionProvisioner = (*WebhookProvisioner)(nil)

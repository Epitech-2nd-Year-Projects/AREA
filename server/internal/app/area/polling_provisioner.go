package area

import (
	"context"
	"fmt"
	"time"

	areadomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/area"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
)

const (
	defaultPollingInterval = 5 * time.Minute
)

// PollingProvisioner provisions polling metadata for action sources that rely on periodic fetches
type PollingProvisioner struct {
	sources outbound.ActionSourceRepository
	clock   Clock
}

// NewPollingProvisioner constructs a PollingProvisioner bound to the provided repositories
func NewPollingProvisioner(sources outbound.ActionSourceRepository, clock Clock) *PollingProvisioner {
	return &PollingProvisioner{sources: sources, clock: clock}
}

// Provision ensures polling sources are configured when the action metadata declares a polling ingestion mode
func (p *PollingProvisioner) Provision(ctx context.Context, area areadomain.Area) error {
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

	cfg, ok, err := decodePollingConfig(component.Metadata)
	if err != nil {
		return fmt.Errorf("area.PollingProvisioner.Provision: decode polling config: %w", err)
	}
	if !ok {
		return nil
	}

	now := p.now()
	interval := time.Duration(cfg.intervalSeconds) * time.Second
	if interval <= 0 {
		interval = defaultPollingInterval
	}
	cursor := map[string]any{
		"interval_seconds": cfg.intervalSeconds,
		"last_run":         now.Format(time.RFC3339Nano),
		"next_run":         now.Add(interval).Format(time.RFC3339Nano),
	}
	if len(cfg.initialCursor) > 0 {
		cursor["state"] = cloneMapAny(cfg.initialCursor)
	}

	if _, err := p.sources.UpsertPollingSource(ctx, area.Action.Config.ID, cursor); err != nil {
		return fmt.Errorf("area.PollingProvisioner.Provision: upsert polling source: %w", err)
	}
	return nil
}

func (p *PollingProvisioner) now() time.Time {
	if p.clock == nil {
		return time.Now().UTC()
	}
	return p.clock.Now().UTC()
}

type pollingConfig struct {
	intervalSeconds int
	initialCursor   map[string]any
}

func decodePollingConfig(metadata map[string]any) (pollingConfig, bool, error) {
	cfg := pollingConfig{intervalSeconds: int(defaultPollingInterval / time.Second)}

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
	if mode != "polling" {
		return cfg, false, nil
	}

	if value, ok := ingest["intervalSeconds"]; ok {
		interval, err := toInt(value)
		if err != nil || interval <= 0 {
			return cfg, false, fmt.Errorf("polling config: invalid intervalSeconds")
		}
		cfg.intervalSeconds = interval
	} else if value, ok := metadata["pollingIntervalSeconds"]; ok {
		interval, err := toInt(value)
		if err == nil && interval > 0 {
			cfg.intervalSeconds = interval
		}
	}

	if initial, ok := ingest["initialCursor"]; ok {
		if initialMap, err := toMapStringAny(initial); err == nil {
			cfg.initialCursor = initialMap
		}
	}

	return cfg, true, nil
}

// Ensure PollingProvisioner implements ActionProvisioner
var _ ActionProvisioner = (*PollingProvisioner)(nil)

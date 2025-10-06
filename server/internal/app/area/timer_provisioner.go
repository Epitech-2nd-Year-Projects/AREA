package area

import (
	"context"
	"fmt"
	"time"

	areadomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/area"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
)

// TimerProvisioner provisions schedule sources for timer-based actions
type TimerProvisioner struct {
	sources outbound.ActionSourceRepository
	clock   Clock
}

// NewTimerProvisioner constructs a TimerProvisioner from its dependencies
func NewTimerProvisioner(sources outbound.ActionSourceRepository, clock Clock) *TimerProvisioner {
	return &TimerProvisioner{sources: sources, clock: clock}
}

// Provision configures the timer schedule when the AREA action uses the timer component
func (p *TimerProvisioner) Provision(ctx context.Context, area areadomain.Area) error {
	if p == nil || p.sources == nil {
		return nil
	}
	if area.Status != areadomain.StatusEnabled {
		return nil
	}
	if area.Action == nil {
		return nil
	}

	component := area.Action.Config.Component
	if component == nil {
		return nil
	}
	if component.Name != timerComponentName {
		return nil
	}
	if component.Provider.Name != "" && component.Provider.Name != timerProviderName {
		return nil
	}

	cfg, err := decodeTimerConfig(area.Action.Config.Params)
	if err != nil {
		return fmt.Errorf("area.TimerProvisioner.Provision: decode timer config: %w", err)
	}

	nextRun, err := cfg.nextAfter(p.now())
	if err != nil {
		return fmt.Errorf("area.TimerProvisioner.Provision: compute next run: %w", err)
	}

	intervalSeconds := int(cfg.interval() / time.Second)
	cursor := map[string]any{
		"next_run":         nextRun.Format(time.RFC3339Nano),
		"interval_seconds": intervalSeconds,
		"frequency_value":  cfg.frequencyValue,
		"frequency_unit":   cfg.frequencyUnit,
	}
	if cfg.startAt != nil {
		cursor["start_at"] = cfg.startAt.Format(time.RFC3339Nano)
	}
	if cfg.timeZone != "" {
		cursor["time_zone"] = cfg.timeZone
	}

	schedule := cfg.description()
	if _, err := p.sources.UpsertScheduleSource(ctx, area.Action.Config.ID, schedule, cursor); err != nil {
		return fmt.Errorf("area.TimerProvisioner.Provision: upsert schedule: %w", err)
	}
	return nil
}

func (p *TimerProvisioner) now() time.Time {
	if p.clock == nil {
		return time.Now().UTC()
	}
	return p.clock.Now().UTC()
}

// Ensure TimerProvisioner implements ActionProvisioner
var _ ActionProvisioner = (*TimerProvisioner)(nil)

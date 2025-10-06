package area

import (
	"context"
	"time"

	actiondomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/action"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
	"github.com/google/uuid"
	"go.uber.org/zap"
)

// AreaExecutor represents the subset of Service required by the scheduler
type AreaExecutor interface {
	Execute(ctx context.Context, userID uuid.UUID, areaID uuid.UUID) error
}

// TimerScheduler polls scheduled actions and triggers the associated areas
type TimerScheduler struct {
	sources  outbound.ActionSourceRepository
	executor AreaExecutor
	clock    Clock
	logger   *zap.Logger
	interval time.Duration
	batch    int
}

// TimerSchedulerOption configures scheduler behavior
type TimerSchedulerOption func(*TimerScheduler)

// WithTimerInterval overrides the polling interval
func WithTimerInterval(interval time.Duration) TimerSchedulerOption {
	return func(s *TimerScheduler) {
		if interval > 0 {
			s.interval = interval
		}
	}
}

// WithTimerBatchSize overrides the maximum number of schedules processed per tick
func WithTimerBatchSize(size int) TimerSchedulerOption {
	return func(s *TimerScheduler) {
		if size > 0 {
			s.batch = size
		}
	}
}

// WithTimerLogger sets the logger used by the scheduler
func WithTimerLogger(logger *zap.Logger) TimerSchedulerOption {
	return func(s *TimerScheduler) {
		if logger != nil {
			s.logger = logger
		}
	}
}

// NewTimerScheduler assembles a scheduler for timer-based actions
func NewTimerScheduler(sources outbound.ActionSourceRepository, executor AreaExecutor, clock Clock, opts ...TimerSchedulerOption) *TimerScheduler {
	scheduler := &TimerScheduler{
		sources:  sources,
		executor: executor,
		clock:    clock,
		interval: time.Minute,
		batch:    25,
		logger:   zap.NewNop(),
	}
	for _, opt := range opts {
		if opt != nil {
			opt(scheduler)
		}
	}
	if scheduler.logger == nil {
		scheduler.logger = zap.NewNop()
	}
	if scheduler.interval <= 0 {
		scheduler.interval = time.Minute
	}
	if scheduler.batch <= 0 {
		scheduler.batch = 25
	}
	return scheduler
}

// Run starts the scheduler loop until the context is cancelled
func (s *TimerScheduler) Run(ctx context.Context) {
	if s == nil || s.sources == nil || s.executor == nil {
		return
	}

	s.process(ctx)
	ticker := time.NewTicker(s.interval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			s.process(ctx)
		}
	}
}

func (s *TimerScheduler) process(ctx context.Context) {
	now := s.now()
	bindings, err := s.sources.ListDueScheduleSources(ctx, now, s.batch)
	if err != nil {
		s.log().Error("list due timer sources failed", zap.Error(err))
		return
	}
	for _, binding := range bindings {
		s.executeBinding(ctx, binding, now)
	}
}

func (s *TimerScheduler) executeBinding(ctx context.Context, binding actiondomain.ScheduleBinding, now time.Time) {
	if binding.NextRun.IsZero() {
		return
	}

	execErr := s.executor.Execute(ctx, binding.UserID, binding.AreaID)
	if execErr != nil {
		s.log().Error("timer execution failed", zap.Error(execErr), zap.String("area_id", binding.AreaID.String()))
	}

	cfg, err := decodeTimerConfig(binding.Config.Params)
	if err != nil {
		s.log().Error("timer config decode failed", zap.Error(err), zap.String("area_id", binding.AreaID.String()))
		return
	}

	nextRun, err := cfg.nextAfter(now)
	if err != nil {
		s.log().Error("timer next run calculation failed", zap.Error(err), zap.String("area_id", binding.AreaID.String()))
		return
	}

	cursor := cloneMap(binding.Source.Cursor)
	intervalSeconds := int(cfg.interval() / time.Second)
	cursor["next_run"] = nextRun.Format(time.RFC3339Nano)
	cursor["interval_seconds"] = intervalSeconds
	cursor["frequency_value"] = cfg.frequencyValue
	cursor["frequency_unit"] = cfg.frequencyUnit
	cursor["last_run"] = now.Format(time.RFC3339Nano)
	if cfg.startAt != nil {
		cursor["start_at"] = cfg.startAt.Format(time.RFC3339Nano)
	}
	if cfg.timeZone != "" {
		cursor["time_zone"] = cfg.timeZone
	}
	if execErr != nil {
		cursor["last_error"] = execErr.Error()
	} else {
		delete(cursor, "last_error")
	}

	if err := s.sources.UpdateScheduleCursor(ctx, binding.Source.ID, binding.Source.ComponentConfigID, cursor); err != nil {
		s.log().Error(
			"timer cursor update failed",
			zap.Error(err),
			zap.String("source_id", binding.Source.ID.String()),
			zap.String("component_config_id", binding.Source.ComponentConfigID.String()),
		)
	}
}

func (s *TimerScheduler) now() time.Time {
	if s.clock == nil {
		return time.Now().UTC()
	}
	return s.clock.Now().UTC()
}

func (s *TimerScheduler) log() *zap.Logger {
	if s.logger != nil {
		return s.logger
	}
	return zap.NewNop()
}

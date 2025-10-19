package area

import (
	"context"
	"time"

	actiondomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/action"
	componentdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/component"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
	"go.uber.org/zap"
)

const (
	defaultPollingIntervalSeconds = int(defaultPollingInterval / time.Second)
)

// PollingEvent captures an event emitted by a polling action
type PollingEvent struct {
	Payload     map[string]any
	Fingerprint string
	OccurredAt  time.Time
}

// PollingResult groups the events produced by a polling cycle and the updated cursor state
type PollingResult struct {
	Cursor map[string]any
	Events []PollingEvent
}

// PollingRequest provides context to component-specific polling handlers
type PollingRequest struct {
	Binding   actiondomain.PollingBinding
	Component componentdomain.Component
	Cursor    map[string]any
	Now       time.Time
}

// ComponentPollingHandler fetches events for polling-based action components
type ComponentPollingHandler interface {
	Supports(component *componentdomain.Component) bool
	Poll(ctx context.Context, req PollingRequest) (PollingResult, error)
}

// PollingRunner orchestrates polling action execution and event creation
type PollingRunner struct {
	sources    outbound.ActionSourceRepository
	components outbound.ComponentRepository
	executor   AreaExecutor
	handlers   []ComponentPollingHandler
	clock      Clock
	logger     *zap.Logger
	interval   time.Duration
	batch      int
}

// PollingRunnerOption configures the polling runner behaviour
type PollingRunnerOption func(*PollingRunner)

// WithPollingInterval overrides the runner loop interval
func WithPollingInterval(interval time.Duration) PollingRunnerOption {
	return func(r *PollingRunner) {
		if interval > 0 {
			r.interval = interval
		}
	}
}

// WithPollingBatchSize overrides the maximum number of polling sources processed per tick
func WithPollingBatchSize(size int) PollingRunnerOption {
	return func(r *PollingRunner) {
		if size > 0 {
			r.batch = size
		}
	}
}

// WithPollingLogger sets the logger used by the runner
func WithPollingLogger(logger *zap.Logger) PollingRunnerOption {
	return func(r *PollingRunner) {
		if logger != nil {
			r.logger = logger
		}
	}
}

// NewPollingRunner assembles a polling runner from its dependencies
func NewPollingRunner(
	sources outbound.ActionSourceRepository,
	components outbound.ComponentRepository,
	executor AreaExecutor,
	clock Clock,
	handlers []ComponentPollingHandler,
	opts ...PollingRunnerOption,
) *PollingRunner {
	if sources == nil || components == nil || executor == nil {
		return nil
	}
	if clock == nil {
		clock = systemClock{}
	}
	runner := &PollingRunner{
		sources:    sources,
		components: components,
		executor:   executor,
		handlers:   append([]ComponentPollingHandler(nil), handlers...),
		clock:      clock,
		logger:     zap.NewNop(),
		interval:   30 * time.Second,
		batch:      50,
	}
	for _, opt := range opts {
		if opt != nil {
			opt(runner)
		}
	}
	if runner.logger == nil {
		runner.logger = zap.NewNop()
	}
	if runner.interval <= 0 {
		runner.interval = 30 * time.Second
	}
	if runner.batch <= 0 {
		runner.batch = 50
	}
	return runner
}

// Run starts the polling loop until the context is cancelled
func (r *PollingRunner) Run(ctx context.Context) {
	if r == nil {
		return
	}

	r.process(ctx)
	ticker := time.NewTicker(r.interval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			r.process(ctx)
		}
	}
}

func (r *PollingRunner) process(ctx context.Context) {
	if r.sources == nil || r.components == nil || r.executor == nil {
		return
	}
	now := r.now()
	bindings, err := r.sources.ListDuePollingSources(ctx, now, r.batch)
	if err != nil {
		r.log().Error("list due polling sources failed", zap.Error(err))
		return
	}
	for _, binding := range bindings {
		r.processBinding(ctx, binding, now)
	}
}

func (r *PollingRunner) processBinding(ctx context.Context, binding actiondomain.PollingBinding, now time.Time) {
	component, err := r.components.FindByID(ctx, binding.Config.ComponentID)
	if err != nil {
		r.log().Error("load polling component failed",
			zap.Error(err),
			zap.String("component_id", binding.Config.ComponentID.String()),
			zap.String("area_id", binding.AreaID.String()),
		)
		r.bumpCursor(ctx, binding, now, defaultPollingIntervalSeconds, nil)
		return
	}

	handler := r.findHandler(&component)
	if handler == nil {
		r.log().Warn("no polling handler for component",
			zap.String("component", component.Name),
			zap.String("provider", component.Provider.Name),
			zap.String("area_id", binding.AreaID.String()),
		)
		r.bumpCursor(ctx, binding, now, intervalFromCursor(binding.Source.Cursor), nil)
		return
	}

	cursor := cloneMapAny(binding.Source.Cursor)
	if cursor == nil {
		cursor = map[string]any{}
	}
	req := PollingRequest{
		Binding:   binding,
		Component: component,
		Cursor:    cloneMapAny(cursor),
		Now:       now,
	}

	result, err := handler.Poll(ctx, req)
	if err != nil {
		r.log().Error("polling handler failed",
			zap.Error(err),
			zap.String("component", component.Name),
			zap.String("provider", component.Provider.Name),
			zap.String("area_id", binding.AreaID.String()),
		)
		result = PollingResult{}
	}

	intervalSeconds := intervalFromCursor(cursor)
	r.bumpCursor(ctx, binding, now, intervalSeconds, result.Cursor)

	for _, event := range result.Events {
		payload := cloneMapAny(event.Payload)
		if payload == nil {
			payload = map[string]any{}
		}
		options := ExecutionOptions{
			SourceID:    binding.Source.ID,
			Payload:     payload,
			Fingerprint: event.Fingerprint,
			OccurredAt:  event.OccurredAt,
		}
		if err := r.executor.ExecuteWithOptions(ctx, binding.UserID, binding.AreaID, options); err != nil {
			r.log().Error("polling execution failed",
				zap.Error(err),
				zap.String("area_id", binding.AreaID.String()),
			)
		}
	}
}

func (r *PollingRunner) bumpCursor(ctx context.Context, binding actiondomain.PollingBinding, now time.Time, intervalSeconds int, updates map[string]any) {
	if intervalSeconds <= 0 {
		intervalSeconds = defaultPollingIntervalSeconds
	}
	cursor := cloneMapAny(binding.Source.Cursor)
	if cursor == nil {
		cursor = map[string]any{}
	}
	for key, value := range cursorNormalization(updates) {
		cursor[key] = value
	}
	cursor["interval_seconds"] = intervalSeconds
	cursor["last_run"] = now.Format(time.RFC3339Nano)
	nextRun := now.Add(time.Duration(intervalSeconds) * time.Second)
	cursor["next_run"] = nextRun.Format(time.RFC3339Nano)

	if err := r.sources.UpdatePollingCursor(ctx, binding.Source.ID, binding.Source.ComponentConfigID, cursor); err != nil {
		r.log().Error("polling cursor update failed",
			zap.Error(err),
			zap.String("source_id", binding.Source.ID.String()),
			zap.String("component_config_id", binding.Source.ComponentConfigID.String()),
		)
	}
}

func cursorNormalization(updates map[string]any) map[string]any {
	if len(updates) == 0 {
		return map[string]any{}
	}
	return cloneMapAny(updates)
}

func intervalFromCursor(cursor map[string]any) int {
	if cursor == nil {
		return defaultPollingIntervalSeconds
	}
	if value, ok := cursor["interval_seconds"]; ok {
		if interval, err := toInt(value); err == nil && interval > 0 {
			return interval
		}
	}
	return defaultPollingIntervalSeconds
}

func (r *PollingRunner) findHandler(component *componentdomain.Component) ComponentPollingHandler {
	for _, handler := range r.handlers {
		if handler != nil && handler.Supports(component) {
			return handler
		}
	}
	return nil
}

func (r *PollingRunner) now() time.Time {
	if r.clock == nil {
		return time.Now().UTC()
	}
	return r.clock.Now().UTC()
}

func (r *PollingRunner) log() *zap.Logger {
	if r.logger != nil {
		return r.logger
	}
	return zap.NewNop()
}

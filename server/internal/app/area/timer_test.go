package area

import (
	"context"
	"testing"
	"time"

	actiondomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/action"
	areadomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/area"
	componentdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/component"
	"github.com/google/uuid"
	"go.uber.org/zap"
)

func TestDecodeTimerConfig(t *testing.T) {
	params := map[string]any{
		"frequencyValue": 5,
		"frequencyUnit":  "minutes",
	}
	cfg, err := decodeTimerConfig(params)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if cfg.frequencyValue != 5 || cfg.frequencyUnit != "minute" {
		t.Fatalf("unexpected config %+v", cfg)
	}
	interval := cfg.interval()
	if interval != 5*time.Minute {
		t.Fatalf("unexpected interval %s", interval)
	}

	now := time.Date(2024, 4, 1, 10, 0, 0, 0, time.UTC)
	next, err := cfg.nextAfter(now)
	if err != nil {
		t.Fatalf("nextAfter error: %v", err)
	}
	if !next.Equal(now.Add(5 * time.Minute)) {
		t.Fatalf("unexpected next run %s", next)
	}
}

func TestDecodeTimerConfig_WithStartAt(t *testing.T) {
	start := "2024-04-01T08:00:00Z"
	params := map[string]any{
		"frequencyValue": 2,
		"frequencyUnit":  "hours",
		"startAt":        start,
	}
	cfg, err := decodeTimerConfig(params)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if cfg.startAt == nil {
		t.Fatalf("expected startAt parsed")
	}
	now := time.Date(2024, 4, 1, 9, 0, 0, 0, time.UTC)
	next, err := cfg.nextAfter(now)
	if err != nil {
		t.Fatalf("nextAfter error: %v", err)
	}
	expected := time.Date(2024, 4, 1, 10, 0, 0, 0, time.UTC)
	if !next.Equal(expected) {
		t.Fatalf("expected %s got %s", expected, next)
	}
}

func TestTimerProvisioner(t *testing.T) {
	repo := &mockActionSourceRepo{}
	clock := stubClock{now: time.Date(2024, 4, 1, 12, 0, 0, 0, time.UTC)}
	prov := NewTimerProvisioner(repo, clock)

	componentID := uuid.New()
	area := areadomain.Area{
		ID:     uuid.New(),
		UserID: uuid.New(),
		Status: areadomain.StatusEnabled,
		Action: &areadomain.Link{
			Config: componentdomain.Config{
				ID:          uuid.New(),
				ComponentID: componentID,
				Params:      map[string]any{"frequencyValue": 10, "frequencyUnit": "minutes"},
				Component: &componentdomain.Component{
					ID:         componentID,
					Name:       timerComponentName,
					Provider:   componentdomain.Provider{Name: timerProviderName},
					Enabled:    true,
					ProviderID: uuid.New(),
				},
			},
		},
	}

	if err := prov.Provision(context.Background(), area); err != nil {
		t.Fatalf("Provision error: %v", err)
	}

	if len(repo.upsertCalls) != 1 {
		t.Fatalf("expected 1 upsert call got %d", len(repo.upsertCalls))
	}
	call := repo.upsertCalls[0]
	if call.schedule != "every 10 minutes" {
		t.Fatalf("unexpected schedule %s", call.schedule)
	}
	if call.cursor["interval_seconds"] != 600 {
		t.Fatalf("unexpected interval seconds %v", call.cursor["interval_seconds"])
	}
	if _, ok := call.cursor["next_run"]; !ok {
		t.Fatalf("next_run missing in cursor")
	}
}

func TestTimerSchedulerProcess(t *testing.T) {
	repo := &mockActionSourceRepo{}
	exec := &stubAreaExecutor{}
	clock := stubClock{now: time.Date(2024, 4, 1, 15, 0, 0, 0, time.UTC)}

	sourceID := uuid.New()
	areaID := uuid.New()
	configID := uuid.New()
	binding := actiondomain.ScheduleBinding{
		Source: actiondomain.Source{
			ID:                sourceID,
			ComponentConfigID: configID,
			Cursor:            map[string]any{},
		},
		AreaID:  areaID,
		UserID:  uuid.New(),
		NextRun: clock.now.Add(-time.Minute),
		Config: componentdomain.Config{
			Params: map[string]any{"frequencyValue": 15, "frequencyUnit": "minutes"},
		},
	}
	repo.listResponse = []actiondomain.ScheduleBinding{binding}

	scheduler := NewTimerScheduler(repo, exec, clock, WithTimerLogger(zap.NewNop()))
	scheduler.process(context.Background())

	if len(exec.calls) != 1 {
		t.Fatalf("expected executor to be called once, got %d", len(exec.calls))
	}
	if len(repo.updateCalls) != 1 {
		t.Fatalf("expected cursor update call")
	}
	update := repo.updateCalls[0]
	if update.sourceID != sourceID {
		t.Fatalf("unexpected sourceID %s", update.sourceID)
	}
	if update.componentConfigID != binding.Source.ComponentConfigID {
		t.Fatalf("unexpected component config id %s", update.componentConfigID)
	}
	if _, ok := update.cursor["next_run"]; !ok {
		t.Fatalf("next_run missing in updated cursor")
	}
}

type mockActionSourceRepo struct {
	upsertCalls []struct {
		configID uuid.UUID
		schedule string
		cursor   map[string]any
	}
	listResponse []actiondomain.ScheduleBinding
	updateCalls  []struct {
		sourceID          uuid.UUID
		componentConfigID uuid.UUID
		cursor            map[string]any
	}
	findCalls    []uuid.UUID
	findResponse actiondomain.Source
	findErr      error
}

func (m *mockActionSourceRepo) UpsertScheduleSource(ctx context.Context, componentConfigID uuid.UUID, schedule string, cursor map[string]any) (actiondomain.Source, error) {
	clone := cloneMap(cursor)
	m.upsertCalls = append(m.upsertCalls, struct {
		configID uuid.UUID
		schedule string
		cursor   map[string]any
	}{configID: componentConfigID, schedule: schedule, cursor: clone})
	return actiondomain.Source{ID: uuid.New()}, nil
}

func (m *mockActionSourceRepo) ListDueScheduleSources(ctx context.Context, before time.Time, limit int) ([]actiondomain.ScheduleBinding, error) {
	return append([]actiondomain.ScheduleBinding(nil), m.listResponse...), nil
}

func (m *mockActionSourceRepo) UpdateScheduleCursor(ctx context.Context, sourceID uuid.UUID, componentConfigID uuid.UUID, cursor map[string]any) error {
	clone := cloneMap(cursor)
	m.updateCalls = append(m.updateCalls, struct {
		sourceID          uuid.UUID
		componentConfigID uuid.UUID
		cursor            map[string]any
	}{sourceID: sourceID, componentConfigID: componentConfigID, cursor: clone})
	return nil
}

func (m *mockActionSourceRepo) FindByComponentConfig(ctx context.Context, componentConfigID uuid.UUID) (actiondomain.Source, error) {
	m.findCalls = append(m.findCalls, componentConfigID)
	if m.findErr != nil {
		return actiondomain.Source{}, m.findErr
	}
	resp := m.findResponse
	if resp.Cursor != nil {
		resp.Cursor = cloneMap(resp.Cursor)
	}
	return resp, nil
}

type stubAreaExecutor struct {
	calls []struct {
		userID  uuid.UUID
		areaID  uuid.UUID
		options ExecutionOptions
	}
	err error
}

func (s *stubAreaExecutor) ExecuteWithOptions(ctx context.Context, userID uuid.UUID, areaID uuid.UUID, opts ExecutionOptions) error {
	s.calls = append(s.calls, struct {
		userID  uuid.UUID
		areaID  uuid.UUID
		options ExecutionOptions
	}{userID: userID, areaID: areaID, options: opts})
	return s.err
}

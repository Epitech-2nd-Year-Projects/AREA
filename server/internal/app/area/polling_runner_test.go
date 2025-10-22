package area

import (
	"context"
	"fmt"
	"testing"
	"time"

	actiondomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/action"
	componentdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/component"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
	"github.com/google/uuid"
)

type stubPollingSourceRepo struct {
	bindings          []actiondomain.PollingBinding
	cursorUpdates     []map[string]any
	updateSourceIDs   []uuid.UUID
	updateConfigIDs   []uuid.UUID
	listInvocations   int
	updateInvocations int
}

func (s *stubPollingSourceRepo) UpsertScheduleSource(ctx context.Context, componentConfigID uuid.UUID, schedule string, cursor map[string]any) (actiondomain.Source, error) {
	return actiondomain.Source{}, fmt.Errorf("not implemented")
}

func (s *stubPollingSourceRepo) UpsertPollingSource(ctx context.Context, componentConfigID uuid.UUID, cursor map[string]any) (actiondomain.Source, error) {
	return actiondomain.Source{}, fmt.Errorf("not implemented")
}

func (s *stubPollingSourceRepo) UpsertWebhookSource(ctx context.Context, componentConfigID uuid.UUID, secret string, urlPath string, cursor map[string]any) (actiondomain.Source, error) {
	return actiondomain.Source{}, fmt.Errorf("not implemented")
}

func (s *stubPollingSourceRepo) ListDueScheduleSources(ctx context.Context, before time.Time, limit int) ([]actiondomain.ScheduleBinding, error) {
	return nil, fmt.Errorf("not implemented")
}

func (s *stubPollingSourceRepo) ListDuePollingSources(ctx context.Context, before time.Time, limit int) ([]actiondomain.PollingBinding, error) {
	s.listInvocations++
	result := make([]actiondomain.PollingBinding, 0, len(s.bindings))
	for _, binding := range s.bindings {
		clone := binding
		clone.Source.Cursor = cloneMapAny(binding.Source.Cursor)
		result = append(result, clone)
	}
	s.bindings = nil
	return result, nil
}

func (s *stubPollingSourceRepo) UpdateScheduleCursor(ctx context.Context, sourceID uuid.UUID, componentConfigID uuid.UUID, cursor map[string]any) error {
	return fmt.Errorf("not implemented")
}

func (s *stubPollingSourceRepo) UpdatePollingCursor(ctx context.Context, sourceID uuid.UUID, componentConfigID uuid.UUID, cursor map[string]any) error {
	s.updateInvocations++
	s.updateSourceIDs = append(s.updateSourceIDs, sourceID)
	s.updateConfigIDs = append(s.updateConfigIDs, componentConfigID)
	s.cursorUpdates = append(s.cursorUpdates, cloneMapAny(cursor))
	return nil
}

func (s *stubPollingSourceRepo) FindByComponentConfig(ctx context.Context, componentConfigID uuid.UUID) (actiondomain.Source, error) {
	return actiondomain.Source{}, fmt.Errorf("not implemented")
}

func (s *stubPollingSourceRepo) UpdateWebhookCursor(ctx context.Context, sourceID uuid.UUID, componentConfigID uuid.UUID, cursor map[string]any) error {
	return nil
}

func (s *stubPollingSourceRepo) FindWebhookBindingByPath(ctx context.Context, path string) (actiondomain.WebhookBinding, error) {
	return actiondomain.WebhookBinding{}, outbound.ErrNotFound
}

type stubComponentRepo struct {
	component componentdomain.Component
	err       error
}

func (s stubComponentRepo) FindByID(ctx context.Context, id uuid.UUID) (componentdomain.Component, error) {
	if s.err != nil {
		return componentdomain.Component{}, s.err
	}
	component := s.component
	return component, nil
}

func (s stubComponentRepo) FindByIDs(ctx context.Context, ids []uuid.UUID) (map[uuid.UUID]componentdomain.Component, error) {
	return nil, fmt.Errorf("not implemented")
}

func (s stubComponentRepo) List(ctx context.Context, opts outbound.ComponentListOptions) ([]componentdomain.Component, error) {
	return nil, fmt.Errorf("not implemented")
}

type recordingPollingHandler struct {
	supports bool
	result   PollingResult
	err      error
	calls    []PollingRequest
}

func (h *recordingPollingHandler) Supports(component *componentdomain.Component) bool {
	return h.supports
}

func (h *recordingPollingHandler) Poll(ctx context.Context, req PollingRequest) (PollingResult, error) {
	h.calls = append(h.calls, req)
	if h.err != nil {
		return PollingResult{}, h.err
	}
	return h.result, nil
}

type recordingExecutor struct {
	calls []ExecutionOptions
}

func (r *recordingExecutor) ExecuteWithOptions(ctx context.Context, userID uuid.UUID, areaID uuid.UUID, opts ExecutionOptions) error {
	r.calls = append(r.calls, opts)
	return nil
}

func TestPollingRunnerProcessesEvents(t *testing.T) {
	now := time.Unix(1720000000, 0).UTC()
	sourceID := uuid.New()
	configID := uuid.New()
	areaID := uuid.New()
	userID := uuid.New()

	binding := actiondomain.PollingBinding{
		Source: actiondomain.Source{
			ID:                sourceID,
			ComponentConfigID: configID,
			Mode:              actiondomain.ModePolling,
			Cursor: map[string]any{
				"interval_seconds": 60,
				"next_run":         now.Format(time.RFC3339Nano),
				"state": map[string]any{
					"cursor": "123",
				},
			},
			IsActive: true,
		},
		AreaID:     areaID,
		AreaLinkID: uuid.New(),
		UserID:     userID,
		NextRun:    now,
		Config: componentdomain.Config{
			ID:          configID,
			ComponentID: uuid.New(),
			Params: map[string]any{
				"type": "demo",
			},
		},
	}

	repo := &stubPollingSourceRepo{
		bindings: []actiondomain.PollingBinding{binding},
	}
	component := componentdomain.Component{
		ID:         binding.Config.ComponentID,
		Name:       "github_new_issue",
		ProviderID: uuid.New(),
		Provider: componentdomain.Provider{
			ID:   uuid.New(),
			Name: "github",
		},
		Metadata: map[string]any{},
	}
	componentRepo := stubComponentRepo{component: component}

	handler := &recordingPollingHandler{
		supports: true,
		result: PollingResult{
			Cursor: map[string]any{
				"state": map[string]any{
					"cursor": "456",
				},
			},
			Events: []PollingEvent{
				{
					Payload: map[string]any{"number": 42},
				},
			},
		},
	}

	executor := &recordingExecutor{}

	runner := NewPollingRunner(repo, componentRepo, executor, stubClock{now: now}, []ComponentPollingHandler{handler},
		WithPollingInterval(10*time.Millisecond),
		WithPollingBatchSize(5),
	)
	if runner == nil {
		t.Fatalf("expected runner to be constructed")
	}

	runner.process(context.Background())

	if repo.listInvocations != 1 {
		t.Fatalf("expected ListDuePollingSources to be called once, got %d", repo.listInvocations)
	}
	if len(repo.cursorUpdates) != 1 {
		t.Fatalf("expected cursor update, got %d", len(repo.cursorUpdates))
	}
	updated := repo.cursorUpdates[0]
	if updated["interval_seconds"] != 60 {
		t.Fatalf("expected interval_seconds to remain 60, got %v", updated["interval_seconds"])
	}
	if _, ok := updated["next_run"]; !ok {
		t.Fatalf("expected next_run to be set")
	}
	state, ok := updated["state"].(map[string]any)
	if !ok || state["cursor"] != "456" {
		t.Fatalf("expected cursor state to be updated, got %v", updated["state"])
	}

	if len(handler.calls) != 1 {
		t.Fatalf("expected handler to be invoked once, got %d", len(handler.calls))
	}
	if len(executor.calls) != 1 {
		t.Fatalf("expected executor to be invoked once, got %d", len(executor.calls))
	}
	if value := executor.calls[0].Payload["number"]; value != 42.0 && value != 42 {
		t.Fatalf("unexpected payload propagated: %v", executor.calls[0].Payload)
	}
}

func TestPollingRunnerNoHandlerSkipsBinding(t *testing.T) {
	now := time.Unix(1720000000, 0).UTC()
	sourceID := uuid.New()
	configID := uuid.New()

	binding := actiondomain.PollingBinding{
		Source: actiondomain.Source{
			ID:                sourceID,
			ComponentConfigID: configID,
			Mode:              actiondomain.ModePolling,
			Cursor: map[string]any{
				"interval_seconds": 120,
				"next_run":         now.Format(time.RFC3339Nano),
			},
			IsActive: true,
		},
		AreaID:     uuid.New(),
		AreaLinkID: uuid.New(),
		UserID:     uuid.New(),
		NextRun:    now,
		Config: componentdomain.Config{
			ID:          configID,
			ComponentID: uuid.New(),
		},
	}

	repo := &stubPollingSourceRepo{
		bindings: []actiondomain.PollingBinding{binding},
	}
	component := componentdomain.Component{
		ID:         binding.Config.ComponentID,
		Name:       "unsupported_action",
		ProviderID: uuid.New(),
		Provider:   componentdomain.Provider{Name: "demo"},
	}
	componentRepo := stubComponentRepo{component: component}
	executor := &recordingExecutor{}

	runner := NewPollingRunner(repo, componentRepo, executor, stubClock{now: now}, nil)
	if runner == nil {
		t.Fatalf("expected runner to be constructed")
	}

	runner.process(context.Background())

	if len(executor.calls) != 0 {
		t.Fatalf("expected no executor calls, got %d", len(executor.calls))
	}
	if len(repo.cursorUpdates) != 1 {
		t.Fatalf("expected cursor update even without handler")
	}
	updated := repo.cursorUpdates[0]
	if updated["interval_seconds"] != 120 {
		t.Fatalf("expected interval_seconds to remain 120, got %v", updated["interval_seconds"])
	}
}

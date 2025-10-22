package area

import (
	"context"
	"testing"
	"time"

	actiondomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/action"
	areadomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/area"
	componentdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/component"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
	"github.com/google/uuid"
)

type recordingActionSourceRepo struct {
	pollingCalled bool
	webhookCalled bool
	pollingInput  struct {
		ComponentConfigID uuid.UUID
		Cursor            map[string]any
	}
}

func (r *recordingActionSourceRepo) UpsertScheduleSource(ctx context.Context, componentConfigID uuid.UUID, schedule string, cursor map[string]any) (actiondomain.Source, error) {
	return actiondomain.Source{}, nil
}

func (r *recordingActionSourceRepo) UpsertPollingSource(ctx context.Context, componentConfigID uuid.UUID, cursor map[string]any) (actiondomain.Source, error) {
	r.pollingCalled = true
	r.pollingInput.ComponentConfigID = componentConfigID
	r.pollingInput.Cursor = cursor
	return actiondomain.Source{ComponentConfigID: componentConfigID, Mode: actiondomain.ModePolling}, nil
}

func (r *recordingActionSourceRepo) UpsertWebhookSource(ctx context.Context, componentConfigID uuid.UUID, secret string, urlPath string, cursor map[string]any) (actiondomain.Source, error) {
	r.webhookCalled = true
	return actiondomain.Source{}, nil
}

func (r *recordingActionSourceRepo) ListDueScheduleSources(ctx context.Context, before time.Time, limit int) ([]actiondomain.ScheduleBinding, error) {
	return nil, nil
}

func (r *recordingActionSourceRepo) ListDuePollingSources(ctx context.Context, before time.Time, limit int) ([]actiondomain.PollingBinding, error) {
	return nil, nil
}

func (r *recordingActionSourceRepo) UpdateScheduleCursor(ctx context.Context, sourceID uuid.UUID, componentConfigID uuid.UUID, cursor map[string]any) error {
	return nil
}

func (r *recordingActionSourceRepo) UpdatePollingCursor(ctx context.Context, sourceID uuid.UUID, componentConfigID uuid.UUID, cursor map[string]any) error {
	return nil
}

func (r *recordingActionSourceRepo) FindByComponentConfig(ctx context.Context, componentConfigID uuid.UUID) (actiondomain.Source, error) {
	return actiondomain.Source{}, nil
}

func (r *recordingActionSourceRepo) UpdateWebhookCursor(ctx context.Context, sourceID uuid.UUID, componentConfigID uuid.UUID, cursor map[string]any) error {
	return nil
}

func (r *recordingActionSourceRepo) FindWebhookBindingByPath(ctx context.Context, path string) (actiondomain.WebhookBinding, error) {
	return actiondomain.WebhookBinding{}, outbound.ErrNotFound
}

func TestPollingProvisioner_UpsertsPollingSource(t *testing.T) {
	repo := &recordingActionSourceRepo{}
	prov := NewPollingProvisioner(repo, stubClock{now: time.Unix(1720000000, 0).UTC()})

	componentID := uuid.New()
	area := areadomain.Area{
		Status: areadomain.StatusEnabled,
		Action: &areadomain.Link{
			Config: componentdomain.Config{
				ID: componentID,
				Component: &componentdomain.Component{
					Metadata: map[string]any{
						"ingestion": map[string]any{
							"mode":            "polling",
							"intervalSeconds": 120,
							"initialCursor": map[string]any{
								"since": "0",
							},
						},
					},
				},
			},
		},
	}

	if err := prov.Provision(context.Background(), area); err != nil {
		t.Fatalf("Provision returned error: %v", err)
	}
	if !repo.pollingCalled {
		t.Fatalf("expected polling source to be provisioned")
	}
	if repo.pollingInput.ComponentConfigID != componentID {
		t.Fatalf("component config mismatch")
	}
	if repo.pollingInput.Cursor["interval_seconds"] != 120 {
		t.Fatalf("expected interval to be 120 seconds")
	}
	state, ok := repo.pollingInput.Cursor["state"].(map[string]any)
	if !ok || state["since"] != "0" {
		t.Fatalf("expected initial cursor to be preserved")
	}
	if _, ok := repo.pollingInput.Cursor["last_run"]; !ok {
		t.Fatalf("expected last_run to be set")
	}
	if repo.webhookCalled {
		t.Fatalf("webhook provisioner should not be invoked in polling flow")
	}
}

func TestPollingProvisioner_NoOpWhenNotPolling(t *testing.T) {
	repo := &recordingActionSourceRepo{}
	prov := NewPollingProvisioner(repo, stubClock{now: time.Now().UTC()})

	area := areadomain.Area{
		Status: areadomain.StatusEnabled,
		Action: &areadomain.Link{
			Config: componentdomain.Config{
				ID: uuid.New(),
				Component: &componentdomain.Component{
					Metadata: map[string]any{
						"ingestion": map[string]any{
							"mode": "webhook",
						},
					},
				},
			},
		},
	}

	if err := prov.Provision(context.Background(), area); err != nil {
		t.Fatalf("Provision returned error: %v", err)
	}
	if repo.pollingCalled {
		t.Fatalf("polling provisioner should have skipped non-polling component")
	}
}

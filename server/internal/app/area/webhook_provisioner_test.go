package area

import (
	"context"
	"testing"
	"time"

	actiondomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/action"
	areadomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/area"
	componentdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/component"
	"github.com/google/uuid"
)

type webhookRecordingRepo struct {
	webhookCalled bool
	webhookInput  struct {
		ComponentConfigID uuid.UUID
		Secret            string
		Path              string
		Cursor            map[string]any
	}
}

func (r *webhookRecordingRepo) UpsertScheduleSource(ctx context.Context, componentConfigID uuid.UUID, schedule string, cursor map[string]any) (actiondomain.Source, error) {
	return actiondomain.Source{}, nil
}

func (r *webhookRecordingRepo) UpsertPollingSource(ctx context.Context, componentConfigID uuid.UUID, cursor map[string]any) (actiondomain.Source, error) {
	return actiondomain.Source{}, nil
}

func (r *webhookRecordingRepo) UpsertWebhookSource(ctx context.Context, componentConfigID uuid.UUID, secret string, urlPath string, cursor map[string]any) (actiondomain.Source, error) {
	r.webhookCalled = true
	r.webhookInput.ComponentConfigID = componentConfigID
	r.webhookInput.Secret = secret
	r.webhookInput.Path = urlPath
	r.webhookInput.Cursor = cursor
	return actiondomain.Source{ComponentConfigID: componentConfigID, Mode: actiondomain.ModeWebhook}, nil
}

func (r *webhookRecordingRepo) ListDueScheduleSources(ctx context.Context, before time.Time, limit int) ([]actiondomain.ScheduleBinding, error) {
	return nil, nil
}

func (r *webhookRecordingRepo) ListDuePollingSources(ctx context.Context, before time.Time, limit int) ([]actiondomain.PollingBinding, error) {
	return nil, nil
}

func (r *webhookRecordingRepo) UpdateScheduleCursor(ctx context.Context, sourceID uuid.UUID, componentConfigID uuid.UUID, cursor map[string]any) error {
	return nil
}

func (r *webhookRecordingRepo) UpdatePollingCursor(ctx context.Context, sourceID uuid.UUID, componentConfigID uuid.UUID, cursor map[string]any) error {
	return nil
}

func (r *webhookRecordingRepo) FindByComponentConfig(ctx context.Context, componentConfigID uuid.UUID) (actiondomain.Source, error) {
	return actiondomain.Source{}, nil
}

func TestWebhookProvisioner_UpsertsWebhookSource(t *testing.T) {
	repo := &webhookRecordingRepo{}
	secretGen := func() (string, error) { return "generated-secret", nil }
	pathGen := func(area areadomain.Area) (string, error) { return "hooks/test", nil } // deterministic path
	prov := NewWebhookProvisioner(repo, secretGen, pathGen, stubClock{now: time.Unix(1720000000, 0).UTC()})

	configID := uuid.New()
	area := areadomain.Area{
		Status: areadomain.StatusEnabled,
		Action: &areadomain.Link{
			Config: componentdomain.Config{
				ID: configID,
				Component: &componentdomain.Component{
					Name:     "github_issue",
					Provider: componentdomain.Provider{Name: "github"},
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
	if !repo.webhookCalled {
		t.Fatalf("expected webhook provision to execute")
	}
	if repo.webhookInput.ComponentConfigID != configID {
		t.Fatalf("component config mismatch")
	}
	if repo.webhookInput.Secret != "generated-secret" {
		t.Fatalf("unexpected secret %s", repo.webhookInput.Secret)
	}
	if repo.webhookInput.Path != "hooks/test" {
		t.Fatalf("unexpected path %s", repo.webhookInput.Path)
	}
	if _, ok := repo.webhookInput.Cursor["created_at"]; !ok {
		t.Fatalf("expected cursor to contain created_at timestamp")
	}
}

func TestWebhookProvisioner_NoOpWhenNotWebhook(t *testing.T) {
	repo := &webhookRecordingRepo{}
	prov := NewWebhookProvisioner(repo, nil, nil, stubClock{now: time.Now().UTC()})

	area := areadomain.Area{
		Status: areadomain.StatusEnabled,
		Action: &areadomain.Link{
			Config: componentdomain.Config{
				ID: uuid.New(),
				Component: &componentdomain.Component{
					Metadata: map[string]any{
						"ingestion": map[string]any{
							"mode": "polling",
						},
					},
				},
			},
		},
	}

	if err := prov.Provision(context.Background(), area); err != nil {
		t.Fatalf("Provision returned error: %v", err)
	}
	if repo.webhookCalled {
		t.Fatalf("webhook provisioner should skip non-webhook components")
	}
}

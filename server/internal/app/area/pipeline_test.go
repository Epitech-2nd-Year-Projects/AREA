package area

import (
	"context"
	"strings"
	"testing"
	"time"

	actiondomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/action"
	areadomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/area"
	componentdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/component"
	jobdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/job"
	queueport "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound/queue"
	"github.com/google/uuid"
)

type fakeExecutionRepository struct {
	events   []actiondomain.Event
	triggers []actiondomain.Trigger
	jobs     []jobdomain.Job
}

func (f *fakeExecutionRepository) Create(ctx context.Context, event actiondomain.Event, triggers []actiondomain.Trigger, jobs []jobdomain.Job) (actiondomain.Event, []actiondomain.Trigger, []jobdomain.Job, error) {
	f.events = append(f.events, event)
	f.triggers = append(f.triggers, triggers...)
	f.jobs = append(f.jobs, jobs...)
	return event, triggers, jobs, nil
}

type recordingQueue struct {
	messages []queueport.JobMessage
}

func (r *recordingQueue) Enqueue(ctx context.Context, msg queueport.JobMessage) error {
	r.messages = append(r.messages, msg)
	return nil
}

func (r *recordingQueue) Reserve(context.Context, time.Duration) (queueport.Reservation, error) {
	return nil, queueport.ErrEmpty
}

func TestExecutionPipelineEnqueuePublishesJob(t *testing.T) {
	repo := &fakeExecutionRepository{}
	queue := &recordingQueue{}
	pipe := NewExecutionPipeline(repo, stubClock{now: time.Unix(1720000000, 0).UTC()}, queue)

	componentID := uuid.New()
	providerID := uuid.New()
	component := componentdomain.Component{
		ID:        componentID,
		Name:      "http_request",
		Provider:  componentdomain.Provider{ID: providerID, Name: "http"},
		Kind:      componentdomain.KindReaction,
		Enabled:   true,
		CreatedAt: time.Unix(1720000000, 0).UTC(),
		UpdatedAt: time.Unix(1720000000, 0).UTC(),
	}

	reactionLink := areadomain.Link{
		ID:   uuid.New(),
		Role: areadomain.LinkRoleReaction,
		Config: componentdomain.Config{
			ID:          uuid.New(),
			ComponentID: componentID,
			Component:   &component,
			Params:      map[string]any{"url": "https://example.com"},
			Active:      true,
			CreatedAt:   time.Unix(1720000000, 0).UTC(),
			UpdatedAt:   time.Unix(1720000000, 0).UTC(),
		},
		CreatedAt: time.Unix(1720000000, 0).UTC(),
		UpdatedAt: time.Unix(1720000000, 0).UTC(),
	}

	areaModel := areadomain.Area{
		ID:        uuid.New(),
		UserID:    uuid.New(),
		Name:      "Test area",
		CreatedAt: time.Unix(1720000000, 0).UTC(),
		UpdatedAt: time.Unix(1720000000, 0).UTC(),
		Action: &areadomain.Link{
			ID:   uuid.New(),
			Role: areadomain.LinkRoleAction,
			Config: componentdomain.Config{
				ID:          uuid.New(),
				ComponentID: uuid.New(),
				Component: &componentdomain.Component{
					ID:        uuid.New(),
					Name:      "timer_interval",
					Provider:  componentdomain.Provider{ID: uuid.New(), Name: "scheduler"},
					Kind:      componentdomain.KindAction,
					Enabled:   true,
					CreatedAt: time.Unix(1720000000, 0).UTC(),
					UpdatedAt: time.Unix(1720000000, 0).UTC(),
				},
				Params:    map[string]any{"frequencyValue": 1, "frequencyUnit": "hours"},
				Active:    true,
				CreatedAt: time.Unix(1720000000, 0).UTC(),
				UpdatedAt: time.Unix(1720000000, 0).UTC(),
			},
			CreatedAt: time.Unix(1720000000, 0).UTC(),
			UpdatedAt: time.Unix(1720000000, 0).UTC(),
		},
		Reactions: []areadomain.Link{reactionLink},
	}

	input := ExecutionInput{
		Area:     areaModel,
		SourceID: uuid.New(),
	}

	if err := pipe.Enqueue(context.Background(), input); err != nil {
		t.Fatalf("Enqueue returned error: %v", err)
	}

	if len(queue.messages) != 1 {
		t.Fatalf("expected one queue message, got %d", len(queue.messages))
	}
	storedJob := repo.jobs[0]
	if queue.messages[0].JobID != storedJob.ID {
		t.Fatalf("queue message job id mismatch")
	}
}

func TestExecutionPipelineMissingQueue(t *testing.T) {
	repo := &fakeExecutionRepository{}
	pipe := NewExecutionPipeline(repo, stubClock{now: time.Unix(1720000000, 0).UTC()}, nil)

	err := pipe.Enqueue(context.Background(), ExecutionInput{
		Area: areadomain.Area{
			ID: uuid.New(),
			Action: &areadomain.Link{
				Config: componentdomain.Config{ID: uuid.New()},
			},
			Reactions: []areadomain.Link{
				{ID: uuid.New()},
			},
		},
		SourceID: uuid.New(),
	})
	if err == nil {
		t.Fatalf("expected error when queue missing")
	}
	if !strings.Contains(err.Error(), "queue unavailable") {
		t.Fatalf("unexpected enqueue error: %v", err)
	}
}

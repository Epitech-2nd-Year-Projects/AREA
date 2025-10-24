package area

import (
	"context"
	"errors"
	"fmt"
	"time"

	actiondomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/action"
	areadomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/area"
	jobdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/job"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
	queueport "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound/queue"
	"github.com/google/uuid"
)

// ExecutionInput aggregates the data required to enqueue jobs for an AREA
type ExecutionInput struct {
	Area        areadomain.Area
	SourceID    uuid.UUID
	Payload     map[string]any
	Fingerprint string
	OccurredAt  time.Time
}

// ExecutionPipeline persists action events, triggers, and jobs
type ExecutionPipeline interface {
	Enqueue(ctx context.Context, input ExecutionInput) error
}

type dbExecutionPipeline struct {
	executions outbound.ExecutionRepository
	queue      queueport.JobProducer
	clock      Clock
}

// NewExecutionPipeline builds a pipeline backed by the provided execution repository
func NewExecutionPipeline(repo outbound.ExecutionRepository, clock Clock, producer queueport.JobProducer) ExecutionPipeline {
	if clock == nil {
		clock = systemClock{}
	}
	return &dbExecutionPipeline{
		executions: repo,
		queue:      producer,
		clock:      clock,
	}
}

func (p *dbExecutionPipeline) Enqueue(ctx context.Context, input ExecutionInput) error {
	if p == nil || p.executions == nil {
		return fmt.Errorf("area.ExecutionPipeline.Enqueue: repository unavailable")
	}
	if input.Area.ID == uuid.Nil {
		return fmt.Errorf("area.ExecutionPipeline.Enqueue: area id missing")
	}
	if input.SourceID == uuid.Nil {
		return fmt.Errorf("area.ExecutionPipeline.Enqueue: source id missing")
	}
	if input.Area.Action == nil || input.Area.Action.Config.ID == uuid.Nil {
		return fmt.Errorf("area.ExecutionPipeline.Enqueue: action config missing")
	}
	if len(input.Area.Reactions) == 0 {
		return fmt.Errorf("area.ExecutionPipeline.Enqueue: reactions missing")
	}

	now := p.clock.Now().UTC()
	occurredAt := input.OccurredAt.UTC()
	if occurredAt.IsZero() {
		occurredAt = now
	}
	fingerprint := input.Fingerprint
	if fingerprint == "" {
		fingerprint = uuid.NewString()
	}
	payload := cloneMap(input.Payload)
	payload["area_id"] = input.Area.ID.String()
	payload["source_id"] = input.SourceID.String()

	event := actiondomain.Event{
		ID:          uuid.New(),
		SourceID:    input.SourceID,
		OccurredAt:  occurredAt,
		ReceivedAt:  now,
		Fingerprint: fingerprint,
		Payload:     payload,
		DedupStatus: actiondomain.DedupStatusNew,
	}

	triggers := make([]actiondomain.Trigger, 0, 1)
	trigger := actiondomain.Trigger{
		ID:        uuid.New(),
		EventID:   event.ID,
		AreaID:    input.Area.ID,
		Status:    actiondomain.TriggerStatusMatched,
		CreatedAt: now,
		UpdatedAt: now,
	}
	triggers = append(triggers, trigger)

	jobs := make([]jobdomain.Job, 0, len(input.Area.Reactions))
	for _, reaction := range input.Area.Reactions {
		job := jobdomain.Job{
			ID:           uuid.New(),
			TriggerID:    trigger.ID,
			AreaLinkID:   reaction.ID,
			Status:       jobdomain.StatusQueued,
			Attempt:      0,
			RunAt:        now,
			InputPayload: buildJobInputPayload(input.Area, reaction, payload),
			CreatedAt:    now,
			UpdatedAt:    now,
		}
		jobs = append(jobs, job)
	}

	_, _, _, err := p.executions.Create(ctx, event, triggers, jobs)
	if err != nil {
		if errors.Is(err, outbound.ErrConflict) {
			return nil
		}
		return fmt.Errorf("area.ExecutionPipeline.Enqueue: %w", err)
	}
	if p.queue == nil {
		return fmt.Errorf("area.ExecutionPipeline.Enqueue: queue unavailable")
	}
	for _, job := range jobs {
		msg := queueport.JobMessage{
			JobID: job.ID,
			RunAt: job.RunAt,
		}
		if err := p.queue.Enqueue(ctx, msg); err != nil {
			return fmt.Errorf("area.ExecutionPipeline.Enqueue: queue enqueue: %w", err)
		}
	}
	return nil
}

func buildJobInputPayload(area areadomain.Area, reaction areadomain.Link, eventPayload map[string]any) map[string]any {
	payload := map[string]any{
		"areaId":       area.ID.String(),
		"userId":       area.UserID.String(),
		"areaName":     area.Name,
		"reactionId":   reaction.ID.String(),
		"componentId":  reaction.Config.ComponentID.String(),
		"params":       cloneMap(reaction.Config.Params),
		"eventPayload": cloneMap(eventPayload),
	}
	if reaction.Config.Component != nil {
		payload["componentName"] = reaction.Config.Component.Name
		payload["provider"] = reaction.Config.Component.Provider.Name
		payload["providerId"] = reaction.Config.Component.Provider.ID.String()
	}
	return payload
}

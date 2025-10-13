package automation

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/app/area"
	areadomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/area"
	componentdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/component"
	jobdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/job"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
	queueport "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound/queue"
	"github.com/google/uuid"
	"go.uber.org/zap"
)

// Clock abstracts time for deterministic testing
type Clock interface {
	Now() time.Time
}

type systemClock struct{}

func (systemClock) Now() time.Time { return time.Now().UTC() }

// Worker processes jobs fetched from the queue and executes their reactions
type Worker struct {
	queue       queueport.JobQueue
	jobs        outbound.JobRepository
	areas       *area.Service
	executor    *area.CompositeReactionExecutor
	logger      *zap.Logger
	clock       Clock
	workerID    string
	pollTimeout time.Duration
	backoff     time.Duration
}

// Option configures worker behavior
type Option func(*Worker)

// WithID overrides the worker identifier used for locking
func WithID(id string) Option {
	return func(w *Worker) {
		if strings.TrimSpace(id) != "" {
			w.workerID = id
		}
	}
}

// WithPollTimeout sets the blocking reserve timeout
func WithPollTimeout(timeout time.Duration) Option {
	return func(w *Worker) {
		if timeout > 0 {
			w.pollTimeout = timeout
		}
	}
}

// WithBackoff sets the delay used after transient errors
func WithBackoff(delay time.Duration) Option {
	return func(w *Worker) {
		if delay > 0 {
			w.backoff = delay
		}
	}
}

// WithClock injects a deterministic clock (useful for tests)
func WithClock(clock Clock) Option {
	return func(w *Worker) {
		if clock != nil {
			w.clock = clock
		}
	}
}

// NewWorker assembles a job worker from its dependencies
func NewWorker(queue queueport.JobQueue, jobs outbound.JobRepository, areas *area.Service, executor *area.CompositeReactionExecutor, logger *zap.Logger, opts ...Option) *Worker {
	if logger == nil {
		logger = zap.NewNop()
	}

	worker := &Worker{
		queue:       queue,
		jobs:        jobs,
		areas:       areas,
		executor:    executor,
		logger:      logger,
		clock:       systemClock{},
		workerID:    uuid.NewString(),
		pollTimeout: 5 * time.Second,
		backoff:     time.Second,
	}
	for _, opt := range opts {
		if opt != nil {
			opt(worker)
		}
	}
	return worker
}

// Run starts the worker loop until the context is cancelled
func (w *Worker) Run(ctx context.Context) {
	if w == nil || w.queue == nil || w.jobs == nil || w.executor == nil {
		return
	}

	for {
		if ctx.Err() != nil {
			return
		}
		reservation, err := w.queue.Reserve(ctx, w.pollTimeout)
		if err != nil {
			if errors.Is(err, queueport.ErrEmpty) {
				continue
			}
			if ctx.Err() != nil {
				return
			}
			w.logger.Error("queue reservation failed", zap.Error(err))
			select {
			case <-ctx.Done():
				return
			case <-time.After(w.backoff):
			}
			continue
		}
		if err := w.processReservation(ctx, reservation); err != nil {
			w.logger.Error("job processing failed", zap.Error(err))
		}
	}
}

func (w *Worker) processReservation(ctx context.Context, reservation queueport.Reservation) error {
	if reservation == nil {
		return fmt.Errorf("automation.Worker.processReservation: reservation missing")
	}
	msg := reservation.Message()
	if msg.JobID == uuid.Nil {
		if err := reservation.Ack(ctx); err != nil {
			return fmt.Errorf("automation.Worker.processReservation: ack missing job id: %w", err)
		}
		return fmt.Errorf("automation.Worker.processReservation: job id missing")
	}

	now := w.now()
	if !msg.RunAt.IsZero() && msg.RunAt.After(now) {
		delay := msg.RunAt.Sub(now)
		if err := reservation.Requeue(ctx, delay); err != nil {
			return fmt.Errorf("automation.Worker.processReservation: requeue future job: %w", err)
		}
		return nil
	}

	job, err := w.jobs.Claim(ctx, msg.JobID, w.workerID, now)
	if err != nil {
		if errors.Is(err, outbound.ErrNotFound) {
			if ackErr := reservation.Ack(ctx); ackErr != nil {
				return fmt.Errorf("automation.Worker.processReservation: ack missing job: %w", ackErr)
			}
			return nil
		}
		if ctx.Err() != nil {
			return ctx.Err()
		}
		if err := reservation.Requeue(ctx, w.backoff); err != nil {
			w.logger.Warn("failed to requeue job after claim error", zap.Error(err), zap.String("job_id", msg.JobID.String()))
		}
		return fmt.Errorf("automation.Worker.processReservation: claim job: %w", err)
	}

	if err := w.executeJob(ctx, job); err != nil {
		job.Status = jobdomain.StatusFailed
		errStr := err.Error()
		job.Error = &errStr
		job.LockedBy = nil
		job.LockedAt = nil
		job.UpdatedAt = now
		if updateErr := w.jobs.Update(ctx, job); updateErr != nil {
			return fmt.Errorf("automation.Worker.processReservation: update failed job: %w (original error: %v)", updateErr, err)
		}
		if ackErr := reservation.Ack(ctx); ackErr != nil {
			return fmt.Errorf("automation.Worker.processReservation: ack failed job: %w", ackErr)
		}
		return err
	}

	job.Status = jobdomain.StatusSucceeded
	job.Error = nil
	job.LockedBy = nil
	job.LockedAt = nil
	job.ResultPayload = map[string]any{
		"completedAt": w.now(),
	}
	job.UpdatedAt = w.now()
	if err := w.jobs.Update(ctx, job); err != nil {
		if requeueErr := reservation.Requeue(ctx, w.backoff); requeueErr != nil {
			w.logger.Warn("failed to requeue job after update error", zap.Error(requeueErr), zap.String("job_id", job.ID.String()))
		}
		return fmt.Errorf("automation.Worker.processReservation: update succeeded job: %w", err)
	}
	if err := reservation.Ack(ctx); err != nil {
		return fmt.Errorf("automation.Worker.processReservation: ack succeeded job: %w", err)
	}
	return nil
}

func (w *Worker) executeJob(ctx context.Context, job jobdomain.Job) error {
	if w.executor == nil {
		return fmt.Errorf("automation.Worker.executeJob: executor unavailable")
	}
	if w.areas == nil {
		return fmt.Errorf("automation.Worker.executeJob: area service unavailable")
	}

	payload := job.InputPayload
	areaID, err := parseUUIDField(payload, "areaId")
	if err != nil {
		return fmt.Errorf("automation.Worker.executeJob: %w", err)
	}
	userID, err := parseUUIDField(payload, "userId")
	if err != nil {
		return fmt.Errorf("automation.Worker.executeJob: %w", err)
	}
	reactionID, err := parseUUIDField(payload, "reactionId")
	if err != nil {
		return fmt.Errorf("automation.Worker.executeJob: %w", err)
	}

	areaModel, err := w.areas.Get(ctx, userID, areaID)
	if err != nil {
		return fmt.Errorf("automation.Worker.executeJob: load area: %w", err)
	}
	var reactionLink *areadomain.Link
	for idx := range areaModel.Reactions {
		if areaModel.Reactions[idx].ID == reactionID {
			reactionLink = &areaModel.Reactions[idx]
			break
		}
	}
	if reactionLink == nil {
		return fmt.Errorf("automation.Worker.executeJob: reaction %s not found for area %s", reactionID, areaID)
	}
	if reactionLink.Config.Component == nil {
		component := componentdomain.Component{
			ID: reactionLink.Config.ComponentID,
		}
		if name, ok := stringField(payload, "componentName"); ok {
			component.Name = name
		}
		if providerName, ok := stringField(payload, "provider"); ok {
			component.Provider.Name = providerName
		}
		if providerID, ok := stringField(payload, "providerId"); ok {
			if parsed, parseErr := uuid.Parse(providerID); parseErr == nil {
				component.Provider.ID = parsed
			}
		}
		reactionCopy := *reactionLink
		reactionCopy.Config.Component = &component
		reactionLink = &reactionCopy
	}

	if err := w.executor.ExecuteReaction(ctx, areaModel, *reactionLink); err != nil {
		return fmt.Errorf("automation.Worker.executeJob: execute reaction: %w", err)
	}
	return nil
}

func (w *Worker) now() time.Time {
	if w.clock == nil {
		return time.Now().UTC()
	}
	return w.clock.Now().UTC()
}

func parseUUIDField(payload map[string]any, key string) (uuid.UUID, error) {
	value, ok := stringField(payload, key)
	if !ok || strings.TrimSpace(value) == "" {
		return uuid.Nil, fmt.Errorf("missing field %q", key)
	}
	id, err := uuid.Parse(value)
	if err != nil {
		return uuid.Nil, fmt.Errorf("parse field %q: %w", key, err)
	}
	return id, nil
}

func stringField(payload map[string]any, key string) (string, bool) {
	if payload == nil {
		return "", false
	}
	value, ok := payload[key]
	if !ok {
		return "", false
	}
	switch v := value.(type) {
	case string:
		return v, true
	default:
		return fmt.Sprintf("%v", v), true
	}
}

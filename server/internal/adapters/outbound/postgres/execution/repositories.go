package execution

import (
	"context"
	"database/sql"
	"fmt"
	"strings"
	"time"

	actiondomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/action"
	jobdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/job"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

// EventRepository persists action events using Postgres
type EventRepository struct {
	db *gorm.DB
}

// NewEventRepository constructs an EventRepository backed by GORM
func NewEventRepository(db *gorm.DB) EventRepository {
	return EventRepository{db: db}
}

// Create stores a new action event
func (r EventRepository) Create(ctx context.Context, event actiondomain.Event) (actiondomain.Event, error) {
	if r.db == nil {
		return actiondomain.Event{}, fmt.Errorf("postgres.execution.EventRepository.Create: nil db handle")
	}

	model, err := eventFromDomain(event)
	if err != nil {
		return actiondomain.Event{}, fmt.Errorf("postgres.execution.EventRepository.Create: encode payload: %w", err)
	}
	if model.ID == uuid.Nil {
		model.ID = uuid.New()
	}
	if model.ReceivedAt.IsZero() {
		model.ReceivedAt = time.Now().UTC()
	}
	if model.OccurredAt.IsZero() {
		model.OccurredAt = model.ReceivedAt
	}
	if model.DedupStatus == "" {
		model.DedupStatus = string(actiondomain.DedupStatusNew)
	}

	if err := r.db.WithContext(ctx).Create(&model).Error; err != nil {
		return actiondomain.Event{}, fmt.Errorf("postgres.execution.EventRepository.Create: %w", err)
	}
	return model.toDomain(), nil
}

// TriggerRepository persists triggers using Postgres
type TriggerRepository struct {
	db *gorm.DB
}

// NewTriggerRepository constructs a TriggerRepository backed by GORM
func NewTriggerRepository(db *gorm.DB) TriggerRepository {
	return TriggerRepository{db: db}
}

// Create stores a single trigger row
func (r TriggerRepository) Create(ctx context.Context, trigger actiondomain.Trigger) (actiondomain.Trigger, error) {
	if r.db == nil {
		return actiondomain.Trigger{}, fmt.Errorf("postgres.execution.TriggerRepository.Create: nil db handle")
	}

	model, err := triggerFromDomain(trigger)
	if err != nil {
		return actiondomain.Trigger{}, fmt.Errorf("postgres.execution.TriggerRepository.Create: encode match info: %w", err)
	}
	if model.ID == uuid.Nil {
		model.ID = uuid.New()
	}
	now := time.Now().UTC()
	if model.CreatedAt.IsZero() {
		model.CreatedAt = now
	}
	if model.UpdatedAt.IsZero() {
		model.UpdatedAt = now
	}
	if model.Status == "" {
		model.Status = string(actiondomain.TriggerStatusPending)
	}

	if err := r.db.WithContext(ctx).Create(&model).Error; err != nil {
		return actiondomain.Trigger{}, fmt.Errorf("postgres.execution.TriggerRepository.Create: %w", err)
	}
	return model.toDomain(), nil
}

// CreateBatch stores multiple triggers in one statement
func (r TriggerRepository) CreateBatch(ctx context.Context, triggers []actiondomain.Trigger) ([]actiondomain.Trigger, error) {
	if r.db == nil {
		return nil, fmt.Errorf("postgres.execution.TriggerRepository.CreateBatch: nil db handle")
	}
	if len(triggers) == 0 {
		return []actiondomain.Trigger{}, nil
	}

	models := make([]triggerModel, 0, len(triggers))
	now := time.Now().UTC()
	for _, trigger := range triggers {
		model, err := triggerFromDomain(trigger)
		if err != nil {
			return nil, fmt.Errorf("postgres.execution.TriggerRepository.CreateBatch: encode match info: %w", err)
		}
		if model.ID == uuid.Nil {
			model.ID = uuid.New()
		}
		if model.CreatedAt.IsZero() {
			model.CreatedAt = now
		}
		if model.UpdatedAt.IsZero() {
			model.UpdatedAt = now
		}
		if model.Status == "" {
			model.Status = string(actiondomain.TriggerStatusPending)
		}
		models = append(models, model)
	}

	if err := r.db.WithContext(ctx).Create(&models).Error; err != nil {
		return nil, fmt.Errorf("postgres.execution.TriggerRepository.CreateBatch: %w", err)
	}

	result := make([]actiondomain.Trigger, 0, len(models))
	for _, model := range models {
		result = append(result, model.toDomain())
	}
	return result, nil
}

// JobRepository persists jobs using Postgres
type JobRepository struct {
	db *gorm.DB
}

// NewJobRepository constructs a JobRepository backed by GORM
func NewJobRepository(db *gorm.DB) JobRepository {
	return JobRepository{db: db}
}

// Create stores a single job row
func (r JobRepository) Create(ctx context.Context, job jobdomain.Job) (jobdomain.Job, error) {
	if r.db == nil {
		return jobdomain.Job{}, fmt.Errorf("postgres.execution.JobRepository.Create: nil db handle")
	}

	model, err := jobFromDomain(job)
	if err != nil {
		return jobdomain.Job{}, fmt.Errorf("postgres.execution.JobRepository.Create: encode payload: %w", err)
	}
	if model.ID == uuid.Nil {
		model.ID = uuid.New()
	}
	now := time.Now().UTC()
	if model.CreatedAt.IsZero() {
		model.CreatedAt = now
	}
	if model.UpdatedAt.IsZero() {
		model.UpdatedAt = now
	}
	if model.Status == "" {
		model.Status = string(jobdomain.StatusQueued)
	}
	if model.RunAt.IsZero() {
		model.RunAt = now
	}

	if err := r.db.WithContext(ctx).Create(&model).Error; err != nil {
		return jobdomain.Job{}, fmt.Errorf("postgres.execution.JobRepository.Create: %w", err)
	}
	return model.toDomain(), nil
}

// CreateBatch stores multiple jobs in a single statement
func (r JobRepository) CreateBatch(ctx context.Context, jobs []jobdomain.Job) ([]jobdomain.Job, error) {
	if r.db == nil {
		return nil, fmt.Errorf("postgres.execution.JobRepository.CreateBatch: nil db handle")
	}
	if len(jobs) == 0 {
		return []jobdomain.Job{}, nil
	}

	models := make([]jobModel, 0, len(jobs))
	now := time.Now().UTC()
	for _, job := range jobs {
		model, err := jobFromDomain(job)
		if err != nil {
			return nil, fmt.Errorf("postgres.execution.JobRepository.CreateBatch: encode payload: %w", err)
		}
		if model.ID == uuid.Nil {
			model.ID = uuid.New()
		}
		if model.CreatedAt.IsZero() {
			model.CreatedAt = now
		}
		if model.UpdatedAt.IsZero() {
			model.UpdatedAt = now
		}
		if model.Status == "" {
			model.Status = string(jobdomain.StatusQueued)
		}
		if model.RunAt.IsZero() {
			model.RunAt = now
		}
		models = append(models, model)
	}

	if err := r.db.WithContext(ctx).Create(&models).Error; err != nil {
		return nil, fmt.Errorf("postgres.execution.JobRepository.CreateBatch: %w", err)
	}

	result := make([]jobdomain.Job, 0, len(models))
	for _, model := range models {
		result = append(result, model.toDomain())
	}
	return result, nil
}

// Update persists mutable fields on a job record
func (r JobRepository) Update(ctx context.Context, job jobdomain.Job) error {
	if r.db == nil {
		return fmt.Errorf("postgres.execution.JobRepository.Update: nil db handle")
	}

	model, err := jobFromDomain(job)
	if err != nil {
		return fmt.Errorf("postgres.execution.JobRepository.Update: encode payload: %w", err)
	}
	if model.ID == uuid.Nil {
		return fmt.Errorf("postgres.execution.JobRepository.Update: missing id")
	}
	model.UpdatedAt = time.Now().UTC()

	updates := map[string]any{
		"status":         model.Status,
		"attempt":        model.Attempt,
		"run_at":         model.RunAt,
		"locked_by":      model.LockedBy,
		"locked_at":      model.LockedAt,
		"input_payload":  model.InputPayload,
		"result_payload": model.ResultPayload,
		"error":          model.Error,
		"updated_at":     model.UpdatedAt,
	}

	if err := r.db.WithContext(ctx).
		Model(&jobModel{}).
		Where("id = ?", model.ID).
		Updates(updates).Error; err != nil {
		return fmt.Errorf("postgres.execution.JobRepository.Update: %w", err)
	}
	return nil
}

// Claim transitions a queued job into the running state for the specified worker
func (r JobRepository) Claim(ctx context.Context, id uuid.UUID, worker string, now time.Time) (jobdomain.Job, error) {
	if r.db == nil {
		return jobdomain.Job{}, fmt.Errorf("postgres.execution.JobRepository.Claim: nil db handle")
	}
	if id == uuid.Nil {
		return jobdomain.Job{}, fmt.Errorf("postgres.execution.JobRepository.Claim: missing id")
	}
	if now.IsZero() {
		now = time.Now().UTC()
	}

	var model jobModel
	query := `
UPDATE jobs
SET status = ?, locked_by = ?, locked_at = ?, attempt = attempt + 1, updated_at = ?
WHERE id = ? AND status IN ('queued','retrying')
RETURNING *`
	lockedBy := sql.NullString{String: strings.TrimSpace(worker)}
	if lockedBy.String != "" {
		lockedBy.Valid = true
	}

	if err := r.db.WithContext(ctx).
		Raw(query,
			string(jobdomain.StatusRunning),
			lockedBy,
			now.UTC(),
			now.UTC(),
			id,
		).
		Scan(&model).Error; err != nil {
		return jobdomain.Job{}, fmt.Errorf("postgres.execution.JobRepository.Claim: update: %w", err)
	}
	if model.ID == uuid.Nil {
		return jobdomain.Job{}, outbound.ErrNotFound
	}
	return model.toDomain(), nil
}

// DeliveryLogRepository persists delivery logs using Postgres
type DeliveryLogRepository struct {
	db *gorm.DB
}

// NewDeliveryLogRepository constructs a DeliveryLogRepository backed by GORM
func NewDeliveryLogRepository(db *gorm.DB) DeliveryLogRepository {
	return DeliveryLogRepository{db: db}
}

// Create stores a delivery log row
func (r DeliveryLogRepository) Create(ctx context.Context, log jobdomain.DeliveryLog) (jobdomain.DeliveryLog, error) {
	if r.db == nil {
		return jobdomain.DeliveryLog{}, fmt.Errorf("postgres.execution.DeliveryLogRepository.Create: nil db handle")
	}

	model, err := deliveryLogFromDomain(log)
	if err != nil {
		return jobdomain.DeliveryLog{}, fmt.Errorf("postgres.execution.DeliveryLogRepository.Create: encode payload: %w", err)
	}
	if model.ID == uuid.Nil {
		model.ID = uuid.New()
	}
	if model.CreatedAt.IsZero() {
		model.CreatedAt = time.Now().UTC()
	}

	if err := r.db.WithContext(ctx).Create(&model).Error; err != nil {
		return jobdomain.DeliveryLog{}, fmt.Errorf("postgres.execution.DeliveryLogRepository.Create: %w", err)
	}
	return model.toDomain(), nil
}

var (
	_ outbound.ActionEventRepository = EventRepository{}
	_ outbound.TriggerRepository     = TriggerRepository{}
	_ outbound.JobRepository         = JobRepository{}
	_ outbound.DeliveryLogRepository = DeliveryLogRepository{}
)

// Manager orchestrates transactional persistence of events, triggers, and jobs
type Manager struct {
	db *gorm.DB
}

// NewManager constructs a Manager backed by GORM
func NewManager(db *gorm.DB) Manager {
	return Manager{db: db}
}

// Create persists the event, triggers, and jobs in a single transaction
func (m Manager) Create(ctx context.Context, event actiondomain.Event, triggers []actiondomain.Trigger, jobs []jobdomain.Job) (actiondomain.Event, []actiondomain.Trigger, []jobdomain.Job, error) {
	if m.db == nil {
		return actiondomain.Event{}, nil, nil, fmt.Errorf("postgres.execution.Manager.Create: nil db handle")
	}

	tx := m.db.WithContext(ctx).Begin()
	if err := tx.Error; err != nil {
		return actiondomain.Event{}, nil, nil, fmt.Errorf("postgres.execution.Manager.Create: begin tx: %w", err)
	}

	rollback := func(err error) (actiondomain.Event, []actiondomain.Trigger, []jobdomain.Job, error) {
		_ = tx.Rollback()
		return actiondomain.Event{}, nil, nil, err
	}

	eventRepo := NewEventRepository(tx)
	triggerRepo := NewTriggerRepository(tx)
	jobRepo := NewJobRepository(tx)

	storedEvent, err := eventRepo.Create(ctx, event)
	if err != nil {
		return rollback(fmt.Errorf("postgres.execution.Manager.Create: create event: %w", err))
	}

	storedTriggers, err := triggerRepo.CreateBatch(ctx, triggers)
	if err != nil {
		return rollback(fmt.Errorf("postgres.execution.Manager.Create: create triggers: %w", err))
	}

	storedJobs, err := jobRepo.CreateBatch(ctx, jobs)
	if err != nil {
		return rollback(fmt.Errorf("postgres.execution.Manager.Create: create jobs: %w", err))
	}

	if err := tx.Commit().Error; err != nil {
		return rollback(fmt.Errorf("postgres.execution.Manager.Create: commit: %w", err))
	}

	return storedEvent, storedTriggers, storedJobs, nil
}

var _ outbound.ExecutionRepository = Manager{}

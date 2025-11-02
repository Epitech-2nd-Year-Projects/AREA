package execution

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"strings"
	"time"

	actiondomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/action"
	jobdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/job"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
	"github.com/google/uuid"
	"gorm.io/datatypes"
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
		if isUniqueViolation(err) {
			return actiondomain.Event{}, outbound.ErrConflict
		}
		return actiondomain.Event{}, fmt.Errorf("postgres.execution.EventRepository.Create: %w", err)
	}
	return model.toDomain(), nil
}

func isUniqueViolation(err error) bool {
	if err == nil {
		return false
	}
	lowered := strings.ToLower(err.Error())
	return strings.Contains(lowered, "duplicate") || strings.Contains(lowered, "unique")
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

func valueOrDefault(input *string) string {
	if input == nil {
		return ""
	}
	return *input
}

// ListWithDetails returns recent jobs enriched with area and component metadata
func (r JobRepository) ListWithDetails(ctx context.Context, opts outbound.JobListOptions) ([]outbound.JobDetails, error) {
	if r.db == nil {
		return nil, fmt.Errorf("postgres.execution.JobRepository.ListWithDetails: nil db handle")
	}
	if opts.UserID == uuid.Nil {
		return nil, fmt.Errorf("postgres.execution.JobRepository.ListWithDetails: user id required")
	}
	limit := opts.Limit
	if limit <= 0 || limit > 200 {
		limit = 50
	}

	type jobWithDetails struct {
		JobID         uuid.UUID      `gorm:"column:job_id"`
		TriggerID     uuid.UUID      `gorm:"column:trigger_id"`
		AreaLinkID    uuid.UUID      `gorm:"column:area_link_id"`
		Status        string         `gorm:"column:status"`
		Attempt       int            `gorm:"column:attempt"`
		RunAt         time.Time      `gorm:"column:run_at"`
		LockedBy      *string        `gorm:"column:locked_by"`
		LockedAt      *time.Time     `gorm:"column:locked_at"`
		InputPayload  datatypes.JSON `gorm:"column:input_payload"`
		ResultPayload datatypes.JSON `gorm:"column:result_payload"`
		Error         *string        `gorm:"column:error"`
		CreatedAt     time.Time      `gorm:"column:created_at"`
		UpdatedAt     time.Time      `gorm:"column:updated_at"`
		AreaID        uuid.UUID      `gorm:"column:area_id"`
		AreaName      string         `gorm:"column:area_name"`
		ComponentName *string        `gorm:"column:component_name"`
		ProviderName  *string        `gorm:"column:provider_name"`
	}

	query := r.db.WithContext(ctx).
		Table("jobs AS j").
		Select(`
			j.id AS job_id,
			j.trigger_id,
			j.area_link_id,
			j.status,
			j.attempt,
			j.run_at,
			j.locked_by,
			j.locked_at,
			j.input_payload,
			j.result_payload,
			j.error,
			j.created_at,
			j.updated_at,
			l.area_id,
			a.name AS area_name,
			sc.display_name AS component_name,
			sp.display_name AS provider_name`).
		Joins("JOIN area_links l ON l.id = j.area_link_id").
		Joins("JOIN areas a ON a.id = l.area_id").
		Joins("LEFT JOIN user_component_configs cfg ON cfg.id = l.component_config_id").
		Joins("LEFT JOIN service_components sc ON sc.id = cfg.component_id").
		Joins("LEFT JOIN service_providers sp ON sp.id = sc.provider_id").
		Where("a.user_id = ?", opts.UserID)

	if opts.AreaID != uuid.Nil {
		query = query.Where("l.area_id = ?", opts.AreaID)
	}
	if opts.Status != nil && *opts.Status != "" {
		query = query.Where("j.status = ?", string(*opts.Status))
	}

	var rows []jobWithDetails
	if err := query.Order("j.created_at DESC").Limit(limit).Scan(&rows).Error; err != nil {
		return nil, fmt.Errorf("postgres.execution.JobRepository.ListWithDetails: %w", err)
	}

	results := make([]outbound.JobDetails, 0, len(rows))
	for _, row := range rows {
		model := jobModel{
			ID:            row.JobID,
			TriggerID:     row.TriggerID,
			AreaLinkID:    row.AreaLinkID,
			Status:        row.Status,
			Attempt:       row.Attempt,
			RunAt:         row.RunAt,
			LockedBy:      row.LockedBy,
			LockedAt:      row.LockedAt,
			InputPayload:  row.InputPayload,
			ResultPayload: row.ResultPayload,
			Error:         row.Error,
			CreatedAt:     row.CreatedAt,
			UpdatedAt:     row.UpdatedAt,
		}
		job := model.toDomain()
		details := outbound.JobDetails{
			Job:           job,
			AreaID:        row.AreaID,
			AreaName:      row.AreaName,
			ComponentName: valueOrDefault(row.ComponentName),
			ProviderName:  valueOrDefault(row.ProviderName),
		}
		results = append(results, details)
	}
	return results, nil
}

// FindDetails fetches a single job with area metadata ensuring ownership
func (r JobRepository) FindDetails(ctx context.Context, userID uuid.UUID, jobID uuid.UUID) (outbound.JobDetails, error) {
	if r.db == nil {
		return outbound.JobDetails{}, fmt.Errorf("postgres.execution.JobRepository.FindDetails: nil db handle")
	}
	if userID == uuid.Nil || jobID == uuid.Nil {
		return outbound.JobDetails{}, fmt.Errorf("postgres.execution.JobRepository.FindDetails: identifiers required")
	}

	type jobWithDetails struct {
		JobID         uuid.UUID      `gorm:"column:job_id"`
		TriggerID     uuid.UUID      `gorm:"column:trigger_id"`
		AreaLinkID    uuid.UUID      `gorm:"column:area_link_id"`
		Status        string         `gorm:"column:status"`
		Attempt       int            `gorm:"column:attempt"`
		RunAt         time.Time      `gorm:"column:run_at"`
		LockedBy      *string        `gorm:"column:locked_by"`
		LockedAt      *time.Time     `gorm:"column:locked_at"`
		InputPayload  datatypes.JSON `gorm:"column:input_payload"`
		ResultPayload datatypes.JSON `gorm:"column:result_payload"`
		Error         *string        `gorm:"column:error"`
		CreatedAt     time.Time      `gorm:"column:created_at"`
		UpdatedAt     time.Time      `gorm:"column:updated_at"`
		AreaID        uuid.UUID      `gorm:"column:area_id"`
		AreaName      string         `gorm:"column:area_name"`
		ComponentName *string        `gorm:"column:component_name"`
		ProviderName  *string        `gorm:"column:provider_name"`
	}

	var row jobWithDetails
	query := r.db.WithContext(ctx).
		Table("jobs AS j").
		Select(`
			j.id AS job_id,
			j.trigger_id,
			j.area_link_id,
			j.status,
			j.attempt,
			j.run_at,
			j.locked_by,
			j.locked_at,
			j.input_payload,
			j.result_payload,
			j.error,
			j.created_at,
			j.updated_at,
			l.area_id,
			a.name AS area_name,
			sc.display_name AS component_name,
			sp.display_name AS provider_name`).
		Joins("JOIN area_links l ON l.id = j.area_link_id").
		Joins("JOIN areas a ON a.id = l.area_id").
		Joins("LEFT JOIN user_component_configs cfg ON cfg.id = l.component_config_id").
		Joins("LEFT JOIN service_components sc ON sc.id = cfg.component_id").
		Joins("LEFT JOIN service_providers sp ON sp.id = sc.provider_id").
		Where("a.user_id = ? AND j.id = ?", userID, jobID)
	if err := query.Take(&row).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return outbound.JobDetails{}, outbound.ErrNotFound
		}
		return outbound.JobDetails{}, fmt.Errorf("postgres.execution.JobRepository.FindDetails: %w", err)
	}
	model := jobModel{
		ID:            row.JobID,
		TriggerID:     row.TriggerID,
		AreaLinkID:    row.AreaLinkID,
		Status:        row.Status,
		Attempt:       row.Attempt,
		RunAt:         row.RunAt,
		LockedBy:      row.LockedBy,
		LockedAt:      row.LockedAt,
		InputPayload:  row.InputPayload,
		ResultPayload: row.ResultPayload,
		Error:         row.Error,
		CreatedAt:     row.CreatedAt,
		UpdatedAt:     row.UpdatedAt,
	}
	job := model.toDomain()
	return outbound.JobDetails{
		Job:           job,
		AreaID:        row.AreaID,
		AreaName:      row.AreaName,
		ComponentName: valueOrDefault(row.ComponentName),
		ProviderName:  valueOrDefault(row.ProviderName),
	}, nil
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

// ListByJob returns recent delivery logs for the specified job
func (r DeliveryLogRepository) ListByJob(ctx context.Context, jobID uuid.UUID, limit int) ([]jobdomain.DeliveryLog, error) {
	if r.db == nil {
		return nil, fmt.Errorf("postgres.execution.DeliveryLogRepository.ListByJob: nil db handle")
	}
	if jobID == uuid.Nil {
		return nil, fmt.Errorf("postgres.execution.DeliveryLogRepository.ListByJob: job id missing")
	}
	if limit <= 0 || limit > 200 {
		limit = 50
	}

	var models []deliveryLogModel
	if err := r.db.WithContext(ctx).
		Where("job_id = ?", jobID).
		Order("created_at DESC").
		Limit(limit).
		Find(&models).Error; err != nil {
		return nil, fmt.Errorf("postgres.execution.DeliveryLogRepository.ListByJob: %w", err)
	}

	logs := make([]jobdomain.DeliveryLog, 0, len(models))
	for _, model := range models {
		logs = append(logs, model.toDomain())
	}
	return logs, nil
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

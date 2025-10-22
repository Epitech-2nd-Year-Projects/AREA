package action

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	actiondomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/action"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
	"github.com/google/uuid"
	"gorm.io/datatypes"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

// Repository persists action sources using Postgres via GORM
type Repository struct {
	db *gorm.DB
}

// NewRepository constructs a Repository backed by the provided gorm handle
func NewRepository(db *gorm.DB) Repository { return Repository{db: db} }

// UpsertScheduleSource inserts or updates a scheduled action source for the component configuration
func (r Repository) UpsertScheduleSource(ctx context.Context, componentConfigID uuid.UUID, schedule string, cursor map[string]any) (actiondomain.Source, error) {
	if r.db == nil {
		return actiondomain.Source{}, fmt.Errorf("postgres.action.Repository.UpsertScheduleSource: nil db handle")
	}
	if componentConfigID == uuid.Nil {
		return actiondomain.Source{}, fmt.Errorf("postgres.action.Repository.UpsertScheduleSource: missing component config id")
	}
	buffer, err := json.Marshal(cursor)
	if err != nil {
		return actiondomain.Source{}, fmt.Errorf("postgres.action.Repository.UpsertScheduleSource: marshal cursor: %w", err)
	}

	model := sourceModel{
		ID:                uuid.New(),
		ComponentConfigID: componentConfigID,
		Mode:              string(actiondomain.ModeSchedule),
		Cursor:            datatypes.JSON(buffer),
		Schedule:          &schedule,
		IsActive:          true,
	}

	if err := r.db.WithContext(ctx).
		Clauses(
			clause.OnConflict{
				Columns: []clause.Column{{Name: "component_config_id"}},
				TargetWhere: clause.Where{Exprs: []clause.Expression{
					clause.Eq{Column: clause.Column{Table: clause.CurrentTable, Name: "mode"}, Value: string(actiondomain.ModeSchedule)},
				}},
				DoUpdates: clause.Assignments(map[string]any{
					"mode":       string(actiondomain.ModeSchedule),
					"schedule":   schedule,
					"cursor":     datatypes.JSON(buffer),
					"is_active":  true,
					"updated_at": gorm.Expr("NOW()"),
				}),
			},
			clause.Returning{},
		).
		Create(&model).Error; err != nil {
		return actiondomain.Source{}, fmt.Errorf("postgres.action.Repository.UpsertScheduleSource: %w", err)
	}

	return model.toDomain(), nil
}

// UpsertPollingSource inserts or updates a polling action source for the component configuration
func (r Repository) UpsertPollingSource(ctx context.Context, componentConfigID uuid.UUID, cursor map[string]any) (actiondomain.Source, error) {
	if r.db == nil {
		return actiondomain.Source{}, fmt.Errorf("postgres.action.Repository.UpsertPollingSource: nil db handle")
	}
	if componentConfigID == uuid.Nil {
		return actiondomain.Source{}, fmt.Errorf("postgres.action.Repository.UpsertPollingSource: missing component config id")
	}
	buffer, err := json.Marshal(cursor)
	if err != nil {
		return actiondomain.Source{}, fmt.Errorf("postgres.action.Repository.UpsertPollingSource: marshal cursor: %w", err)
	}

	model := sourceModel{
		ID:                uuid.New(),
		ComponentConfigID: componentConfigID,
		Mode:              string(actiondomain.ModePolling),
		Cursor:            datatypes.JSON(buffer),
		IsActive:          true,
	}

	if err := r.db.WithContext(ctx).
		Clauses(
			clause.OnConflict{
				Columns: []clause.Column{{Name: "component_config_id"}},
				TargetWhere: clause.Where{Exprs: []clause.Expression{
					clause.Eq{Column: clause.Column{Table: clause.CurrentTable, Name: "mode"}, Value: string(actiondomain.ModePolling)},
				}},
				DoUpdates: clause.Assignments(map[string]any{
					"mode":             string(actiondomain.ModePolling),
					"cursor":           datatypes.JSON(buffer),
					"schedule":         gorm.Expr("NULL"),
					"webhook_secret":   gorm.Expr("NULL"),
					"webhook_url_path": gorm.Expr("NULL"),
					"is_active":        true,
					"updated_at":       gorm.Expr("NOW()"),
				}),
			},
			clause.Returning{},
		).
		Create(&model).Error; err != nil {
		return actiondomain.Source{}, fmt.Errorf("postgres.action.Repository.UpsertPollingSource: %w", err)
	}

	return model.toDomain(), nil
}

// UpsertWebhookSource inserts or updates a webhook-driven action source for the component configuration
func (r Repository) UpsertWebhookSource(ctx context.Context, componentConfigID uuid.UUID, secret string, urlPath string, cursor map[string]any) (actiondomain.Source, error) {
	if r.db == nil {
		return actiondomain.Source{}, fmt.Errorf("postgres.action.Repository.UpsertWebhookSource: nil db handle")
	}
	if componentConfigID == uuid.Nil {
		return actiondomain.Source{}, fmt.Errorf("postgres.action.Repository.UpsertWebhookSource: missing component config id")
	}
	if strings.TrimSpace(secret) == "" {
		return actiondomain.Source{}, fmt.Errorf("postgres.action.Repository.UpsertWebhookSource: secret empty")
	}
	if strings.TrimSpace(urlPath) == "" {
		return actiondomain.Source{}, fmt.Errorf("postgres.action.Repository.UpsertWebhookSource: url path empty")
	}

	buffer, err := json.Marshal(cursor)
	if err != nil {
		return actiondomain.Source{}, fmt.Errorf("postgres.action.Repository.UpsertWebhookSource: marshal cursor: %w", err)
	}

	model := sourceModel{
		ID:                uuid.New(),
		ComponentConfigID: componentConfigID,
		Mode:              string(actiondomain.ModeWebhook),
		Cursor:            datatypes.JSON(buffer),
		WebhookSecret:     &secret,
		WebhookURLPath:    &urlPath,
		IsActive:          true,
	}

	if err := r.db.WithContext(ctx).
		Clauses(
			clause.OnConflict{
				Columns: []clause.Column{{Name: "component_config_id"}},
				TargetWhere: clause.Where{Exprs: []clause.Expression{
					clause.Eq{Column: clause.Column{Table: clause.CurrentTable, Name: "mode"}, Value: string(actiondomain.ModeWebhook)},
				}},
				DoUpdates: clause.Assignments(map[string]any{
					"mode":             string(actiondomain.ModeWebhook),
					"cursor":           datatypes.JSON(buffer),
					"webhook_secret":   secret,
					"webhook_url_path": urlPath,
					"schedule":         gorm.Expr("NULL"),
					"is_active":        true,
					"updated_at":       gorm.Expr("NOW()"),
				}),
			},
			clause.Returning{},
		).
		Create(&model).Error; err != nil {
		return actiondomain.Source{}, fmt.Errorf("postgres.action.Repository.UpsertWebhookSource: %w", err)
	}

	return model.toDomain(), nil
}

// ListDueScheduleSources returns scheduled action bindings whose next run is before or equal to the provided instant
func (r Repository) ListDueScheduleSources(ctx context.Context, before time.Time, limit int) ([]actiondomain.ScheduleBinding, error) {
	if r.db == nil {
		return nil, fmt.Errorf("postgres.action.Repository.ListDueScheduleSources: nil db handle")
	}
	if limit <= 0 {
		limit = 25
	}

	query := `
SELECT
    s.id AS source_id,
    s.component_config_id,
    s.mode,
    s.cursor,
    s.schedule,
    s.is_active,
    s.created_at,
    s.updated_at,
    l.id AS area_link_id,
    l.area_id,
    a.user_id,
    ((s.cursor->>'next_run')::timestamptz) AS next_run,
    c.id AS config_id,
    c.user_id AS config_user_id,
    c.component_id AS config_component_id,
    c.name AS config_name,
    c.params AS config_params,
    c.secrets_ref AS config_secrets_ref,
    c.is_active AS config_is_active,
    c.created_at AS config_created_at,
    c.updated_at AS config_updated_at
FROM action_sources s
JOIN user_component_configs c ON c.id = s.component_config_id
JOIN area_links l ON l.component_config_id = c.id AND l.role = 'action'
JOIN areas a ON a.id = l.area_id
WHERE s.mode = 'schedule'
  AND s.is_active = TRUE
  AND c.is_active = TRUE
  AND a.status = 'enabled'
  AND (s.cursor->>'next_run') IS NOT NULL
  AND ((s.cursor->>'next_run')::timestamptz) <= ?
ORDER BY ((s.cursor->>'next_run')::timestamptz) ASC
LIMIT ?`

	var rows []scheduleBindingModel
	if err := r.db.WithContext(ctx).Raw(query, before.UTC(), limit).Scan(&rows).Error; err != nil {
		return nil, fmt.Errorf("postgres.action.Repository.ListDueScheduleSources: %w", err)
	}

	bindings := make([]actiondomain.ScheduleBinding, 0, len(rows))
	for _, row := range rows {
		binding, err := row.toDomain()
		if err != nil {
			return nil, fmt.Errorf("postgres.action.Repository.ListDueScheduleSources: decode row: %w", err)
		}
		if binding.NextRun.IsZero() {
			continue
		}
		bindings = append(bindings, binding)
	}
	return bindings, nil
}

// UpdateScheduleCursor persists a new cursor payload for the given source identifier
func (r Repository) UpdateScheduleCursor(ctx context.Context, sourceID uuid.UUID, componentConfigID uuid.UUID, cursor map[string]any) error {
	if r.db == nil {
		return fmt.Errorf("postgres.action.Repository.UpdateScheduleCursor: nil db handle")
	}
	if sourceID == uuid.Nil && componentConfigID == uuid.Nil {
		return fmt.Errorf("postgres.action.Repository.UpdateScheduleCursor: missing identifiers")
	}
	buffer, err := json.Marshal(cursor)
	if err != nil {
		return fmt.Errorf("postgres.action.Repository.UpdateScheduleCursor: marshal cursor: %w", err)
	}

	query := r.db.WithContext(ctx).
		Model(&sourceModel{})

	if sourceID != uuid.Nil {
		query = query.Where("id = ?", sourceID)
	} else {
		query = query.Where("component_config_id = ? AND mode = ?", componentConfigID, string(actiondomain.ModeSchedule))
	}

	result := query.Updates(map[string]any{
		"cursor":     datatypes.JSON(buffer),
		"updated_at": time.Now().UTC(),
	})
	if result.Error != nil {
		return fmt.Errorf("postgres.action.Repository.UpdateScheduleCursor: %w", result.Error)
	}
	if result.RowsAffected == 0 {
		return outbound.ErrNotFound
	}
	return nil
}

// FindByComponentConfig retrieves the action source associated with the component configuration
func (r Repository) FindByComponentConfig(ctx context.Context, componentConfigID uuid.UUID) (actiondomain.Source, error) {
	if r.db == nil {
		return actiondomain.Source{}, fmt.Errorf("postgres.action.Repository.FindByComponentConfig: nil db handle")
	}
	if componentConfigID == uuid.Nil {
		return actiondomain.Source{}, fmt.Errorf("postgres.action.Repository.FindByComponentConfig: missing component config id")
	}

	var model sourceModel
	if err := r.db.WithContext(ctx).
		Where("component_config_id = ?", componentConfigID).
		Order("created_at ASC").
		Take(&model).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return actiondomain.Source{}, outbound.ErrNotFound
		}
		return actiondomain.Source{}, fmt.Errorf("postgres.action.Repository.FindByComponentConfig: %w", err)
	}
	return model.toDomain(), nil
}

// ListDuePollingSources returns polling action bindings whose next run is before or equal to the provided instant
func (r Repository) ListDuePollingSources(ctx context.Context, before time.Time, limit int) ([]actiondomain.PollingBinding, error) {
	if r.db == nil {
		return nil, fmt.Errorf("postgres.action.Repository.ListDuePollingSources: nil db handle")
	}
	if limit <= 0 {
		limit = 25
	}

	query := `
SELECT
    s.id AS source_id,
    s.component_config_id,
    s.mode,
    s.cursor,
    s.is_active,
    s.created_at,
    s.updated_at,
    l.id AS area_link_id,
    l.area_id,
    a.user_id,
    ((s.cursor->>'next_run')::timestamptz) AS next_run,
    c.id AS config_id,
    c.user_id AS config_user_id,
    c.component_id AS config_component_id,
    c.name AS config_name,
    c.params AS config_params,
    c.secrets_ref AS config_secrets_ref,
    c.is_active AS config_is_active,
    c.created_at AS config_created_at,
    c.updated_at AS config_updated_at
FROM action_sources s
JOIN user_component_configs c ON c.id = s.component_config_id
JOIN area_links l ON l.component_config_id = c.id AND l.role = 'action'
JOIN areas a ON a.id = l.area_id
WHERE s.mode = 'polling'
  AND s.is_active = TRUE
  AND c.is_active = TRUE
  AND a.status = 'enabled'
  AND (s.cursor->>'next_run') IS NOT NULL
  AND ((s.cursor->>'next_run')::timestamptz) <= ?
ORDER BY ((s.cursor->>'next_run')::timestamptz) ASC
LIMIT ?`

	var rows []pollingBindingModel
	if err := r.db.WithContext(ctx).Raw(query, before.UTC(), limit).Scan(&rows).Error; err != nil {
		return nil, fmt.Errorf("postgres.action.Repository.ListDuePollingSources: %w", err)
	}

	bindings := make([]actiondomain.PollingBinding, 0, len(rows))
	for _, row := range rows {
		binding, err := row.toDomain()
		if err != nil {
			return nil, fmt.Errorf("postgres.action.Repository.ListDuePollingSources: decode row: %w", err)
		}
		if binding.NextRun.IsZero() {
			binding.NextRun = before.UTC()
		}
		bindings = append(bindings, binding)
	}
	return bindings, nil
}

// UpdatePollingCursor persists a new cursor payload for polling action sources
func (r Repository) UpdatePollingCursor(ctx context.Context, sourceID uuid.UUID, componentConfigID uuid.UUID, cursor map[string]any) error {
	if r.db == nil {
		return fmt.Errorf("postgres.action.Repository.UpdatePollingCursor: nil db handle")
	}
	if sourceID == uuid.Nil && componentConfigID == uuid.Nil {
		return fmt.Errorf("postgres.action.Repository.UpdatePollingCursor: missing identifiers")
	}
	buffer, err := json.Marshal(cursor)
	if err != nil {
		return fmt.Errorf("postgres.action.Repository.UpdatePollingCursor: marshal cursor: %w", err)
	}

	query := r.db.WithContext(ctx).
		Model(&sourceModel{})

	if sourceID != uuid.Nil {
		query = query.Where("id = ?", sourceID)
	} else {
		query = query.Where("component_config_id = ? AND mode = ?", componentConfigID, string(actiondomain.ModePolling))
	}

	result := query.Updates(map[string]any{
		"cursor":     datatypes.JSON(buffer),
		"updated_at": time.Now().UTC(),
	})
	if result.Error != nil {
		return fmt.Errorf("postgres.action.Repository.UpdatePollingCursor: %w", result.Error)
	}
	if result.RowsAffected == 0 {
		return outbound.ErrNotFound
	}
	return nil
}

// FindWebhookBindingByPath resolves a webhook source and its AREA metadata by path
func (r Repository) FindWebhookBindingByPath(ctx context.Context, path string) (actiondomain.WebhookBinding, error) {
	if r.db == nil {
		return actiondomain.WebhookBinding{}, fmt.Errorf("postgres.action.Repository.FindWebhookBindingByPath: nil db handle")
	}
	trimmed := strings.TrimSpace(path)
	if trimmed == "" {
		return actiondomain.WebhookBinding{}, outbound.ErrNotFound
	}

	query := `
SELECT
    s.id AS source_id,
    s.component_config_id,
    s.mode,
    s.cursor,
    s.webhook_secret,
    s.webhook_url_path,
    s.is_active,
    s.created_at,
    s.updated_at,
    l.id AS area_link_id,
    l.area_id,
    a.user_id
FROM action_sources s
JOIN user_component_configs c ON c.id = s.component_config_id
JOIN area_links l ON l.component_config_id = c.id AND l.role = 'action'
JOIN areas a ON a.id = l.area_id
WHERE s.mode = 'webhook'
  AND s.is_active = TRUE
  AND c.is_active = TRUE
  AND a.status = 'enabled'
  AND s.webhook_url_path = ?
LIMIT 1`

	var row webhookBindingModel
	if err := r.db.WithContext(ctx).Raw(query, trimmed).Scan(&row).Error; err != nil {
		return actiondomain.WebhookBinding{}, fmt.Errorf("postgres.action.Repository.FindWebhookBindingByPath: %w", err)
	}
	if row.SourceID == uuid.Nil {
		return actiondomain.WebhookBinding{}, outbound.ErrNotFound
	}

	binding, err := row.toDomain()
	if err != nil {
		return actiondomain.WebhookBinding{}, fmt.Errorf("postgres.action.Repository.FindWebhookBindingByPath: decode row: %w", err)
	}
	return binding, nil
}

// UpdateWebhookCursor persists auxiliary cursor metadata for webhook sources
func (r Repository) UpdateWebhookCursor(ctx context.Context, sourceID uuid.UUID, componentConfigID uuid.UUID, cursor map[string]any) error {
	if r.db == nil {
		return fmt.Errorf("postgres.action.Repository.UpdateWebhookCursor: nil db handle")
	}
	if sourceID == uuid.Nil && componentConfigID == uuid.Nil {
		return fmt.Errorf("postgres.action.Repository.UpdateWebhookCursor: missing identifiers")
	}
	buffer, err := json.Marshal(cursor)
	if err != nil {
		return fmt.Errorf("postgres.action.Repository.UpdateWebhookCursor: marshal cursor: %w", err)
	}

	query := r.db.WithContext(ctx).
		Model(&sourceModel{})

	if sourceID != uuid.Nil {
		query = query.Where("id = ?", sourceID)
	} else {
		query = query.Where("component_config_id = ? AND mode = ?", componentConfigID, string(actiondomain.ModeWebhook))
	}

	result := query.Updates(map[string]any{
		"cursor":     datatypes.JSON(buffer),
		"updated_at": time.Now().UTC(),
	})
	if result.Error != nil {
		return fmt.Errorf("postgres.action.Repository.UpdateWebhookCursor: %w", result.Error)
	}
	if result.RowsAffected == 0 {
		return outbound.ErrNotFound
	}
	return nil
}

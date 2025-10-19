package action

import (
	"encoding/json"
	"time"

	actiondomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/action"
	componentdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/component"
	"github.com/google/uuid"
	"gorm.io/datatypes"
)

type sourceModel struct {
	ID                uuid.UUID      `gorm:"column:id;type:uuid;default:gen_random_uuid();primaryKey"`
	ComponentConfigID uuid.UUID      `gorm:"column:component_config_id"`
	Mode              string         `gorm:"column:mode"`
	Cursor            datatypes.JSON `gorm:"column:cursor"`
	WebhookSecret     *string        `gorm:"column:webhook_secret"`
	WebhookURLPath    *string        `gorm:"column:webhook_url_path"`
	Schedule          *string        `gorm:"column:schedule"`
	IsActive          bool           `gorm:"column:is_active"`
	CreatedAt         time.Time      `gorm:"column:created_at"`
	UpdatedAt         time.Time      `gorm:"column:updated_at"`
}

func (sourceModel) TableName() string { return "action_sources" }

func (m sourceModel) toDomain() actiondomain.Source {
	var cursor map[string]any
	if len(m.Cursor) > 0 {
		_ = json.Unmarshal(m.Cursor, &cursor)
	}
	return actiondomain.Source{
		ID:                m.ID,
		ComponentConfigID: m.ComponentConfigID,
		Mode:              actiondomain.Mode(m.Mode),
		Cursor:            cursor,
		WebhookSecret:     m.WebhookSecret,
		WebhookURLPath:    m.WebhookURLPath,
		Schedule:          m.Schedule,
		IsActive:          m.IsActive,
		CreatedAt:         m.CreatedAt,
		UpdatedAt:         m.UpdatedAt,
	}
}

type scheduleBindingModel struct {
	SourceID          uuid.UUID      `gorm:"column:source_id"`
	ComponentConfigID uuid.UUID      `gorm:"column:component_config_id"`
	Mode              string         `gorm:"column:mode"`
	Cursor            datatypes.JSON `gorm:"column:cursor"`
	Schedule          *string        `gorm:"column:schedule"`
	IsActive          bool           `gorm:"column:is_active"`
	CreatedAt         time.Time      `gorm:"column:created_at"`
	UpdatedAt         time.Time      `gorm:"column:updated_at"`
	AreaID            uuid.UUID      `gorm:"column:area_id"`
	AreaLinkID        uuid.UUID      `gorm:"column:area_link_id"`
	UserID            uuid.UUID      `gorm:"column:user_id"`
	NextRun           time.Time      `gorm:"column:next_run"`
	ConfigID          uuid.UUID      `gorm:"column:config_id"`
	ConfigUserID      uuid.UUID      `gorm:"column:config_user_id"`
	ConfigComponentID uuid.UUID      `gorm:"column:config_component_id"`
	ConfigName        *string        `gorm:"column:config_name"`
	ConfigParams      datatypes.JSON `gorm:"column:config_params"`
	ConfigSecretsRef  *string        `gorm:"column:config_secrets_ref"`
	ConfigIsActive    bool           `gorm:"column:config_is_active"`
	ConfigCreatedAt   time.Time      `gorm:"column:config_created_at"`
	ConfigUpdatedAt   time.Time      `gorm:"column:config_updated_at"`
}

func (m scheduleBindingModel) toDomain() (actiondomain.ScheduleBinding, error) {
	source := actiondomain.Source{
		ID:                m.SourceID,
		ComponentConfigID: m.ComponentConfigID,
		Mode:              actiondomain.Mode(m.Mode),
		Schedule:          m.Schedule,
		IsActive:          m.IsActive,
		CreatedAt:         m.CreatedAt,
		UpdatedAt:         m.UpdatedAt,
	}
	if len(m.Cursor) > 0 {
		var cursor map[string]any
		if err := json.Unmarshal(m.Cursor, &cursor); err != nil {
			return actiondomain.ScheduleBinding{}, err
		}
		source.Cursor = cursor
	}
	params := map[string]any{}
	if len(m.ConfigParams) > 0 {
		if err := json.Unmarshal(m.ConfigParams, &params); err != nil {
			return actiondomain.ScheduleBinding{}, err
		}
	}
	config := componentdomain.Config{
		ID:          m.ConfigID,
		UserID:      m.ConfigUserID,
		ComponentID: m.ConfigComponentID,
		Params:      params,
		SecretsRef:  m.ConfigSecretsRef,
		Active:      m.ConfigIsActive,
		CreatedAt:   m.ConfigCreatedAt,
		UpdatedAt:   m.ConfigUpdatedAt,
	}
	if m.ConfigName != nil {
		config.Name = *m.ConfigName
	}
	return actiondomain.ScheduleBinding{
		Source:     source,
		AreaID:     m.AreaID,
		AreaLinkID: m.AreaLinkID,
		UserID:     m.UserID,
		NextRun:    m.NextRun,
		Config:     config,
	}, nil
}

type pollingBindingModel struct {
	SourceID          uuid.UUID      `gorm:"column:source_id"`
	ComponentConfigID uuid.UUID      `gorm:"column:component_config_id"`
	Mode              string         `gorm:"column:mode"`
	Cursor            datatypes.JSON `gorm:"column:cursor"`
	IsActive          bool           `gorm:"column:is_active"`
	CreatedAt         time.Time      `gorm:"column:created_at"`
	UpdatedAt         time.Time      `gorm:"column:updated_at"`
	AreaID            uuid.UUID      `gorm:"column:area_id"`
	AreaLinkID        uuid.UUID      `gorm:"column:area_link_id"`
	UserID            uuid.UUID      `gorm:"column:user_id"`
	NextRun           time.Time      `gorm:"column:next_run"`
	ConfigID          uuid.UUID      `gorm:"column:config_id"`
	ConfigUserID      uuid.UUID      `gorm:"column:config_user_id"`
	ConfigComponentID uuid.UUID      `gorm:"column:config_component_id"`
	ConfigName        *string        `gorm:"column:config_name"`
	ConfigParams      datatypes.JSON `gorm:"column:config_params"`
	ConfigSecretsRef  *string        `gorm:"column:config_secrets_ref"`
	ConfigIsActive    bool           `gorm:"column:config_is_active"`
	ConfigCreatedAt   time.Time      `gorm:"column:config_created_at"`
	ConfigUpdatedAt   time.Time      `gorm:"column:config_updated_at"`
}

func (m pollingBindingModel) toDomain() (actiondomain.PollingBinding, error) {
	source := actiondomain.Source{
		ID:                m.SourceID,
		ComponentConfigID: m.ComponentConfigID,
		Mode:              actiondomain.Mode(m.Mode),
		IsActive:          m.IsActive,
		CreatedAt:         m.CreatedAt,
		UpdatedAt:         m.UpdatedAt,
	}
	if len(m.Cursor) > 0 {
		var cursor map[string]any
		if err := json.Unmarshal(m.Cursor, &cursor); err != nil {
			return actiondomain.PollingBinding{}, err
		}
		source.Cursor = cursor
	}
	params := map[string]any{}
	if len(m.ConfigParams) > 0 {
		if err := json.Unmarshal(m.ConfigParams, &params); err != nil {
			return actiondomain.PollingBinding{}, err
		}
	}
	config := componentdomain.Config{
		ID:          m.ConfigID,
		UserID:      m.ConfigUserID,
		ComponentID: m.ConfigComponentID,
		Params:      params,
		SecretsRef:  m.ConfigSecretsRef,
		Active:      m.ConfigIsActive,
		CreatedAt:   m.ConfigCreatedAt,
		UpdatedAt:   m.ConfigUpdatedAt,
	}
	if m.ConfigName != nil {
		config.Name = *m.ConfigName
	}
	return actiondomain.PollingBinding{
		Source:     source,
		AreaID:     m.AreaID,
		AreaLinkID: m.AreaLinkID,
		UserID:     m.UserID,
		NextRun:    m.NextRun,
		Config:     config,
	}, nil
}

type webhookBindingModel struct {
	SourceID          uuid.UUID      `gorm:"column:source_id"`
	ComponentConfigID uuid.UUID      `gorm:"column:component_config_id"`
	Mode              string         `gorm:"column:mode"`
	Cursor            datatypes.JSON `gorm:"column:cursor"`
	WebhookSecret     *string        `gorm:"column:webhook_secret"`
	WebhookURLPath    *string        `gorm:"column:webhook_url_path"`
	IsActive          bool           `gorm:"column:is_active"`
	CreatedAt         time.Time      `gorm:"column:created_at"`
	UpdatedAt         time.Time      `gorm:"column:updated_at"`
	AreaID            uuid.UUID      `gorm:"column:area_id"`
	AreaLinkID        uuid.UUID      `gorm:"column:area_link_id"`
	UserID            uuid.UUID      `gorm:"column:user_id"`
}

func (m webhookBindingModel) toDomain() (actiondomain.WebhookBinding, error) {
	source := actiondomain.Source{
		ID:                m.SourceID,
		ComponentConfigID: m.ComponentConfigID,
		Mode:              actiondomain.Mode(m.Mode),
		Cursor:            nil,
		WebhookSecret:     m.WebhookSecret,
		WebhookURLPath:    m.WebhookURLPath,
		IsActive:          m.IsActive,
		CreatedAt:         m.CreatedAt,
		UpdatedAt:         m.UpdatedAt,
	}
	if len(m.Cursor) > 0 {
		var cursor map[string]any
		if err := json.Unmarshal(m.Cursor, &cursor); err != nil {
			return actiondomain.WebhookBinding{}, err
		}
		source.Cursor = cursor
	}
	return actiondomain.WebhookBinding{
		Source:     source,
		AreaID:     m.AreaID,
		AreaLinkID: m.AreaLinkID,
		UserID:     m.UserID,
	}, nil
}

package area

import (
	"encoding/json"
	"strings"
	"time"

	areadomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/area"
	componentdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/component"
	"github.com/google/uuid"
	"gorm.io/datatypes"
)

type areaModel struct {
	ID          uuid.UUID `gorm:"column:id;type:uuid;primaryKey"`
	UserID      uuid.UUID `gorm:"column:user_id"`
	Name        string    `gorm:"column:name"`
	Description *string   `gorm:"column:description"`
	Status      string    `gorm:"column:status"`
	CreatedAt   time.Time `gorm:"column:created_at"`
	UpdatedAt   time.Time `gorm:"column:updated_at"`
	Links       []areaLinkModel
}

func (areaModel) TableName() string { return "areas" }

type areaLinkModel struct {
	ID                uuid.UUID `gorm:"column:id;primaryKey"`
	AreaID            uuid.UUID `gorm:"column:area_id"`
	Role              string    `gorm:"column:role"`
	ComponentConfigID uuid.UUID `gorm:"column:component_config_id"`
	Position          int       `gorm:"column:position"`
	RetryPolicy       []byte    `gorm:"column:retry_policy"`
	CreatedAt         time.Time `gorm:"column:created_at"`
	UpdatedAt         time.Time `gorm:"column:updated_at"`
	ComponentConfig   componentConfigModel
}

func (areaLinkModel) TableName() string { return "area_links" }

type componentConfigModel struct {
	ID          uuid.UUID      `gorm:"column:id;primaryKey"`
	UserID      uuid.UUID      `gorm:"column:user_id"`
	ComponentID uuid.UUID      `gorm:"column:component_id"`
	Name        *string        `gorm:"column:name"`
	Params      datatypes.JSON `gorm:"column:params"`
	SecretsRef  *string        `gorm:"column:secrets_ref"`
	IsActive    bool           `gorm:"column:is_active"`
	CreatedAt   time.Time      `gorm:"column:created_at"`
	UpdatedAt   time.Time      `gorm:"column:updated_at"`
}

func (componentConfigModel) TableName() string { return "user_component_configs" }

func (m areaModel) toDomain() areadomain.Area {
	area := areadomain.Area{
		ID:          m.ID,
		UserID:      m.UserID,
		Name:        m.Name,
		Description: m.Description,
		Status:      areadomain.Status(m.Status),
		CreatedAt:   m.CreatedAt,
		UpdatedAt:   m.UpdatedAt,
	}
	for _, linkModel := range m.Links {
		link, err := linkModel.toDomain()
		if err != nil {
			continue
		}
		if link.IsAction() {
			link.AreaID = area.ID
			area.Action = &link
			continue
		}
		link.AreaID = area.ID
		area.Reactions = append(area.Reactions, link)
	}
	return area
}

func areaFromDomain(area areadomain.Area) areaModel {
	return areaModel{
		ID:          area.ID,
		UserID:      area.UserID,
		Name:        area.Name,
		Description: area.Description,
		Status:      string(area.Status),
		CreatedAt:   area.CreatedAt,
		UpdatedAt:   area.UpdatedAt,
	}
}

func linkFromDomain(link areadomain.Link) areaLinkModel {
	return areaLinkModel{
		ID:                link.ID,
		AreaID:            link.AreaID,
		Role:              string(link.Role),
		ComponentConfigID: link.Config.ID,
		Position:          link.Position,
		CreatedAt:         link.CreatedAt,
		UpdatedAt:         link.UpdatedAt,
	}
}

func (m areaLinkModel) toDomain() (areadomain.Link, error) {
	config, err := m.ComponentConfig.toDomain()
	if err != nil {
		return areadomain.Link{}, err
	}
	return areadomain.Link{
		ID:        m.ID,
		AreaID:    m.AreaID,
		Role:      areadomain.LinkRole(m.Role),
		Position:  m.Position,
		Config:    config,
		CreatedAt: m.CreatedAt,
		UpdatedAt: m.UpdatedAt,
	}, nil
}

func configFromDomain(cfg componentdomain.Config) (componentConfigModel, error) {
	params := cfg.Params
	if params == nil {
		params = map[string]any{}
	}
	encoded, err := json.Marshal(params)
	if err != nil {
		return componentConfigModel{}, err
	}

	model := componentConfigModel{
		ID:          cfg.ID,
		UserID:      cfg.UserID,
		ComponentID: cfg.ComponentID,
		Params:      datatypes.JSON(encoded),
		SecretsRef:  cfg.SecretsRef,
		IsActive:    cfg.Active,
		CreatedAt:   cfg.CreatedAt,
		UpdatedAt:   cfg.UpdatedAt,
	}
	if trimmed := strings.TrimSpace(cfg.Name); trimmed != "" {
		name := trimmed
		model.Name = &name
	}
	return model, nil
}

func (m componentConfigModel) toDomain() (componentdomain.Config, error) {
	params := map[string]any{}
	if len(m.Params) > 0 {
		if err := json.Unmarshal(m.Params, &params); err != nil {
			return componentdomain.Config{}, err
		}
	}
	config := componentdomain.Config{
		ID:          m.ID,
		UserID:      m.UserID,
		ComponentID: m.ComponentID,
		Params:      params,
		SecretsRef:  m.SecretsRef,
		Active:      m.IsActive,
		CreatedAt:   m.CreatedAt,
		UpdatedAt:   m.UpdatedAt,
	}
	if m.Name != nil {
		config.Name = *m.Name
	}
	return config, nil
}

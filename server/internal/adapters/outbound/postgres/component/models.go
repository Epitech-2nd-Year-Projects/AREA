package component

import (
	"encoding/json"
	"time"

	componentdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/component"
	"github.com/google/uuid"
	"gorm.io/datatypes"
)

type componentModel struct {
	ID          uuid.UUID      `gorm:"column:id;primaryKey"`
	ProviderID  uuid.UUID      `gorm:"column:provider_id"`
	Kind        string         `gorm:"column:kind"`
	Name        string         `gorm:"column:name"`
	DisplayName string         `gorm:"column:display_name"`
	Description *string        `gorm:"column:description"`
	Version     int            `gorm:"column:version"`
	Metadata    datatypes.JSON `gorm:"column:metadata"`
	IsEnabled   bool           `gorm:"column:is_enabled"`
	CreatedAt   time.Time      `gorm:"column:created_at"`
	UpdatedAt   time.Time      `gorm:"column:updated_at"`
	Provider    providerModel
}

func (componentModel) TableName() string { return "service_components" }

type providerModel struct {
	ID          uuid.UUID `gorm:"column:id;primaryKey"`
	Name        string    `gorm:"column:name"`
	DisplayName string    `gorm:"column:display_name"`
}

func (providerModel) TableName() string { return "service_providers" }

func (m componentModel) toDomain() componentdomain.Component {
	component := componentdomain.Component{
		ID:          m.ID,
		ProviderID:  m.ProviderID,
		Kind:        componentdomain.Kind(m.Kind),
		Name:        m.Name,
		DisplayName: m.DisplayName,
		Version:     m.Version,
		Enabled:     m.IsEnabled,
		CreatedAt:   m.CreatedAt,
		UpdatedAt:   m.UpdatedAt,
	}
	if m.Description != nil {
		component.Description = *m.Description
	}
	if len(m.Metadata) > 0 {
		var metadata map[string]any
		if err := json.Unmarshal(m.Metadata, &metadata); err == nil {
			component.Metadata = metadata
		}
	}
	component.Provider = componentdomain.Provider{
		ID:          m.Provider.ID,
		Name:        m.Provider.Name,
		DisplayName: m.Provider.DisplayName,
	}
	return component
}

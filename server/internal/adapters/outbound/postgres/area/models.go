package area

import (
	"time"

	areadomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/area"
	"github.com/google/uuid"
)

type areaModel struct {
	ID          uuid.UUID `gorm:"column:id;type:uuid;primaryKey"`
	UserID      uuid.UUID `gorm:"column:user_id"`
	Name        string    `gorm:"column:name"`
	Description *string   `gorm:"column:description"`
	Status      string    `gorm:"column:status"`
	CreatedAt   time.Time `gorm:"column:created_at"`
	UpdatedAt   time.Time `gorm:"column:updated_at"`
}

func (areaModel) TableName() string { return "areas" }

func (m areaModel) toDomain() areadomain.Area {
	return areadomain.Area{
		ID:          m.ID,
		UserID:      m.UserID,
		Name:        m.Name,
		Description: m.Description,
		Status:      areadomain.Status(m.Status),
		CreatedAt:   m.CreatedAt,
		UpdatedAt:   m.UpdatedAt,
	}
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

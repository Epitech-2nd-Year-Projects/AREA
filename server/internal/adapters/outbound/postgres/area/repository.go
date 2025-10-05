package area

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	areadomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/area"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Repository persists AREA entities using Postgres via GORM
type Repository struct {
	db *gorm.DB
}

// NewRepository constructs a Repository backed by the provided gorm handle
func NewRepository(db *gorm.DB) Repository {
	return Repository{db: db}
}

// Create inserts a new area row and returns the stored aggregate
func (r Repository) Create(ctx context.Context, area areadomain.Area) (areadomain.Area, error) {
	if r.db == nil {
		return areadomain.Area{}, fmt.Errorf("postgres.area.Repository.Create: nil db handle")
	}
	model := areaFromDomain(area)
	if model.ID == uuid.Nil {
		model.ID = uuid.New()
	}
	if model.CreatedAt.IsZero() {
		model.CreatedAt = time.Now().UTC()
	}
	if model.UpdatedAt.IsZero() {
		model.UpdatedAt = model.CreatedAt
	}
	if err := r.db.WithContext(ctx).Create(&model).Error; err != nil {
		if isUniqueViolation(err) {
			return areadomain.Area{}, outbound.ErrConflict
		}
		return areadomain.Area{}, fmt.Errorf("postgres.area.Repository.Create: %w", err)
	}
	return model.toDomain(), nil
}

// FindByID retrieves an area by its identifier
func (r Repository) FindByID(ctx context.Context, id uuid.UUID) (areadomain.Area, error) {
	if r.db == nil {
		return areadomain.Area{}, fmt.Errorf("postgres.area.Repository.FindByID: nil db handle")
	}
	var model areaModel
	if err := r.db.WithContext(ctx).First(&model, "id = ?", id).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return areadomain.Area{}, outbound.ErrNotFound
		}
		return areadomain.Area{}, fmt.Errorf("postgres.area.Repository.FindByID: %w", err)
	}
	return model.toDomain(), nil
}

// ListByUser returns all areas for the specified user ordered by creation date descending
func (r Repository) ListByUser(ctx context.Context, userID uuid.UUID) ([]areadomain.Area, error) {
	if r.db == nil {
		return nil, fmt.Errorf("postgres.area.Repository.ListByUser: nil db handle")
	}
	var models []areaModel
	if err := r.db.WithContext(ctx).
		Where("user_id = ?", userID).
		Order("created_at DESC").
		Find(&models).Error; err != nil {
		return nil, fmt.Errorf("postgres.area.Repository.ListByUser: %w", err)
	}
	areas := make([]areadomain.Area, 0, len(models))
	for _, model := range models {
		areas = append(areas, model.toDomain())
	}
	return areas, nil
}

func isUniqueViolation(err error) bool {
	return err != nil && strings.Contains(strings.ToLower(err.Error()), "duplicate")
}

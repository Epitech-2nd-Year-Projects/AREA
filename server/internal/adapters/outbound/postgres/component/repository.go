package component

import (
	"context"
	"fmt"

	componentdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/component"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Repository exposes Postgres-backed component lookups
type Repository struct {
	db *gorm.DB
}

// NewRepository constructs a Repository bound to the provided gorm handle
func NewRepository(db *gorm.DB) Repository {
	return Repository{db: db}
}

// FindByID retrieves a single component with its provider metadata
func (r Repository) FindByID(ctx context.Context, id uuid.UUID) (componentdomain.Component, error) {
	if r.db == nil {
		return componentdomain.Component{}, fmt.Errorf("postgres.component.Repository.FindByID: nil db handle")
	}
	var model componentModel
	if err := r.db.WithContext(ctx).
		Preload("Provider").
		First(&model, "id = ?", id).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return componentdomain.Component{}, outbound.ErrNotFound
		}
		return componentdomain.Component{}, fmt.Errorf("postgres.component.Repository.FindByID: %w", err)
	}
	return model.toDomain(), nil
}

// FindByIDs fetches components for the provided identifiers and returns a map keyed by ID
func (r Repository) FindByIDs(ctx context.Context, ids []uuid.UUID) (map[uuid.UUID]componentdomain.Component, error) {
	result := make(map[uuid.UUID]componentdomain.Component, len(ids))
	if len(ids) == 0 {
		return result, nil
	}
	if r.db == nil {
		return nil, fmt.Errorf("postgres.component.Repository.FindByIDs: nil db handle")
	}
	var models []componentModel
	if err := r.db.WithContext(ctx).
		Preload("Provider").
		Find(&models, "id IN ?", ids).Error; err != nil {
		return nil, fmt.Errorf("postgres.component.Repository.FindByIDs: %w", err)
	}
	for _, model := range models {
		component := model.toDomain()
		result[component.ID] = component
	}
	return result, nil
}

package component

import (
	"context"
	"errors"
	"fmt"
	"strings"

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
		if errors.Is(err, gorm.ErrRecordNotFound) {
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

// List returns components filtered by the provided options
func (r Repository) List(ctx context.Context, opts outbound.ComponentListOptions) ([]componentdomain.Component, error) {
	if r.db == nil {
		return nil, fmt.Errorf("postgres.component.Repository.List: nil db handle")
	}

	var models []componentModel
	query := r.db.WithContext(ctx).
		Preload("Provider").
		Where("service_components.is_enabled = ?", true)

	if opts.Kind != nil {
		query = query.Where("kind = ?", string(*opts.Kind))
	}
	if trimmed := strings.TrimSpace(strings.ToLower(opts.Provider)); trimmed != "" {
		query = query.Joins("JOIN service_providers ON service_providers.id = service_components.provider_id").
			Where("service_providers.name = ?", trimmed)
	}

	if err := query.Order("display_name ASC").Find(&models).Error; err != nil {
		return nil, fmt.Errorf("postgres.component.Repository.List: %w", err)
	}

	components := make([]componentdomain.Component, 0, len(models))
	for _, model := range models {
		components = append(components, model.toDomain())
	}
	return components, nil
}

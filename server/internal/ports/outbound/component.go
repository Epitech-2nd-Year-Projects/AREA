package outbound

import (
	"context"

	componentdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/component"
	"github.com/google/uuid"
)

// ComponentRepository exposes catalog lookups for service components
type ComponentRepository interface {
	FindByID(ctx context.Context, id uuid.UUID) (componentdomain.Component, error)
	FindByIDs(ctx context.Context, ids []uuid.UUID) (map[uuid.UUID]componentdomain.Component, error)
	List(ctx context.Context, opts ComponentListOptions) ([]componentdomain.Component, error)
}

// ComponentListOptions filters component catalog listings
type ComponentListOptions struct {
	Kind     *componentdomain.Kind
	Provider string
}

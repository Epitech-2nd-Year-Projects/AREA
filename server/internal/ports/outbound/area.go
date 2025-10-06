package outbound

import (
	"context"

	areadomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/area"
	"github.com/google/uuid"
)

// AreaRepository persists AREA automations for a user
type AreaRepository interface {
	Create(ctx context.Context, area areadomain.Area, action areadomain.Link, reactions []areadomain.Link) (areadomain.Area, error)
	FindByID(ctx context.Context, id uuid.UUID) (areadomain.Area, error)
	ListByUser(ctx context.Context, userID uuid.UUID) ([]areadomain.Area, error)
	Delete(ctx context.Context, id uuid.UUID) error
}

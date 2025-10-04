package identity

import (
	"context"

	identitydomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/identity"
	"github.com/google/uuid"
)

// Repository persists linked OAuth identities and their tokens
type Repository interface {
	Create(ctx context.Context, identity identitydomain.Identity) (identitydomain.Identity, error)
	Update(ctx context.Context, identity identitydomain.Identity) error
	FindByID(ctx context.Context, id uuid.UUID) (identitydomain.Identity, error)
	FindByUserAndProvider(ctx context.Context, userID uuid.UUID, provider string) (identitydomain.Identity, error)
	FindByProviderSubject(ctx context.Context, provider string, subject string) (identitydomain.Identity, error)
	ListByUser(ctx context.Context, userID uuid.UUID) ([]identitydomain.Identity, error)
	Delete(ctx context.Context, id uuid.UUID) error
}

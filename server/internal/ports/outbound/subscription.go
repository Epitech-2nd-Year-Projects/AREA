package outbound

import (
	"context"

	subscriptiondomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/subscription"
	"github.com/google/uuid"
)

// SubscriptionRepository persists user-service subscription relationships.
type SubscriptionRepository interface {
	Create(ctx context.Context, subscription subscriptiondomain.Subscription) (subscriptiondomain.Subscription, error)
	Update(ctx context.Context, subscription subscriptiondomain.Subscription) error
	FindByUserAndProvider(ctx context.Context, userID uuid.UUID, providerID uuid.UUID) (subscriptiondomain.Subscription, error)
	ListByUser(ctx context.Context, userID uuid.UUID) ([]subscriptiondomain.Subscription, error)
}

package outbound

import (
	"context"

	servicedomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/service"
)

// ServiceProviderRepository exposes lookups for service providers present in the catalog.
type ServiceProviderRepository interface {
	FindByName(ctx context.Context, name string) (servicedomain.Provider, error)
}

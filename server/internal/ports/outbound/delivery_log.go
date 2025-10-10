package outbound

import (
	"context"

	jobdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/job"
)

// DeliveryLogRepository persists HTTP delivery traces for executed jobs
type DeliveryLogRepository interface {
	Create(ctx context.Context, log jobdomain.DeliveryLog) (jobdomain.DeliveryLog, error)
}

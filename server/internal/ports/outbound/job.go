package outbound

import (
	"context"
	"time"

	jobdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/job"
	"github.com/google/uuid"
)

// JobRepository persists reaction jobs derived from triggers
type JobRepository interface {
	Create(ctx context.Context, job jobdomain.Job) (jobdomain.Job, error)
	CreateBatch(ctx context.Context, jobs []jobdomain.Job) ([]jobdomain.Job, error)
	Update(ctx context.Context, job jobdomain.Job) error
	Claim(ctx context.Context, id uuid.UUID, worker string, now time.Time) (jobdomain.Job, error)
}

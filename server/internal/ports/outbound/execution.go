package outbound

import (
	"context"

	actiondomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/action"
	jobdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/job"
)

// ExecutionRepository persists action events, triggers, and jobs in a single transaction
type ExecutionRepository interface {
	Create(ctx context.Context, event actiondomain.Event, triggers []actiondomain.Trigger, jobs []jobdomain.Job) (actiondomain.Event, []actiondomain.Trigger, []jobdomain.Job, error)
}

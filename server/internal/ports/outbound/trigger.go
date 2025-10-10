package outbound

import (
	"context"

	actiondomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/action"
)

// TriggerRepository persists trigger rows derived from action events
type TriggerRepository interface {
	Create(ctx context.Context, trigger actiondomain.Trigger) (actiondomain.Trigger, error)
	CreateBatch(ctx context.Context, triggers []actiondomain.Trigger) ([]actiondomain.Trigger, error)
}

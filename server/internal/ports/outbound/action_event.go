package outbound

import (
	"context"

	actiondomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/action"
)

// ActionEventRepository persists action events produced by action sources
type ActionEventRepository interface {
	Create(ctx context.Context, event actiondomain.Event) (actiondomain.Event, error)
}

package outbound

import (
	"context"

	areadomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/area"
)

// ReactionExecutor executes a reaction link for a given area
type ReactionExecutor interface {
	ExecuteReaction(ctx context.Context, area areadomain.Area, link areadomain.Link) error
}

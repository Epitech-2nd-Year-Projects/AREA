package outbound

import (
	"context"
	"time"

	areadomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/area"
)

// ReactionResult captures the outcome of executing a reaction
type ReactionResult struct {
	Endpoint   string
	Request    map[string]any
	Response   map[string]any
	StatusCode *int
	Duration   time.Duration
}

// ReactionExecutor executes a reaction link for a given area
type ReactionExecutor interface {
	ExecuteReaction(ctx context.Context, area areadomain.Area, link areadomain.Link) (ReactionResult, error)
}

package area

import (
	"context"
	"fmt"

	areadomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/area"
	componentdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/component"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
	"go.uber.org/zap"
)

// ComponentReactionHandler dispatches reactions for specific components
type ComponentReactionHandler interface {
	Supports(component *componentdomain.Component) bool
	Execute(ctx context.Context, area areadomain.Area, link areadomain.Link) (outbound.ReactionResult, error)
}

// CompositeReactionExecutor routes reaction execution across component-specific handlers
type CompositeReactionExecutor struct {
	handlers []ComponentReactionHandler
	fallback outbound.ReactionExecutor
	logger   *zap.Logger
}

// NewCompositeReactionExecutor assembles a composite executor
func NewCompositeReactionExecutor(fallback outbound.ReactionExecutor, logger *zap.Logger, handlers ...ComponentReactionHandler) *CompositeReactionExecutor {
	if logger == nil {
		logger = zap.NewNop()
	}
	return &CompositeReactionExecutor{handlers: handlers, fallback: fallback, logger: logger}
}

// ExecuteReaction dispatches the reaction to the first supporting handler or fallback
func (c *CompositeReactionExecutor) ExecuteReaction(ctx context.Context, area areadomain.Area, link areadomain.Link) (outbound.ReactionResult, error) {
	component := link.Config.Component
	for _, handler := range c.handlers {
		if handler != nil && handler.Supports(component) {
			return handler.Execute(ctx, area, link)
		}
	}
	if c.fallback != nil {
		return c.fallback.ExecuteReaction(ctx, area, link)
	}
	name := ""
	if component != nil {
		name = component.Name
	}
	return outbound.ReactionResult{}, fmt.Errorf("area.CompositeReactionExecutor: component %q unsupported", name)
}

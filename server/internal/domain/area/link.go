package area

import (
	"time"

	componentdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/component"
	"github.com/google/uuid"
)

// LinkRole describes how a component participates in an AREA
type LinkRole string

const (
	// LinkRoleAction identifies the trigger component of an automation
	LinkRoleAction LinkRole = "action"
	// LinkRoleReaction identifies a downstream reaction component
	LinkRoleReaction LinkRole = "reaction"
)

// Link binds an AREA to a configured component (action or reaction)
type Link struct {
	ID        uuid.UUID
	AreaID    uuid.UUID
	Role      LinkRole
	Position  int
	Config    componentdomain.Config
	CreatedAt time.Time
	UpdatedAt time.Time
}

// IsAction reports whether the link represents the AREA trigger
func (l Link) IsAction() bool {
	return l.Role == LinkRoleAction
}

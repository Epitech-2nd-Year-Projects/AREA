package area

import (
	"strings"
	"time"

	"github.com/google/uuid"
)

// Status mirrors the area_status enum from the persistence layer
type Status string

const (
	// StatusEnabled indicates the automation is active and should run
	StatusEnabled Status = "enabled"
	// StatusDisabled prevents the automation from executing while retaining configuration
	StatusDisabled Status = "disabled"
	// StatusArchived marks the automation as read-only and hidden from default listings
	StatusArchived Status = "archived"
)

// Area represents an automation composed of an action and one or more reactions
type Area struct {
	ID          uuid.UUID
	UserID      uuid.UUID
	Name        string
	Description *string
	Status      Status
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

// WithDescription returns a copy of the area with the provided description applied
func (a Area) WithDescription(description string) Area {
	if strings.TrimSpace(description) == "" {
		a.Description = nil
		return a
	}
	desc := description
	a.Description = &desc
	return a
}

// OwnedBy reports whether the area belongs to the provided user
func (a Area) OwnedBy(userID uuid.UUID) bool {
	return a.UserID == userID
}

// WithStatus returns a copy of the area carrying the provided status
func (a Area) WithStatus(status Status) Area {
	a.Status = status
	return a
}

// WithTimestamps sets the created and updated timestamps if provided
func (a Area) WithTimestamps(created time.Time, updated time.Time) Area {
	a.CreatedAt = created
	a.UpdatedAt = updated
	return a
}

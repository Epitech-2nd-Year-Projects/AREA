package component

import (
	"time"

	"github.com/google/uuid"
)

// Config stores user-specific configuration for a component
type Config struct {
	ID          uuid.UUID
	UserID      uuid.UUID
	ComponentID uuid.UUID
	Name        string
	Params      map[string]any
	SecretsRef  *string
	Active      bool
	CreatedAt   time.Time
	UpdatedAt   time.Time
	Component   *Component
}

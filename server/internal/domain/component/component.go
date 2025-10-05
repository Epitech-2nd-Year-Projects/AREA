package component

import (
	"time"

	"github.com/google/uuid"
)

// Kind enumerates the supported component roles exposed by services
type Kind string

const (
	// KindAction represents an action component (trigger)
	KindAction Kind = "action"
	// KindReaction represents a reaction component (effect)
	KindReaction Kind = "reaction"
)

// Provider describes a third-party integration exposing components
type Provider struct {
	ID          uuid.UUID
	Name        string
	DisplayName string
}

// Component captures catalog metadata for an action or reaction
type Component struct {
	ID          uuid.UUID
	ProviderID  uuid.UUID
	Provider    Provider
	Kind        Kind
	Name        string
	DisplayName string
	Description string
	Version     int
	Enabled     bool
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

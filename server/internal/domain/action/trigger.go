package action

import (
	"time"

	"github.com/google/uuid"
)

// TriggerStatus mirrors the trigger_status enum in the database
type TriggerStatus string

const (
	// TriggerStatusPending indicates that conditions have not been evaluated yet
	TriggerStatusPending TriggerStatus = "pending"
	// TriggerStatusMatched indicates that the trigger matched the automation conditions
	TriggerStatusMatched TriggerStatus = "matched"
	// TriggerStatusFiltered indicates that the trigger was filtered out by conditions
	TriggerStatusFiltered TriggerStatus = "filtered"
	// TriggerStatusFailed indicates that evaluation failed
	TriggerStatusFailed TriggerStatus = "failed"
)

// Trigger ties an action event to a concrete AREA
type Trigger struct {
	ID        uuid.UUID
	EventID   uuid.UUID
	AreaID    uuid.UUID
	Status    TriggerStatus
	MatchInfo map[string]any
	CreatedAt time.Time
	UpdatedAt time.Time
}

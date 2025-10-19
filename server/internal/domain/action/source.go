package action

import (
	"time"

	componentdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/component"
	"github.com/google/uuid"
)

// Mode enumerates action source execution strategies
type Mode string

const (
	// ModeWebhook is used for webhook-driven actions
	ModeWebhook Mode = "webhook"
	// ModePolling is used for polling actions
	ModePolling Mode = "polling"
	// ModeSchedule is used for scheduled actions
	ModeSchedule Mode = "schedule"
)

// Source models the persistence layer representation of an action source
type Source struct {
	ID                uuid.UUID
	ComponentConfigID uuid.UUID
	Mode              Mode
	Cursor            map[string]any
	WebhookSecret     *string
	WebhookURLPath    *string
	Schedule          *string
	IsActive          bool
	CreatedAt         time.Time
	UpdatedAt         time.Time
}

// ScheduleBinding associates a scheduled action source with its AREA metadata
type ScheduleBinding struct {
	Source     Source
	AreaID     uuid.UUID
	AreaLinkID uuid.UUID
	UserID     uuid.UUID
	NextRun    time.Time
	Config     componentdomain.Config
}

// PollingBinding associates a polling action source with its AREA metadata
type PollingBinding struct {
	Source     Source
	AreaID     uuid.UUID
	AreaLinkID uuid.UUID
	UserID     uuid.UUID
	NextRun    time.Time
	Config     componentdomain.Config
}

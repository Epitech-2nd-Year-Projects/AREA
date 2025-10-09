package job

import (
	"time"

	"github.com/google/uuid"
)

// Status mirrors the job_status enum in the database
type Status string

const (
	// StatusQueued indicates that the job is ready to be processed
	StatusQueued Status = "queued"
	// StatusRunning indicates that the job is currently being processed
	StatusRunning Status = "running"
	// StatusSucceeded indicates that the job completed successfully
	StatusSucceeded Status = "succeeded"
	// StatusFailed indicates that the job finished with a non-retriable error
	StatusFailed Status = "failed"
	// StatusCanceled indicates that the job was canceled by the system or user
	StatusCanceled Status = "canceled"
	// StatusRetrying indicates that the job will be retried
	StatusRetrying Status = "retrying"
)

// Job represents the execution of one reaction for one trigger
type Job struct {
	ID            uuid.UUID
	TriggerID     uuid.UUID
	AreaLinkID    uuid.UUID
	Status        Status
	Attempt       int
	RunAt         time.Time
	LockedBy      *string
	LockedAt      *time.Time
	InputPayload  map[string]any
	ResultPayload map[string]any
	Error         *string
	CreatedAt     time.Time
	UpdatedAt     time.Time
}

// DeliveryLog captures the HTTP request/response performed while processing a job
type DeliveryLog struct {
	ID         uuid.UUID
	JobID      uuid.UUID
	Endpoint   string
	Request    map[string]any
	Response   map[string]any
	StatusCode *int
	DurationMS *int
	CreatedAt  time.Time
}

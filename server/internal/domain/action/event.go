package action

import (
	"time"

	"github.com/google/uuid"
)

// DedupStatus mirrors the dedup_status enum in the database
type DedupStatus string

const (
	// DedupStatusNew marks events that have not been processed yet
	DedupStatusNew DedupStatus = "new"
	// DedupStatusDuplicate marks events that were ignored because they were seen before
	DedupStatusDuplicate DedupStatus = "duplicate"
	// DedupStatusIgnored marks events skipped by upstream filters
	DedupStatusIgnored DedupStatus = "ignored"
)

// Event captures an incoming action occurrence recorded from an action source
type Event struct {
	ID          uuid.UUID
	SourceID    uuid.UUID
	OccurredAt  time.Time
	ReceivedAt  time.Time
	Fingerprint string
	Payload     map[string]any
	DedupStatus DedupStatus
}

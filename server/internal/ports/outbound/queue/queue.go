package queue

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

// JobMessage represents a job scheduled for execution
type JobMessage struct {
	JobID uuid.UUID
	RunAt time.Time
}

// Reservation represents a leased job fetched from the queue
type Reservation interface {
	// Message returns the leased job payload
	Message() JobMessage
	// Ack marks the reservation as processed, removing it from the queue
	Ack(ctx context.Context) error
	// Requeue releases the reservation back to the queue after the given delay
	Requeue(ctx context.Context, delay time.Duration) error
}

// JobProducer enqueues jobs for later processing
type JobProducer interface {
	Enqueue(ctx context.Context, msg JobMessage) error
}

// JobConsumer leases jobs for execution
type JobConsumer interface {
	Reserve(ctx context.Context, timeout time.Duration) (Reservation, error)
}

// JobQueue combines producer and consumer capabilities
type JobQueue interface {
	JobProducer
	JobConsumer
}

// ErrEmpty signals that no job was available before the timeout expired
var ErrEmpty = errors.New("queue: empty")

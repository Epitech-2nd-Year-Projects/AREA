package outbound

import "errors"

var (
	// ErrNotFound indicates that the requested record does not exist
	ErrNotFound = errors.New("outbound: not found")

	// ErrConflict signals that the requested operation violates a unique constraint
	ErrConflict = errors.New("outbound: conflict")
)

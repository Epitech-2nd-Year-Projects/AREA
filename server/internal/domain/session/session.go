package session

import (
	"time"

	"github.com/google/uuid"
)

// Session represents a browser session backed by a persistent store
type Session struct {
	ID        uuid.UUID
	UserID    uuid.UUID
	IssuedAt  time.Time
	ExpiresAt time.Time
	RevokedAt *time.Time
	IP        string
	UserAgent string
	// AuthProvider identifies the mechanism that issued the session such as password or provider slug
	AuthProvider string
}

// Active reports whether the session can still be used for authentication
func (s Session) Active(now time.Time) bool {
	if s.RevokedAt != nil {
		return false
	}
	return now.Before(s.ExpiresAt)
}

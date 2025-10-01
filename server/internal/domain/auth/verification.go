package auth

import (
	"time"

	"github.com/google/uuid"
)

// VerificationToken represents a single-use email confirmation token
type VerificationToken struct {
	ID        uuid.UUID
	UserID    uuid.UUID
	Token     string
	ExpiresAt time.Time
	Consumed  *time.Time
	CreatedAt time.Time
}

// Expired reports if the token lifetime elapsed relative to the provided instant
func (t VerificationToken) Expired(now time.Time) bool {
	return now.After(t.ExpiresAt)
}

// Used reports if the token was already consumed
func (t VerificationToken) Used() bool {
	return t.Consumed != nil
}

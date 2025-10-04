package identity

import (
	"time"

	"github.com/google/uuid"
)

// Identity models an external OAuth account linked to an AREA user
type Identity struct {
	ID           uuid.UUID
	UserID       uuid.UUID
	Provider     string
	Subject      string
	AccessToken  string
	RefreshToken string
	Scopes       []string
	ExpiresAt    *time.Time
	CreatedAt    time.Time
	UpdatedAt    time.Time
}

// TokenExpired reports whether the access token is expired relative to now
func (i Identity) TokenExpired(now time.Time) bool {
	if i.ExpiresAt == nil {
		return false
	}

	return !i.ExpiresAt.After(now)
}

// WithTokens returns an updated copy with new OAuth token data applied
func (i Identity) WithTokens(accessToken string, refreshToken string, expiresAt *time.Time, scopes []string) Identity {
	clone := i
	clone.AccessToken = accessToken
	clone.RefreshToken = refreshToken
	clone.ExpiresAt = expiresAt
	clone.Scopes = scopes
	return clone
}

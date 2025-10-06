package subscription

import (
	"time"

	"github.com/google/uuid"
)

// Status captures the lifecycle state of a user service subscription.
type Status string

const (
	// StatusActive indicates the user has granted access to the service.
	StatusActive Status = "active"
	// StatusRevoked indicates access has been explicitly revoked by the user.
	StatusRevoked Status = "revoked"
	// StatusExpired indicates the authorisation expired and needs renewal.
	StatusExpired Status = "expired"
	// StatusNeedsConsent indicates the service requires additional user consent.
	StatusNeedsConsent Status = "needs_consent"
)

// Subscription links an AREA user to a service provider authorisation.
type Subscription struct {
	ID          uuid.UUID
	UserID      uuid.UUID
	ProviderID  uuid.UUID
	IdentityID  *uuid.UUID
	Status      Status
	ScopeGrants []string
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

// WithIdentity returns a shallow copy with the linked identity updated.
func (s Subscription) WithIdentity(identityID uuid.UUID) Subscription {
	clone := s
	clone.IdentityID = &identityID
	return clone
}

// WithScopes returns a shallow copy with the granted scopes updated.
func (s Subscription) WithScopes(scopes []string) Subscription {
	clone := s
	clone.ScopeGrants = append([]string(nil), scopes...)
	return clone
}

package user

import (
	"time"

	"github.com/google/uuid"
)

// Status represents the lifecycle stage of an account
// Values mirror the user_status enum in the database
// Keep in sync with migrations/000001_create_enums_core.up.sql
type Status string

const (
	StatusPending   Status = "pending"
	StatusActive    Status = "active"
	StatusSuspended Status = "suspended"
	StatusDeleted   Status = "deleted"
)

// Role identifies the set of permissions granted to an account
type Role string

const (
	RoleMember Role = "member"
	RoleAdmin  Role = "admin"
)

// User models an AREA account holder
// Business logic should prefer this type over persistence models
type User struct {
	ID           uuid.UUID
	Email        string
	PasswordHash string
	Status       Status
	Role         Role
	CreatedAt    time.Time
	UpdatedAt    time.Time
	LastLoginAt  *time.Time
}

// Active reports whether the user can authenticate into the platform
func (u User) Active() bool {
	return u.Status == StatusActive
}

// PendingVerification indicates if the user must confirm their email before usage
func (u User) PendingVerification() bool {
	return u.Status == StatusPending
}

// IsAdmin reports whether the user holds administrative privileges
func (u User) IsAdmin() bool {
	return u.Role == RoleAdmin
}

// WithPasswordHash returns a copy with the provided password hash set
func (u User) WithPasswordHash(hash string) User {
	u.PasswordHash = hash
	return u
}

// WithStatus returns a copy with the desired status
func (u User) WithStatus(status Status) User {
	u.Status = status
	return u
}

// WithLastLogin updates the last login timestamp
func (u User) WithLastLogin(ts time.Time) User {
	u.LastLoginAt = &ts
	return u
}

// WithRole returns a copy with the desired role
func (u User) WithRole(role Role) User {
	u.Role = role
	return u
}

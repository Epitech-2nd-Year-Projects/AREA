package auth

import (
	"time"

	authdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/auth"
	identitydomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/identity"
	sessiondomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/session"
	userdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/user"
	"github.com/google/uuid"
	"github.com/lib/pq"
)

type userModel struct {
	ID           uuid.UUID  `gorm:"column:id;type:uuid;primaryKey"`
	Email        string     `gorm:"column:email"`
	PasswordHash string     `gorm:"column:password_hash"`
	Status       string     `gorm:"column:status"`
	Role         string     `gorm:"column:role"`
	CreatedAt    time.Time  `gorm:"column:created_at"`
	UpdatedAt    time.Time  `gorm:"column:updated_at"`
	LastLoginAt  *time.Time `gorm:"column:last_login_at"`
}

func (userModel) TableName() string { return "users" }

func (m userModel) toDomain() userdomain.User {
	role := userdomain.Role(m.Role)
	if role == "" {
		role = userdomain.RoleMember
	}

	return userdomain.User{
		ID:           m.ID,
		Email:        m.Email,
		PasswordHash: m.PasswordHash,
		Status:       userdomain.Status(m.Status),
		Role:         role,
		CreatedAt:    m.CreatedAt,
		UpdatedAt:    m.UpdatedAt,
		LastLoginAt:  m.LastLoginAt,
	}
}

func userFromDomain(u userdomain.User) userModel {
	role := u.Role
	if role == "" {
		role = userdomain.RoleMember
	}

	return userModel{
		ID:           u.ID,
		Email:        u.Email,
		PasswordHash: u.PasswordHash,
		Status:       string(u.Status),
		Role:         string(role),
		CreatedAt:    u.CreatedAt,
		UpdatedAt:    u.UpdatedAt,
		LastLoginAt:  u.LastLoginAt,
	}
}

type sessionModel struct {
	ID           uuid.UUID  `gorm:"column:id;type:uuid;primaryKey"`
	UserID       uuid.UUID  `gorm:"column:user_id"`
	IssuedAt     time.Time  `gorm:"column:issued_at"`
	ExpiresAt    time.Time  `gorm:"column:expires_at"`
	RevokedAt    *time.Time `gorm:"column:revoked_at"`
	IP           string     `gorm:"column:ip"`
	UserAgent    string     `gorm:"column:user_agent"`
	AuthProvider string     `gorm:"column:auth_provider"`
}

func (sessionModel) TableName() string { return "sessions" }

func (m sessionModel) toDomain() sessiondomain.Session {
	return sessiondomain.Session{
		ID:           m.ID,
		UserID:       m.UserID,
		IssuedAt:     m.IssuedAt,
		ExpiresAt:    m.ExpiresAt,
		RevokedAt:    m.RevokedAt,
		IP:           m.IP,
		UserAgent:    m.UserAgent,
		AuthProvider: m.AuthProvider,
	}
}

func sessionFromDomain(s sessiondomain.Session) sessionModel {
	return sessionModel{
		ID:           s.ID,
		UserID:       s.UserID,
		IssuedAt:     s.IssuedAt,
		ExpiresAt:    s.ExpiresAt,
		RevokedAt:    s.RevokedAt,
		IP:           s.IP,
		UserAgent:    s.UserAgent,
		AuthProvider: s.AuthProvider,
	}
}

type identityModel struct {
	ID           uuid.UUID      `gorm:"column:id;type:uuid;primaryKey"`
	UserID       uuid.UUID      `gorm:"column:user_id"`
	Provider     string         `gorm:"column:provider"`
	Subject      string         `gorm:"column:subject"`
	AccessToken  string         `gorm:"column:access_token"`
	RefreshToken string         `gorm:"column:refresh_token"`
	Scopes       pq.StringArray `gorm:"column:scopes;type:text[]"`
	ExpiresAt    *time.Time     `gorm:"column:expires_at"`
	CreatedAt    time.Time      `gorm:"column:created_at"`
	UpdatedAt    time.Time      `gorm:"column:updated_at"`
}

func (identityModel) TableName() string { return "user_identities" }

func (m identityModel) toDomain() identitydomain.Identity {
	scopes := make([]string, len(m.Scopes))
	copy(scopes, m.Scopes)

	return identitydomain.Identity{
		ID:           m.ID,
		UserID:       m.UserID,
		Provider:     m.Provider,
		Subject:      m.Subject,
		AccessToken:  m.AccessToken,
		RefreshToken: m.RefreshToken,
		Scopes:       scopes,
		ExpiresAt:    m.ExpiresAt,
		CreatedAt:    m.CreatedAt,
		UpdatedAt:    m.UpdatedAt,
	}
}

func identityFromDomain(identity identitydomain.Identity) identityModel {
	scopes := make(pq.StringArray, len(identity.Scopes))
	copy(scopes, identity.Scopes)

	return identityModel{
		ID:           identity.ID,
		UserID:       identity.UserID,
		Provider:     identity.Provider,
		Subject:      identity.Subject,
		AccessToken:  identity.AccessToken,
		RefreshToken: identity.RefreshToken,
		Scopes:       scopes,
		ExpiresAt:    identity.ExpiresAt,
		CreatedAt:    identity.CreatedAt,
		UpdatedAt:    identity.UpdatedAt,
	}
}

type verificationTokenModel struct {
	ID         uuid.UUID  `gorm:"column:id;type:uuid;primaryKey"`
	UserID     uuid.UUID  `gorm:"column:user_id"`
	Token      string     `gorm:"column:token"`
	ExpiresAt  time.Time  `gorm:"column:expires_at"`
	ConsumedAt *time.Time `gorm:"column:consumed_at"`
	CreatedAt  time.Time  `gorm:"column:created_at"`
}

func (verificationTokenModel) TableName() string { return "email_verification_tokens" }

func (m verificationTokenModel) toDomain() authdomain.VerificationToken {
	return authdomain.VerificationToken{
		ID:        m.ID,
		UserID:    m.UserID,
		Token:     m.Token,
		ExpiresAt: m.ExpiresAt,
		Consumed:  m.ConsumedAt,
		CreatedAt: m.CreatedAt,
	}
}

func verificationTokenFromDomain(t authdomain.VerificationToken) verificationTokenModel {
	return verificationTokenModel{
		ID:         t.ID,
		UserID:     t.UserID,
		Token:      t.Token,
		ExpiresAt:  t.ExpiresAt,
		ConsumedAt: t.Consumed,
		CreatedAt:  t.CreatedAt,
	}
}

package outbound

import (
	"context"

	authdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/auth"
	sessiondomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/session"
	userdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/user"
	"github.com/google/uuid"
)

// UserRepository persists user aggregates
// Implementations must enforce case-insensitive uniqueness on email addresses
type UserRepository interface {
	Create(ctx context.Context, user userdomain.User) (userdomain.User, error)
	FindByEmail(ctx context.Context, email string) (userdomain.User, error)
	FindByID(ctx context.Context, id uuid.UUID) (userdomain.User, error)
	Update(ctx context.Context, user userdomain.User) error
}

// SessionRepository manages browser session entities
type SessionRepository interface {
	Create(ctx context.Context, session sessiondomain.Session) (sessiondomain.Session, error)
	FindByID(ctx context.Context, id uuid.UUID) (sessiondomain.Session, error)
	Delete(ctx context.Context, id uuid.UUID) error
	DeleteByUser(ctx context.Context, userID uuid.UUID) error
}

// VerificationTokenRepository stores email verification tokens
// Tokens are single-use and should be removed or marked consumed when used
type VerificationTokenRepository interface {
	Create(ctx context.Context, token authdomain.VerificationToken) (authdomain.VerificationToken, error)
	FindByToken(ctx context.Context, token string) (authdomain.VerificationToken, error)
	MarkConsumed(ctx context.Context, tokenID uuid.UUID, consumedAt int64) error
	DeleteByUser(ctx context.Context, userID uuid.UUID) error
}

// Mailer delivers transactional email notifications
type Mailer interface {
	Send(ctx context.Context, msg Mail) error
}

// Mail represents an outbound email payload
// Implementations may augment this structure with provider-specific metadata
type Mail struct {
	To      string
	Subject string
	HTML    string
	Text    string
}

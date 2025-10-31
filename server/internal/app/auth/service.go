package auth

import (
	"context"
	"crypto/rand"
	"encoding/base64"
	"errors"
	"fmt"
	"net/mail"
	"strings"
	"time"

	authdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/auth"
	sessiondomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/session"
	userdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/user"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/platform/security/password"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
	"github.com/google/uuid"
	"go.uber.org/zap"
)

// Clock abstracts time sourcing for deterministic testing
type Clock interface {
	Now() time.Time
}

// Config wires runtime options for the authentication service
type Config struct {
	PasswordMinLength int
	SessionTTL        time.Duration
	VerificationTTL   time.Duration
	BaseURL           string
	CookieName        string
}

// Metadata captures request-scoped attributes useful for auditing sessions
type Metadata struct {
	ClientIP  string
	UserAgent string
}

// Service manages user registration, verification, and session issuance
type Service struct {
	users    outbound.UserRepository
	sessions outbound.SessionRepository
	tokens   outbound.VerificationTokenRepository
	mailer   outbound.Mailer
	hasher   password.Hasher
	clock    Clock
	logger   *zap.Logger
	cfg      Config
}

// NewService constructs an authentication service from its dependencies
func NewService(users outbound.UserRepository, sessions outbound.SessionRepository, tokens outbound.VerificationTokenRepository, mailer outbound.Mailer, hasher password.Hasher, clock Clock, logger *zap.Logger, cfg Config) *Service {
	if clock == nil {
		clock = systemClock{}
	}
	if logger == nil {
		logger = zap.NewNop()
	}
	if cfg.SessionTTL == 0 {
		cfg.SessionTTL = 24 * time.Hour
	}
	if cfg.VerificationTTL == 0 {
		cfg.VerificationTTL = 24 * time.Hour
	}
	if cfg.CookieName == "" {
		cfg.CookieName = "area_session"
	}
	return &Service{
		users:    users,
		sessions: sessions,
		tokens:   tokens,
		mailer:   mailer,
		hasher:   hasher,
		clock:    clock,
		logger:   logger,
		cfg:      cfg,
	}
}

var (
	// ErrEmailAlreadyRegistered indicates the email is already in use
	ErrEmailAlreadyRegistered = errors.New("auth: email already registered")

	// ErrInvalidCredentials is returned when email or password do not match
	ErrInvalidCredentials = errors.New("auth: invalid credentials")

	// ErrAccountNotVerified signals that the account must confirm email before login
	ErrAccountNotVerified = errors.New("auth: account requires verification")

	// ErrVerificationTokenExpired indicates the verification token expired
	ErrVerificationTokenExpired = errors.New("auth: verification token expired")

	// ErrVerificationTokenUsed indicates the token has already been consumed
	ErrVerificationTokenUsed = errors.New("auth: verification token consumed")

	// ErrSessionNotFound is returned when the referenced session cannot be found
	ErrSessionNotFound = errors.New("auth: session not found")

	// ErrEmailUnchanged indicates the requested email matches the current value
	ErrEmailUnchanged = errors.New("auth: email unchanged")
)

// RegistrationResult conveys the outcome of a registration attempt
type RegistrationResult struct {
	User                userdomain.User
	VerificationExpires time.Time
}

// VerificationResult represents a successful verification
// It includes the activated user and the associated session
// The caller is responsible for setting the resulting cookie using SessionID
type VerificationResult struct {
	User       userdomain.User
	Session    sessiondomain.Session
	CookieName string
}

// LoginResult holds the session created for a user after authentication
type LoginResult struct {
	User       userdomain.User
	Session    sessiondomain.Session
	CookieName string
}

// EmailChangeResult conveys the outcome of an email update request
type EmailChangeResult struct {
	User                userdomain.User
	VerificationExpires *time.Time
}

// Register creates a pending user and dispatches a verification email
func (s *Service) Register(ctx context.Context, email string, password string) (RegistrationResult, error) {
	email = strings.TrimSpace(strings.ToLower(email))
	if err := validateEmail(email); err != nil {
		return RegistrationResult{}, err
	}
	if len(password) < s.cfg.PasswordMinLength {
		return RegistrationResult{}, fmt.Errorf("auth.Service.Register: password too short")
	}

	if _, err := s.users.FindByEmail(ctx, email); err == nil {
		return RegistrationResult{}, ErrEmailAlreadyRegistered
	} else if !errors.Is(err, outbound.ErrNotFound) {
		return RegistrationResult{}, fmt.Errorf("auth.Service.Register: users.FindByEmail(%s): %w", email, err)
	}

	now := s.clock.Now().UTC()
	hash, err := s.hasher.Hash(password)
	if err != nil {
		return RegistrationResult{}, fmt.Errorf("auth.Service.Register: hash password: %w", err)
	}

	user := userdomain.User{
		ID:           uuid.New(),
		Email:        email,
		PasswordHash: hash,
		Status:       userdomain.StatusPending,
		Role:         userdomain.RoleMember,
		CreatedAt:    now,
		UpdatedAt:    now,
	}

	createdUser, err := s.users.Create(ctx, user)
	if err != nil {
		if errors.Is(err, outbound.ErrConflict) {
			return RegistrationResult{}, ErrEmailAlreadyRegistered
		}
		return RegistrationResult{}, fmt.Errorf("auth.Service.Register: users.Create: %w", err)
	}

	expiresAt, err := s.issueVerification(ctx, createdUser, now)
	if err != nil {
		return RegistrationResult{}, fmt.Errorf("auth.Service.Register: %w", err)
	}

	return RegistrationResult{User: createdUser, VerificationExpires: expiresAt}, nil
}

// VerifyEmail marks a token as consumed, activates the user, and returns a new session cookie
func (s *Service) VerifyEmail(ctx context.Context, token string, meta Metadata) (VerificationResult, error) {
	now := s.clock.Now().UTC()
	record, err := s.tokens.FindByToken(ctx, token)
	if err != nil {
		if errors.Is(err, outbound.ErrNotFound) {
			return VerificationResult{}, ErrVerificationTokenExpired
		}
		return VerificationResult{}, fmt.Errorf("auth.Service.VerifyEmail: tokens.FindByToken: %w", err)
	}
	if record.Used() {
		return VerificationResult{}, ErrVerificationTokenUsed
	}
	if record.Expired(now) {
		return VerificationResult{}, ErrVerificationTokenExpired
	}

	usr, err := s.users.FindByID(ctx, record.UserID)
	if err != nil {
		return VerificationResult{}, fmt.Errorf("auth.Service.VerifyEmail: users.FindByID: %w", err)
	}

	usr.Status = userdomain.StatusActive
	usr.UpdatedAt = now
	if err := s.users.Update(ctx, usr); err != nil {
		return VerificationResult{}, fmt.Errorf("auth.Service.VerifyEmail: users.Update: %w", err)
	}

	if err := s.tokens.MarkConsumed(ctx, record.ID, now.Unix()); err != nil {
		return VerificationResult{}, fmt.Errorf("auth.Service.VerifyEmail: tokens.MarkConsumed: %w", err)
	}
	_ = s.tokens.DeleteByUser(ctx, usr.ID)

	sess := sessiondomain.Session{
		ID:        uuid.New(),
		UserID:    usr.ID,
		IssuedAt:  now,
		ExpiresAt: now.Add(s.cfg.SessionTTL),
		IP:        meta.ClientIP,
		UserAgent: meta.UserAgent,
	}

	createdSession, err := s.sessions.Create(ctx, sess)
	if err != nil {
		return VerificationResult{}, fmt.Errorf("auth.Service.VerifyEmail: sessions.Create: %w", err)
	}

	return VerificationResult{User: usr, Session: createdSession, CookieName: s.cfg.CookieName}, nil
}

// Login validates credentials and issues a session cookie
func (s *Service) Login(ctx context.Context, email string, password string, meta Metadata) (LoginResult, error) {
	email = strings.TrimSpace(strings.ToLower(email))
	usr, err := s.users.FindByEmail(ctx, email)
	if err != nil {
		if errors.Is(err, outbound.ErrNotFound) {
			return LoginResult{}, ErrInvalidCredentials
		}
		return LoginResult{}, fmt.Errorf("auth.Service.Login: users.FindByEmail: %w", err)
	}

	if err := s.hasher.Compare(usr.PasswordHash, password); err != nil {
		return LoginResult{}, ErrInvalidCredentials
	}

	if usr.PendingVerification() {
		return LoginResult{}, ErrAccountNotVerified
	}

	now := s.clock.Now().UTC()
	sess := sessiondomain.Session{
		ID:        uuid.New(),
		UserID:    usr.ID,
		IssuedAt:  now,
		ExpiresAt: now.Add(s.cfg.SessionTTL),
		IP:        meta.ClientIP,
		UserAgent: meta.UserAgent,
	}

	createdSession, err := s.sessions.Create(ctx, sess)
	if err != nil {
		return LoginResult{}, fmt.Errorf("auth.Service.Login: sessions.Create: %w", err)
	}

	usr.LastLoginAt = &now
	usr.UpdatedAt = now
	if err := s.users.Update(ctx, usr); err != nil {
		s.logger.Warn("failed to update last login", zap.Error(err))
	}

	return LoginResult{User: usr, Session: createdSession, CookieName: s.cfg.CookieName}, nil
}

// ChangePassword updates the password after validating the current secret
func (s *Service) ChangePassword(ctx context.Context, userID uuid.UUID, currentPassword, newPassword string) (userdomain.User, error) {
	usr, err := s.users.FindByID(ctx, userID)
	if err != nil {
		return userdomain.User{}, fmt.Errorf("auth.Service.ChangePassword: users.FindByID: %w", err)
	}

	if err := s.hasher.Compare(usr.PasswordHash, currentPassword); err != nil {
		return userdomain.User{}, ErrInvalidCredentials
	}

	hash, err := s.hashPassword("auth.Service.ChangePassword", newPassword)
	if err != nil {
		return userdomain.User{}, err
	}

	now := s.clock.Now().UTC()
	updated := usr.WithPasswordHash(hash)
	updated.UpdatedAt = now

	if err := s.users.Update(ctx, updated); err != nil {
		return userdomain.User{}, fmt.Errorf("auth.Service.ChangePassword: users.Update: %w", err)
	}

	return updated, nil
}

// ChangeEmail updates the email and re-issues a verification token
func (s *Service) ChangeEmail(ctx context.Context, userID uuid.UUID, password string, email string) (EmailChangeResult, error) {
	normalized := strings.TrimSpace(strings.ToLower(email))
	if normalized == "" {
		return EmailChangeResult{}, fmt.Errorf("auth.Service.ChangeEmail: email is empty")
	}
	if err := validateEmail(normalized); err != nil {
		return EmailChangeResult{}, fmt.Errorf("auth.Service.ChangeEmail: %w", err)
	}

	usr, err := s.users.FindByID(ctx, userID)
	if err != nil {
		return EmailChangeResult{}, fmt.Errorf("auth.Service.ChangeEmail: users.FindByID: %w", err)
	}

	if err := s.hasher.Compare(usr.PasswordHash, password); err != nil {
		return EmailChangeResult{}, ErrInvalidCredentials
	}

	if strings.EqualFold(usr.Email, normalized) {
		return EmailChangeResult{}, ErrEmailUnchanged
	}

	if existing, err := s.users.FindByEmail(ctx, normalized); err == nil {
		if existing.ID != usr.ID {
			return EmailChangeResult{}, ErrEmailAlreadyRegistered
		}
	} else if !errors.Is(err, outbound.ErrNotFound) {
		return EmailChangeResult{}, fmt.Errorf("auth.Service.ChangeEmail: users.FindByEmail: %w", err)
	}

	if s.tokens == nil {
		return EmailChangeResult{}, fmt.Errorf("auth.Service.ChangeEmail: token repository missing")
	}
	if err := s.tokens.DeleteByUser(ctx, usr.ID); err != nil && !errors.Is(err, outbound.ErrNotFound) {
		return EmailChangeResult{}, fmt.Errorf("auth.Service.ChangeEmail: tokens.DeleteByUser: %w", err)
	}

	now := s.clock.Now().UTC()
	updated := usr.WithStatus(userdomain.StatusPending)
	updated.Email = normalized
	updated.UpdatedAt = now

	if err := s.users.Update(ctx, updated); err != nil {
		if errors.Is(err, outbound.ErrConflict) {
			return EmailChangeResult{}, ErrEmailAlreadyRegistered
		}
		return EmailChangeResult{}, fmt.Errorf("auth.Service.ChangeEmail: users.Update: %w", err)
	}

	expiresAt, err := s.issueVerification(ctx, updated, now)
	if err != nil {
		return EmailChangeResult{}, fmt.Errorf("auth.Service.ChangeEmail: %w", err)
	}

	return EmailChangeResult{User: updated, VerificationExpires: &expiresAt}, nil
}

// AdminResetPassword sets a new password for the specified user
func (s *Service) AdminResetPassword(ctx context.Context, userID uuid.UUID, newPassword string) (userdomain.User, error) {
	usr, err := s.users.FindByID(ctx, userID)
	if err != nil {
		return userdomain.User{}, fmt.Errorf("auth.Service.AdminResetPassword: users.FindByID: %w", err)
	}

	hash, err := s.hashPassword("auth.Service.AdminResetPassword", newPassword)
	if err != nil {
		return userdomain.User{}, err
	}

	now := s.clock.Now().UTC()
	updated := usr.WithPasswordHash(hash)
	updated.UpdatedAt = now

	if err := s.users.Update(ctx, updated); err != nil {
		return userdomain.User{}, fmt.Errorf("auth.Service.AdminResetPassword: users.Update: %w", err)
	}

	return updated, nil
}

// AdminChangeEmail updates a user's email and optionally issues a verification
func (s *Service) AdminChangeEmail(ctx context.Context, userID uuid.UUID, email string, sendVerification bool) (EmailChangeResult, error) {
	normalized := strings.TrimSpace(strings.ToLower(email))
	if normalized == "" {
		return EmailChangeResult{}, fmt.Errorf("auth.Service.AdminChangeEmail: email is empty")
	}
	if err := validateEmail(normalized); err != nil {
		return EmailChangeResult{}, fmt.Errorf("auth.Service.AdminChangeEmail: %w", err)
	}

	usr, err := s.users.FindByID(ctx, userID)
	if err != nil {
		return EmailChangeResult{}, fmt.Errorf("auth.Service.AdminChangeEmail: users.FindByID: %w", err)
	}

	if strings.EqualFold(usr.Email, normalized) {
		return EmailChangeResult{}, ErrEmailUnchanged
	}

	if existing, err := s.users.FindByEmail(ctx, normalized); err == nil {
		if existing.ID != usr.ID {
			return EmailChangeResult{}, ErrEmailAlreadyRegistered
		}
	} else if !errors.Is(err, outbound.ErrNotFound) {
		return EmailChangeResult{}, fmt.Errorf("auth.Service.AdminChangeEmail: users.FindByEmail: %w", err)
	}

	if s.tokens == nil {
		return EmailChangeResult{}, fmt.Errorf("auth.Service.AdminChangeEmail: token repository missing")
	}
	if err := s.tokens.DeleteByUser(ctx, usr.ID); err != nil && !errors.Is(err, outbound.ErrNotFound) {
		return EmailChangeResult{}, fmt.Errorf("auth.Service.AdminChangeEmail: tokens.DeleteByUser: %w", err)
	}

	now := s.clock.Now().UTC()
	updated := usr
	updated.Email = normalized
	if sendVerification {
		updated.Status = userdomain.StatusPending
	}
	updated.UpdatedAt = now

	if err := s.users.Update(ctx, updated); err != nil {
		if errors.Is(err, outbound.ErrConflict) {
			return EmailChangeResult{}, ErrEmailAlreadyRegistered
		}
		return EmailChangeResult{}, fmt.Errorf("auth.Service.AdminChangeEmail: users.Update: %w", err)
	}

	var expiresAt *time.Time
	if sendVerification {
		expiry, err := s.issueVerification(ctx, updated, now)
		if err != nil {
			return EmailChangeResult{}, fmt.Errorf("auth.Service.AdminChangeEmail: %w", err)
		}
		expiresAt = &expiry
	}

	return EmailChangeResult{User: updated, VerificationExpires: expiresAt}, nil
}

// AdminUpdateStatus changes the lifecycle status of a user and revokes sessions when necessary
func (s *Service) AdminUpdateStatus(ctx context.Context, userID uuid.UUID, status userdomain.Status) (userdomain.User, error) {
	if !isValidUserStatus(status) {
		return userdomain.User{}, fmt.Errorf("auth.Service.AdminUpdateStatus: invalid status %q", status)
	}

	usr, err := s.users.FindByID(ctx, userID)
	if err != nil {
		return userdomain.User{}, fmt.Errorf("auth.Service.AdminUpdateStatus: users.FindByID: %w", err)
	}

	now := s.clock.Now().UTC()
	updated := usr.WithStatus(status)
	updated.UpdatedAt = now

	if err := s.users.Update(ctx, updated); err != nil {
		return userdomain.User{}, fmt.Errorf("auth.Service.AdminUpdateStatus: users.Update: %w", err)
	}

	if s.sessions != nil && status != userdomain.StatusActive {
		if err := s.sessions.DeleteByUser(ctx, updated.ID); err != nil {
			return userdomain.User{}, fmt.Errorf("auth.Service.AdminUpdateStatus: sessions.DeleteByUser: %w", err)
		}
	}

	return updated, nil
}

// Logout revokes the session referenced by the cookie
func (s *Service) Logout(ctx context.Context, sessionID uuid.UUID) error {
	if sessionID == uuid.Nil {
		return ErrSessionNotFound
	}
	if err := s.sessions.Delete(ctx, sessionID); err != nil {
		return fmt.Errorf("auth.Service.Logout: sessions.Delete: %w", err)
	}
	return nil
}

// ResolveSession fetches the user bound to the session identifier and ensures it is active
func (s *Service) ResolveSession(ctx context.Context, sessionID uuid.UUID) (userdomain.User, sessiondomain.Session, error) {
	if sessionID == uuid.Nil {
		return userdomain.User{}, sessiondomain.Session{}, ErrSessionNotFound
	}

	sess, err := s.sessions.FindByID(ctx, sessionID)
	if err != nil {
		if errors.Is(err, outbound.ErrNotFound) {
			return userdomain.User{}, sessiondomain.Session{}, ErrSessionNotFound
		}
		return userdomain.User{}, sessiondomain.Session{}, fmt.Errorf("auth.Service.ResolveSession: sessions.FindByID: %w", err)
	}

	now := s.clock.Now().UTC()
	if !sess.Active(now) {
		_ = s.sessions.Delete(ctx, sess.ID)
		return userdomain.User{}, sessiondomain.Session{}, ErrSessionNotFound
	}

	usr, err := s.users.FindByID(ctx, sess.UserID)
	if err != nil {
		return userdomain.User{}, sessiondomain.Session{}, fmt.Errorf("auth.Service.ResolveSession: users.FindByID: %w", err)
	}
	if !usr.Active() {
		return userdomain.User{}, sessiondomain.Session{}, ErrAccountNotVerified
	}

	return usr, sess, nil
}

func (s *Service) verificationHTMLBody(token string) string {
	link := s.verificationLink(token)
	return fmt.Sprintf(`<p>Bienvenue sur AREA.</p><p>Confirme ton adresse email en cliquant sur <a href="%s">ce lien</a>.</p>`, link)
}

func (s *Service) issueVerification(ctx context.Context, user userdomain.User, now time.Time) (time.Time, error) {
	if s.tokens == nil {
		return time.Time{}, fmt.Errorf("auth.Service.issueVerification: token repository missing")
	}

	tokenValue, err := randomToken()
	if err != nil {
		return time.Time{}, fmt.Errorf("auth.Service.issueVerification: randomToken: %w", err)
	}

	expiresAt := now.Add(s.cfg.VerificationTTL)
	_, err = s.tokens.Create(ctx, authdomain.VerificationToken{
		ID:        uuid.New(),
		UserID:    user.ID,
		Token:     tokenValue,
		ExpiresAt: expiresAt,
		CreatedAt: now,
	})
	if err != nil {
		return time.Time{}, fmt.Errorf("auth.Service.issueVerification: tokens.Create: %w", err)
	}

	if s.mailer != nil {
		msg := outbound.Mail{
			To:      user.Email,
			Subject: "Confirme ton compte AREA",
			Text:    s.verificationTextBody(tokenValue),
			HTML:    s.verificationHTMLBody(tokenValue),
		}
		if err := s.mailer.Send(ctx, msg); err != nil {
			s.logger.Warn("failed to send verification email", zap.Error(err))
		}
	}

	return expiresAt, nil
}

func (s *Service) hashPassword(op string, password string) (string, error) {
	if len(password) < s.cfg.PasswordMinLength {
		return "", fmt.Errorf("%s: password too short", op)
	}
	hash, err := s.hasher.Hash(password)
	if err != nil {
		return "", fmt.Errorf("%s: hash password: %w", op, err)
	}
	return hash, nil
}

func isValidUserStatus(status userdomain.Status) bool {
	switch status {
	case userdomain.StatusPending, userdomain.StatusActive, userdomain.StatusSuspended, userdomain.StatusDeleted:
		return true
	default:
		return false
	}
}

func (s *Service) verificationTextBody(token string) string {
	return fmt.Sprintf("Bienvenue sur AREA. Confirme ton adresse email avec ce lien: %s", s.verificationLink(token))
}

func (s *Service) verificationLink(token string) string {
	base := strings.TrimSuffix(s.cfg.BaseURL, "/")
	return fmt.Sprintf("%s/v1/auth/verify?token=%s", base, token)
}

func validateEmail(email string) error {
	if email == "" {
		return fmt.Errorf("auth.validateEmail: email is empty")
	}
	if _, err := mail.ParseAddress(email); err != nil {
		return fmt.Errorf("auth.validateEmail: invalid email: %w", err)
	}
	return nil
}

func randomToken() (string, error) {
	buf := make([]byte, 32)
	if _, err := rand.Read(buf); err != nil {
		return "", fmt.Errorf("auth.randomToken: rand.Read: %w", err)
	}
	return base64.URLEncoding.WithPadding(base64.NoPadding).EncodeToString(buf), nil
}

type systemClock struct{}

func (systemClock) Now() time.Time { return time.Now() }

package auth

import (
	"context"
	"testing"
	"time"

	authdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/auth"
	sessiondomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/session"
	userdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/user"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/platform/security/password"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
	"github.com/google/uuid"
	"go.uber.org/zap/zaptest"
)

type fakeClock struct{ t time.Time }

func (c *fakeClock) Now() time.Time { return c.t }

func TestService_RegisterVerifyLogin(t *testing.T) {
	ctx := context.Background()
	now := time.Unix(1710000000, 0)
	clock := &fakeClock{t: now}

	users := &memoryUserRepo{items: map[uuid.UUID]userdomain.User{}}
	sessions := &memorySessionRepo{items: map[uuid.UUID]sessiondomain.Session{}}
	tokens := &memoryTokenRepo{items: map[uuid.UUID]authdomain.VerificationToken{}}
	mailer := &collectingMailer{}

	svc := NewService(users, sessions, tokens, mailer, password.Hasher{}, clock, zaptest.NewLogger(t), Config{
		PasswordMinLength: 8,
		SessionTTL:        12 * time.Hour,
		VerificationTTL:   48 * time.Hour,
		BaseURL:           "http://localhost:8080",
	})

	reg, err := svc.Register(ctx, "user@example.com", "password123")
	if err != nil {
		t.Fatalf("Register: %v", err)
	}
	if reg.User.Status != userdomain.StatusPending {
		t.Fatalf("expected pending status got %s", reg.User.Status)
	}
	if len(mailer.messages) != 1 {
		t.Fatalf("expected verification email to be sent")
	}
	if len(tokens.items) != 1 {
		t.Fatalf("expected verification token to be created")
	}

	var tokenValue string
	for _, token := range tokens.items {
		tokenValue = token.Token
	}
	if tokenValue == "" {
		t.Fatalf("token value missing")
	}

	clock.t = now.Add(time.Hour)
	verifyRes, err := svc.VerifyEmail(ctx, tokenValue, Metadata{})
	if err != nil {
		t.Fatalf("VerifyEmail: %v", err)
	}
	if !verifyRes.User.Active() {
		t.Fatalf("expected user to be active after verification")
	}
	if verifyRes.Session.UserID != verifyRes.User.ID {
		t.Fatalf("session not linked to user")
	}

	clock.t = clock.t.Add(time.Hour)
	loginRes, err := svc.Login(ctx, "user@example.com", "password123", Metadata{})
	if err != nil {
		t.Fatalf("Login: %v", err)
	}
	if loginRes.Session.UserID != verifyRes.User.ID {
		t.Fatalf("login session not linked to user")
	}
}

func TestService_Login_Unverified(t *testing.T) {
	ctx := context.Background()
	now := time.Unix(1710000000, 0)
	clock := &fakeClock{t: now}

	hash, err := (password.Hasher{}).Hash("password123")
	if err != nil {
		t.Fatalf("hash password: %v", err)
	}

	usr := userdomain.User{
		ID:           uuid.New(),
		Email:        "user@example.com",
		PasswordHash: hash,
		Status:       userdomain.StatusPending,
		CreatedAt:    now,
		UpdatedAt:    now,
	}

	users := &memoryUserRepo{items: map[uuid.UUID]userdomain.User{usr.ID: usr}, lookup: map[string]uuid.UUID{"user@example.com": usr.ID}}
	sessions := &memorySessionRepo{items: map[uuid.UUID]sessiondomain.Session{}}
	tokens := &memoryTokenRepo{items: map[uuid.UUID]authdomain.VerificationToken{}}

	svc := NewService(users, sessions, tokens, &collectingMailer{}, password.Hasher{}, clock, zaptest.NewLogger(t), Config{
		PasswordMinLength: 8,
		SessionTTL:        12 * time.Hour,
		VerificationTTL:   48 * time.Hour,
	})

	_, err = svc.Login(ctx, "user@example.com", "password123", Metadata{})
	if err != ErrAccountNotVerified {
		t.Fatalf("expected ErrAccountNotVerified got %v", err)
	}
}

// ---- In-memory fixtures ----

type memoryUserRepo struct {
	items  map[uuid.UUID]userdomain.User
	lookup map[string]uuid.UUID
}

func (m *memoryUserRepo) Create(ctx context.Context, user userdomain.User) (userdomain.User, error) {
	if m.items == nil {
		m.items = map[uuid.UUID]userdomain.User{}
	}
	if m.lookup == nil {
		m.lookup = map[string]uuid.UUID{}
	}
	if _, ok := m.lookup[user.Email]; ok {
		return userdomain.User{}, outbound.ErrConflict
	}
	m.items[user.ID] = user
	m.lookup[user.Email] = user.ID
	return user, nil
}

func (m *memoryUserRepo) FindByEmail(ctx context.Context, email string) (userdomain.User, error) {
	if m.lookup == nil {
		return userdomain.User{}, outbound.ErrNotFound
	}
	id, ok := m.lookup[email]
	if !ok {
		return userdomain.User{}, outbound.ErrNotFound
	}
	return m.items[id], nil
}

func (m *memoryUserRepo) FindByID(ctx context.Context, id uuid.UUID) (userdomain.User, error) {
	user, ok := m.items[id]
	if !ok {
		return userdomain.User{}, outbound.ErrNotFound
	}
	return user, nil
}

func (m *memoryUserRepo) Update(ctx context.Context, user userdomain.User) error {
	if _, ok := m.items[user.ID]; !ok {
		return outbound.ErrNotFound
	}
	m.items[user.ID] = user
	m.lookup[user.Email] = user.ID
	return nil
}

type memorySessionRepo struct {
	items map[uuid.UUID]sessiondomain.Session
}

func (m *memorySessionRepo) Create(ctx context.Context, session sessiondomain.Session) (sessiondomain.Session, error) {
	if m.items == nil {
		m.items = map[uuid.UUID]sessiondomain.Session{}
	}
	m.items[session.ID] = session
	return session, nil
}

func (m *memorySessionRepo) FindByID(ctx context.Context, id uuid.UUID) (sessiondomain.Session, error) {
	sess, ok := m.items[id]
	if !ok {
		return sessiondomain.Session{}, outbound.ErrNotFound
	}
	return sess, nil
}

func (m *memorySessionRepo) Delete(ctx context.Context, id uuid.UUID) error {
	delete(m.items, id)
	return nil
}

func (m *memorySessionRepo) DeleteByUser(ctx context.Context, userID uuid.UUID) error {
	for id, sess := range m.items {
		if sess.UserID == userID {
			delete(m.items, id)
		}
	}
	return nil
}

type memoryTokenRepo struct {
	items map[uuid.UUID]authdomain.VerificationToken
}

func (m *memoryTokenRepo) Create(ctx context.Context, token authdomain.VerificationToken) (authdomain.VerificationToken, error) {
	if m.items == nil {
		m.items = map[uuid.UUID]authdomain.VerificationToken{}
	}
	m.items[token.ID] = token
	return token, nil
}

func (m *memoryTokenRepo) FindByToken(ctx context.Context, token string) (authdomain.VerificationToken, error) {
	for _, item := range m.items {
		if item.Token == token {
			return item, nil
		}
	}
	return authdomain.VerificationToken{}, outbound.ErrNotFound
}

func (m *memoryTokenRepo) MarkConsumed(ctx context.Context, tokenID uuid.UUID, consumedAt int64) error {
	token, ok := m.items[tokenID]
	if !ok {
		return outbound.ErrNotFound
	}
	consumed := time.Unix(consumedAt, 0).UTC()
	token.Consumed = &consumed
	m.items[tokenID] = token
	return nil
}

func (m *memoryTokenRepo) DeleteByUser(ctx context.Context, userID uuid.UUID) error {
	for id, token := range m.items {
		if token.UserID == userID {
			delete(m.items, id)
		}
	}
	return nil
}

type collectingMailer struct {
	messages []outbound.Mail
}

func (m *collectingMailer) Send(ctx context.Context, msg outbound.Mail) error {
	m.messages = append(m.messages, msg)
	return nil
}

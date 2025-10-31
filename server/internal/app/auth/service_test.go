package auth

import (
	"context"
	"errors"
	"strings"
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
		Role:         userdomain.RoleMember,
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
	if !errors.Is(err, ErrAccountNotVerified) {
		t.Fatalf("expected ErrAccountNotVerified got %v", err)
	}
}

func TestService_ChangePassword(t *testing.T) {
	ctx := context.Background()
	now := time.Unix(1710100000, 0).UTC()
	clock := &fakeClock{t: now}
	hasher := password.Hasher{}

	oldHash, err := hasher.Hash("oldpassword123")
	if err != nil {
		t.Fatalf("hash old password: %v", err)
	}

	user := userdomain.User{
		ID:           uuid.New(),
		Email:        "user@example.com",
		PasswordHash: oldHash,
		Status:       userdomain.StatusActive,
		Role:         userdomain.RoleMember,
		CreatedAt:    now.Add(-2 * time.Hour),
		UpdatedAt:    now.Add(-time.Hour),
	}

	users := &memoryUserRepo{
		items:  map[uuid.UUID]userdomain.User{user.ID: user},
		lookup: map[string]uuid.UUID{user.Email: user.ID},
	}

	svc := NewService(users, &memorySessionRepo{}, &memoryTokenRepo{}, &collectingMailer{}, hasher, clock, zaptest.NewLogger(t), Config{
		PasswordMinLength: 8,
		SessionTTL:        time.Hour,
		VerificationTTL:   24 * time.Hour,
	})

	updated, err := svc.ChangePassword(ctx, user.ID, "oldpassword123", "newpassword456")
	if err != nil {
		t.Fatalf("ChangePassword: %v", err)
	}

	if err := hasher.Compare(updated.PasswordHash, "newpassword456"); err != nil {
		t.Fatalf("expected password to change: %v", err)
	}
	if !updated.UpdatedAt.Equal(now) {
		t.Fatalf("expected UpdatedAt to equal %v got %v", now, updated.UpdatedAt)
	}
	stored := users.items[user.ID]
	if err := hasher.Compare(stored.PasswordHash, "newpassword456"); err != nil {
		t.Fatalf("repository not updated: %v", err)
	}
}

func TestService_ChangePassword_InvalidCurrent(t *testing.T) {
	ctx := context.Background()
	now := time.Unix(1710100000, 0).UTC()
	clock := &fakeClock{t: now}
	hasher := password.Hasher{}

	hash, err := hasher.Hash("oldpassword123")
	if err != nil {
		t.Fatalf("hash password: %v", err)
	}

	user := userdomain.User{
		ID:           uuid.New(),
		Email:        "user@example.com",
		PasswordHash: hash,
		Status:       userdomain.StatusActive,
		Role:         userdomain.RoleMember,
		CreatedAt:    now,
		UpdatedAt:    now,
	}
	users := &memoryUserRepo{items: map[uuid.UUID]userdomain.User{user.ID: user}, lookup: map[string]uuid.UUID{user.Email: user.ID}}

	svc := NewService(users, &memorySessionRepo{}, &memoryTokenRepo{}, &collectingMailer{}, hasher, clock, zaptest.NewLogger(t), Config{
		PasswordMinLength: 8,
		SessionTTL:        time.Hour,
		VerificationTTL:   24 * time.Hour,
	})

	if _, err := svc.ChangePassword(ctx, user.ID, "wrong", "newpassword456"); !errors.Is(err, ErrInvalidCredentials) {
		t.Fatalf("expected ErrInvalidCredentials got %v", err)
	}
}

func TestService_ChangeEmail(t *testing.T) {
	ctx := context.Background()
	now := time.Unix(1710200000, 0).UTC()
	clock := &fakeClock{t: now}
	hasher := password.Hasher{}

	hash, err := hasher.Hash("password123")
	if err != nil {
		t.Fatalf("hash password: %v", err)
	}

	user := userdomain.User{
		ID:           uuid.New(),
		Email:        "user@example.com",
		PasswordHash: hash,
		Status:       userdomain.StatusActive,
		Role:         userdomain.RoleMember,
		CreatedAt:    now.Add(-time.Hour),
		UpdatedAt:    now.Add(-time.Minute),
	}
	users := &memoryUserRepo{
		items:  map[uuid.UUID]userdomain.User{user.ID: user},
		lookup: map[string]uuid.UUID{user.Email: user.ID},
	}
	tokens := &memoryTokenRepo{}
	mailer := &collectingMailer{}

	svc := NewService(users, &memorySessionRepo{}, tokens, mailer, hasher, clock, zaptest.NewLogger(t), Config{
		PasswordMinLength: 8,
		SessionTTL:        time.Hour,
		VerificationTTL:   36 * time.Hour,
		BaseURL:           "http://localhost:8080",
	})

	result, err := svc.ChangeEmail(ctx, user.ID, "password123", "new@example.com")
	if err != nil {
		t.Fatalf("ChangeEmail: %v", err)
	}
	if result.User.Email != "new@example.com" {
		t.Fatalf("expected email to change got %s", result.User.Email)
	}
	if result.User.Status != userdomain.StatusPending {
		t.Fatalf("expected pending status got %s", result.User.Status)
	}
	if result.VerificationExpires == nil {
		t.Fatalf("expected verification expiry timestamp")
	} else {
		expected := now.Add(36 * time.Hour)
		if !result.VerificationExpires.Equal(expected) {
			t.Fatalf("expected expiry %v got %v", expected, result.VerificationExpires)
		}
	}
	if len(tokens.items) != 1 {
		t.Fatalf("expected verification token to be stored")
	}
	if len(mailer.messages) != 1 || mailer.messages[0].To != "new@example.com" {
		t.Fatalf("expected verification email to new address")
	}
}

func TestService_ChangeEmail_InvalidPassword(t *testing.T) {
	ctx := context.Background()
	now := time.Unix(1710200000, 0).UTC()
	clock := &fakeClock{t: now}
	hasher := password.Hasher{}

	hash, err := hasher.Hash("password123")
	if err != nil {
		t.Fatalf("hash password: %v", err)
	}

	user := userdomain.User{
		ID:           uuid.New(),
		Email:        "user@example.com",
		PasswordHash: hash,
		Status:       userdomain.StatusActive,
		Role:         userdomain.RoleMember,
		CreatedAt:    now,
		UpdatedAt:    now,
	}
	users := &memoryUserRepo{items: map[uuid.UUID]userdomain.User{user.ID: user}, lookup: map[string]uuid.UUID{user.Email: user.ID}}

	svc := NewService(users, &memorySessionRepo{}, &memoryTokenRepo{}, &collectingMailer{}, hasher, clock, zaptest.NewLogger(t), Config{
		PasswordMinLength: 8,
		SessionTTL:        time.Hour,
		VerificationTTL:   24 * time.Hour,
		BaseURL:           "http://localhost:8080",
	})

	if _, err := svc.ChangeEmail(ctx, user.ID, "wrong", "new@example.com"); !errors.Is(err, ErrInvalidCredentials) {
		t.Fatalf("expected ErrInvalidCredentials got %v", err)
	}
}

func TestService_AdminResetPassword(t *testing.T) {
	ctx := context.Background()
	now := time.Unix(1710300000, 0).UTC()
	clock := &fakeClock{t: now}
	hasher := password.Hasher{}

	user := userdomain.User{
		ID:        uuid.New(),
		Email:     "user@example.com",
		Status:    userdomain.StatusActive,
		Role:      userdomain.RoleMember,
		CreatedAt: now.Add(-2 * time.Hour),
		UpdatedAt: now.Add(-time.Hour),
	}
	users := &memoryUserRepo{items: map[uuid.UUID]userdomain.User{user.ID: user}, lookup: map[string]uuid.UUID{user.Email: user.ID}}

	svc := NewService(users, &memorySessionRepo{}, &memoryTokenRepo{}, &collectingMailer{}, hasher, clock, zaptest.NewLogger(t), Config{
		PasswordMinLength: 8,
		SessionTTL:        time.Hour,
		VerificationTTL:   24 * time.Hour,
	})

	updated, err := svc.AdminResetPassword(ctx, user.ID, "adminpassword789")
	if err != nil {
		t.Fatalf("AdminResetPassword: %v", err)
	}
	if err := hasher.Compare(updated.PasswordHash, "adminpassword789"); err != nil {
		t.Fatalf("expected password to change: %v", err)
	}
}

func TestService_AdminChangeEmail(t *testing.T) {
	ctx := context.Background()
	now := time.Unix(1710400000, 0).UTC()
	clock := &fakeClock{t: now}
	hasher := password.Hasher{}

	user := userdomain.User{
		ID:        uuid.New(),
		Email:     "user@example.com",
		Status:    userdomain.StatusSuspended,
		Role:      userdomain.RoleMember,
		CreatedAt: now.Add(-time.Hour),
		UpdatedAt: now.Add(-time.Minute),
	}
	users := &memoryUserRepo{items: map[uuid.UUID]userdomain.User{user.ID: user}, lookup: map[string]uuid.UUID{user.Email: user.ID}}
	tokens := &memoryTokenRepo{items: map[uuid.UUID]authdomain.VerificationToken{uuid.New(): {ID: uuid.New(), UserID: user.ID}}}
	mailer := &collectingMailer{}

	svc := NewService(users, &memorySessionRepo{}, tokens, mailer, hasher, clock, zaptest.NewLogger(t), Config{
		PasswordMinLength: 8,
		SessionTTL:        time.Hour,
		VerificationTTL:   12 * time.Hour,
		BaseURL:           "http://localhost:8080",
	})

	result, err := svc.AdminChangeEmail(ctx, user.ID, "managed@example.com", true)
	if err != nil {
		t.Fatalf("AdminChangeEmail: %v", err)
	}
	if result.User.Email != "managed@example.com" {
		t.Fatalf("expected email to change got %s", result.User.Email)
	}
	if result.User.Status != userdomain.StatusPending {
		t.Fatalf("expected status pending got %s", result.User.Status)
	}
	if result.VerificationExpires == nil {
		t.Fatalf("expected verification expiry timestamp")
	}
	if len(tokens.items) != 1 {
		t.Fatalf("expected a single verification token after update")
	}
	if len(mailer.messages) != 1 {
		t.Fatalf("expected verification email to be sent")
	}
}

func TestService_AdminChangeEmail_SkipVerification(t *testing.T) {
	ctx := context.Background()
	now := time.Unix(1710400000, 0).UTC()
	clock := &fakeClock{t: now}
	hasher := password.Hasher{}

	user := userdomain.User{
		ID:        uuid.New(),
		Email:     "user@example.com",
		Status:    userdomain.StatusActive,
		Role:      userdomain.RoleMember,
		CreatedAt: now,
		UpdatedAt: now,
	}
	users := &memoryUserRepo{items: map[uuid.UUID]userdomain.User{user.ID: user}, lookup: map[string]uuid.UUID{user.Email: user.ID}}
	tokens := &memoryTokenRepo{}
	mailer := &collectingMailer{}

	svc := NewService(users, &memorySessionRepo{}, tokens, mailer, hasher, clock, zaptest.NewLogger(t), Config{
		PasswordMinLength: 8,
		SessionTTL:        time.Hour,
		VerificationTTL:   12 * time.Hour,
		BaseURL:           "http://localhost:8080",
	})

	result, err := svc.AdminChangeEmail(ctx, user.ID, "managed@example.com", false)
	if err != nil {
		t.Fatalf("AdminChangeEmail: %v", err)
	}
	if result.User.Status != userdomain.StatusActive {
		t.Fatalf("expected status to remain active got %s", result.User.Status)
	}
	if result.VerificationExpires != nil {
		t.Fatalf("expected no verification expiry when skipping email")
	}
	if len(tokens.items) != 0 {
		t.Fatalf("expected no verification tokens when skipping email")
	}
	if len(mailer.messages) != 0 {
		t.Fatalf("expected no email to be sent")
	}
}

func TestService_AdminUpdateStatus(t *testing.T) {
	ctx := context.Background()
	now := time.Unix(1710500000, 0).UTC()
	clock := &fakeClock{t: now}
	hasher := password.Hasher{}

	user := userdomain.User{
		ID:        uuid.New(),
		Email:     "user@example.com",
		Status:    userdomain.StatusActive,
		Role:      userdomain.RoleMember,
		CreatedAt: now.Add(-time.Hour),
		UpdatedAt: now.Add(-time.Minute),
	}
	users := &memoryUserRepo{items: map[uuid.UUID]userdomain.User{user.ID: user}, lookup: map[string]uuid.UUID{user.Email: user.ID}}
	sessID := uuid.New()
	session := sessiondomain.Session{
		ID:        sessID,
		UserID:    user.ID,
		IssuedAt:  now.Add(-time.Minute),
		ExpiresAt: now.Add(time.Hour),
	}
	sessions := &memorySessionRepo{items: map[uuid.UUID]sessiondomain.Session{sessID: session}}

	svc := NewService(users, sessions, &memoryTokenRepo{}, &collectingMailer{}, hasher, clock, zaptest.NewLogger(t), Config{
		PasswordMinLength: 8,
		SessionTTL:        time.Hour,
		VerificationTTL:   12 * time.Hour,
	})

	updated, err := svc.AdminUpdateStatus(ctx, user.ID, userdomain.StatusSuspended)
	if err != nil {
		t.Fatalf("AdminUpdateStatus: %v", err)
	}
	if updated.Status != userdomain.StatusSuspended {
		t.Fatalf("expected suspended status got %s", updated.Status)
	}
	if len(sessions.items) != 0 {
		t.Fatalf("expected sessions to be revoked")
	}
}

func TestService_AdminUpdateStatus_Invalid(t *testing.T) {
	ctx := context.Background()
	now := time.Unix(1710500000, 0).UTC()
	clock := &fakeClock{t: now}
	hasher := password.Hasher{}

	user := userdomain.User{ID: uuid.New(), Email: "user@example.com", Status: userdomain.StatusActive, Role: userdomain.RoleMember}
	users := &memoryUserRepo{items: map[uuid.UUID]userdomain.User{user.ID: user}, lookup: map[string]uuid.UUID{user.Email: user.ID}}

	svc := NewService(users, &memorySessionRepo{}, &memoryTokenRepo{}, &collectingMailer{}, hasher, clock, zaptest.NewLogger(t), Config{
		PasswordMinLength: 8,
		SessionTTL:        time.Hour,
		VerificationTTL:   12 * time.Hour,
	})

	_, err := svc.AdminUpdateStatus(ctx, user.ID, userdomain.Status("invalid"))
	if err == nil || !strings.Contains(err.Error(), "invalid status") {
		t.Fatalf("expected invalid status error got %v", err)
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
	if user.Role == "" {
		user.Role = userdomain.RoleMember
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
	if m.lookup == nil {
		m.lookup = map[string]uuid.UUID{}
	}
	prev := m.items[user.ID]
	if user.Role == "" {
		user.Role = userdomain.RoleMember
	}
	m.items[user.ID] = user
	if !strings.EqualFold(prev.Email, user.Email) {
		delete(m.lookup, prev.Email)
	}
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

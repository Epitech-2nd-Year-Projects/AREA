package auth

import (
	"context"
	"testing"
	"time"

	identitydomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/identity"
	sessiondomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/session"
	userdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/user"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/oauth2"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
	identityport "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound/identity"
	"github.com/google/uuid"
	"go.uber.org/zap/zaptest"
)

func TestOAuthServiceExchangeCreatesUser(t *testing.T) {
	ctx := context.Background()
	now := time.Unix(1720000000, 0).UTC()
	clock := &fakeClock{t: now}

	users := &memoryUserRepo{items: map[uuid.UUID]userdomain.User{}, lookup: map[string]uuid.UUID{}}
	sessions := &memorySessionRepo{items: map[uuid.UUID]sessiondomain.Session{}}
	identities := &memoryIdentityRepo{items: map[uuid.UUID]identitydomain.Identity{}, byKey: map[string]uuid.UUID{}}

	provider := &stubProvider{
		name: "stub",
		exchange: identityport.TokenExchange{
			Token: oauth2.Token{
				AccessToken:  "access-123",
				RefreshToken: "refresh-123",
				Scope:        []string{"email", "profile"},
				ExpiresAt:    now.Add(3600 * time.Second),
			},
			Profile: identitydomain.Profile{
				Provider: "stub",
				Subject:  "user-1",
				Email:    "user@example.com",
				Name:     "OAuth User",
			},
		},
	}

	resolver := staticProviderResolver{"stub": provider}

	svc := NewOAuthService(resolver, identities, users, sessions, clock, zaptest.NewLogger(t), Config{SessionTTL: time.Hour, CookieName: "session"})

	login, storedIdentity, err := svc.Exchange(ctx, "stub", "code-abc", identityport.ExchangeRequest{}, Metadata{ClientIP: "127.0.0.1"})
	if err != nil {
		t.Fatalf("Exchange returned error: %v", err)
	}

	if login.User.Email != "user@example.com" {
		t.Fatalf("unexpected user email %s", login.User.Email)
	}
	if login.Session.UserID != login.User.ID {
		t.Fatalf("session not linked to user")
	}
	if len(sessions.items) != 1 {
		t.Fatalf("expected session to be created")
	}
	if storedIdentity.Provider != "stub" || storedIdentity.Subject != "user-1" {
		t.Fatalf("identity not stored correctly")
	}
	if storedIdentity.AccessToken != "access-123" {
		t.Fatalf("unexpected access token %s", storedIdentity.AccessToken)
	}
	if storedIdentity.RefreshToken != "refresh-123" {
		t.Fatalf("unexpected refresh token %s", storedIdentity.RefreshToken)
	}
	if len(storedIdentity.Scopes) != 2 {
		t.Fatalf("expected scopes to be persisted")
	}
}

func TestOAuthServiceExchangeUpdatesIdentity(t *testing.T) {
	ctx := context.Background()
	now := time.Unix(1720000000, 0).UTC()
	clock := &fakeClock{t: now}

	user := userdomain.User{
		ID:        uuid.New(),
		Email:     "user@example.com",
		Status:    userdomain.StatusActive,
		CreatedAt: now,
		UpdatedAt: now,
	}

	users := &memoryUserRepo{items: map[uuid.UUID]userdomain.User{user.ID: user}, lookup: map[string]uuid.UUID{"user@example.com": user.ID}}
	sessions := &memorySessionRepo{items: map[uuid.UUID]sessiondomain.Session{}}
	identity := identitydomain.Identity{
		ID:           uuid.New(),
		UserID:       user.ID,
		Provider:     "stub",
		Subject:      "user-1",
		AccessToken:  "old-access",
		RefreshToken: "refresh-123",
		Scopes:       []string{"email"},
		CreatedAt:    now.Add(-time.Hour),
		UpdatedAt:    now.Add(-time.Hour),
	}
	identities := &memoryIdentityRepo{items: map[uuid.UUID]identitydomain.Identity{identity.ID: identity}, byKey: map[string]uuid.UUID{"stub|user-1": identity.ID}}

	provider := &stubProvider{
		name: "stub",
		exchange: identityport.TokenExchange{
			Token: oauth2.Token{
				AccessToken: "new-access",
				Scope:       []string{"email", "profile"},
			},
			Profile: identitydomain.Profile{
				Provider: "stub",
				Subject:  "user-1",
				Email:    "user@example.com",
			},
		},
	}

	resolver := staticProviderResolver{"stub": provider}

	svc := NewOAuthService(resolver, identities, users, sessions, clock, zaptest.NewLogger(t), Config{SessionTTL: time.Hour, CookieName: "session"})

	login, updatedIdentity, err := svc.Exchange(ctx, "stub", "code-abc", identityport.ExchangeRequest{}, Metadata{})
	if err != nil {
		t.Fatalf("Exchange returned error: %v", err)
	}

	if updatedIdentity.AccessToken != "new-access" {
		t.Fatalf("expected access token to be updated")
	}
	if updatedIdentity.RefreshToken != "refresh-123" {
		t.Fatalf("refresh token should be preserved when missing")
	}
	if len(updatedIdentity.Scopes) != 2 {
		t.Fatalf("expected scopes to be updated")
	}
	if login.Session.UserID != user.ID {
		t.Fatalf("session user mismatch")
	}
}

type staticProviderResolver map[string]identityport.Provider

func (m staticProviderResolver) Provider(name string) (identityport.Provider, bool) {
	p, ok := m[name]
	return p, ok
}

type stubProvider struct {
	name     string
	authResp identityport.AuthorizationResponse
	exchange identityport.TokenExchange
}

func (s *stubProvider) Name() string { return s.name }

func (s *stubProvider) AuthorizationURL(ctx context.Context, req identityport.AuthorizationRequest) (identityport.AuthorizationResponse, error) {
	resp := s.authResp
	if resp.AuthorizationURL == "" {
		resp = identityport.AuthorizationResponse{
			AuthorizationURL: "https://auth.example/authorize",
			State:            req.State,
		}
	}
	return resp, nil
}

func (s *stubProvider) Exchange(ctx context.Context, code string, req identityport.ExchangeRequest) (identityport.TokenExchange, error) {
	return s.exchange, nil
}

func (s *stubProvider) Refresh(ctx context.Context, identity identitydomain.Identity) (identityport.TokenExchange, error) {
	return identityport.TokenExchange{}, nil
}

type memoryIdentityRepo struct {
	items map[uuid.UUID]identitydomain.Identity
	byKey map[string]uuid.UUID
}

func (m *memoryIdentityRepo) key(provider string, subject string) string {
	return provider + "|" + subject
}

func (m *memoryIdentityRepo) Create(ctx context.Context, identity identitydomain.Identity) (identitydomain.Identity, error) {
	if m.items == nil {
		m.items = map[uuid.UUID]identitydomain.Identity{}
		m.byKey = map[string]uuid.UUID{}
	}
	key := m.key(identity.Provider, identity.Subject)
	if _, exists := m.byKey[key]; exists {
		return identitydomain.Identity{}, outbound.ErrConflict
	}
	if identity.ID == uuid.Nil {
		identity.ID = uuid.New()
	}
	clone := cloneIdentity(identity)
	m.items[clone.ID] = clone
	m.byKey[key] = clone.ID
	return clone, nil
}

func (m *memoryIdentityRepo) Update(ctx context.Context, identity identitydomain.Identity) error {
	if m.items == nil {
		return outbound.ErrNotFound
	}
	if _, ok := m.items[identity.ID]; !ok {
		return outbound.ErrNotFound
	}
	clone := cloneIdentity(identity)
	m.items[clone.ID] = clone
	m.byKey[m.key(clone.Provider, clone.Subject)] = clone.ID
	return nil
}

func (m *memoryIdentityRepo) FindByID(ctx context.Context, id uuid.UUID) (identitydomain.Identity, error) {
	if identity, ok := m.items[id]; ok {
		return cloneIdentity(identity), nil
	}
	return identitydomain.Identity{}, outbound.ErrNotFound
}

func (m *memoryIdentityRepo) FindByUserAndProvider(ctx context.Context, userID uuid.UUID, provider string) (identitydomain.Identity, error) {
	for _, identity := range m.items {
		if identity.UserID == userID && identity.Provider == provider {
			return cloneIdentity(identity), nil
		}
	}
	return identitydomain.Identity{}, outbound.ErrNotFound
}

func (m *memoryIdentityRepo) FindByProviderSubject(ctx context.Context, provider string, subject string) (identitydomain.Identity, error) {
	if m.items == nil {
		return identitydomain.Identity{}, outbound.ErrNotFound
	}
	if id, ok := m.byKey[m.key(provider, subject)]; ok {
		return cloneIdentity(m.items[id]), nil
	}
	return identitydomain.Identity{}, outbound.ErrNotFound
}

func (m *memoryIdentityRepo) ListByUser(ctx context.Context, userID uuid.UUID) ([]identitydomain.Identity, error) {
	result := make([]identitydomain.Identity, 0)
	for _, identity := range m.items {
		if identity.UserID == userID {
			result = append(result, cloneIdentity(identity))
		}
	}
	return result, nil
}

func (m *memoryIdentityRepo) Delete(ctx context.Context, id uuid.UUID) error {
	if identity, ok := m.items[id]; ok {
		delete(m.byKey, m.key(identity.Provider, identity.Subject))
		delete(m.items, id)
		return nil
	}
	return outbound.ErrNotFound
}

func cloneIdentity(identity identitydomain.Identity) identitydomain.Identity {
	clone := identity
	if identity.Scopes != nil {
		clone.Scopes = append([]string(nil), identity.Scopes...)
	}
	return clone
}

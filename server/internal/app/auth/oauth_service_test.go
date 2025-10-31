package auth

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"testing"
	"time"

	identitydomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/identity"
	servicedomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/service"
	sessiondomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/session"
	subscriptiondomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/subscription"
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

	svc := NewOAuthService(resolver, identities, users, sessions, nil, nil, clock, zaptest.NewLogger(t), Config{SessionTTL: time.Hour, CookieName: "session"})

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
		Role:      userdomain.RoleMember,
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

	svc := NewOAuthService(resolver, identities, users, sessions, nil, nil, clock, zaptest.NewLogger(t), Config{SessionTTL: time.Hour, CookieName: "session"})

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

func TestOAuthServiceLinkServiceCreatesSubscription(t *testing.T) {
	ctx := context.Background()
	now := time.Unix(1725000000, 0).UTC()
	clock := &fakeClock{t: now}

	user := userdomain.User{
		ID:        uuid.New(),
		Email:     "user@example.com",
		Status:    userdomain.StatusActive,
		Role:      userdomain.RoleMember,
		CreatedAt: now,
		UpdatedAt: now,
	}

	identities := &memoryIdentityRepo{items: map[uuid.UUID]identitydomain.Identity{}, byKey: map[string]uuid.UUID{}}
	providerID := uuid.New()
	serviceProviders := &memoryServiceProviderRepo{items: map[string]servicedomain.Provider{
		"stub": {
			ID:        providerID,
			Name:      "stub",
			OAuthType: servicedomain.OAuthTypeOAuth2,
		},
	}}
	subscriptions := &memorySubscriptionRepo{items: map[uuid.UUID]subscriptiondomain.Subscription{}, byKey: map[string]uuid.UUID{}}

	provider := &stubProvider{
		name: "stub",
		exchange: identityport.TokenExchange{
			Token: oauth2.Token{
				AccessToken:  "access-123",
				RefreshToken: "refresh-xyz",
				Scope:        []string{"email.send"},
				ExpiresAt:    now.Add(2 * time.Hour),
			},
			Profile: identitydomain.Profile{
				Provider: "stub",
				Subject:  "remote-1",
				Email:    "user@example.com",
			},
		},
	}
	resolver := staticProviderResolver{"stub": provider}

	svc := NewOAuthService(resolver, identities, nil, nil, serviceProviders, subscriptions, clock, zaptest.NewLogger(t), Config{SessionTTL: time.Hour, CookieName: "session"})

	subscription, identity, err := svc.LinkService(ctx, user, "stub", "code-abc", identityport.ExchangeRequest{})
	if err != nil {
		t.Fatalf("LinkService returned error: %v", err)
	}
	if identity.UserID != user.ID {
		t.Fatalf("identity not linked to user")
	}
	if len(identity.Scopes) != 1 || identity.Scopes[0] != "email.send" {
		t.Fatalf("identity scopes not persisted")
	}
	if subscription.ProviderID != providerID {
		t.Fatalf("subscription provider mismatch")
	}
	if subscription.IdentityID == nil || *subscription.IdentityID != identity.ID {
		t.Fatalf("subscription not linked to identity")
	}
	if len(subscription.ScopeGrants) != 1 {
		t.Fatalf("expected scope grants to be stored")
	}
	if _, err := subscriptions.FindByUserAndProvider(ctx, user.ID, providerID); err != nil {
		t.Fatalf("subscription not persisted: %v", err)
	}
}

func TestOAuthServiceLinkServiceIdentityConflict(t *testing.T) {
	ctx := context.Background()
	now := time.Unix(1726000000, 0).UTC()
	clock := &fakeClock{t: now}

	owner := uuid.New()
	user := userdomain.User{
		ID:        uuid.New(),
		Email:     "user@example.com",
		Status:    userdomain.StatusActive,
		Role:      userdomain.RoleMember,
		CreatedAt: now,
		UpdatedAt: now,
	}

	identity := identitydomain.Identity{
		ID:        uuid.New(),
		UserID:    owner,
		Provider:  "stub",
		Subject:   "remote-1",
		CreatedAt: now.Add(-time.Hour),
		UpdatedAt: now.Add(-time.Hour),
	}
	identities := &memoryIdentityRepo{items: map[uuid.UUID]identitydomain.Identity{identity.ID: identity}, byKey: map[string]uuid.UUID{"stub|remote-1": identity.ID}}

	providerID := uuid.New()
	serviceProviders := &memoryServiceProviderRepo{items: map[string]servicedomain.Provider{
		"stub": {ID: providerID, Name: "stub", OAuthType: servicedomain.OAuthTypeOAuth2},
	}}
	subscriptions := &memorySubscriptionRepo{items: map[uuid.UUID]subscriptiondomain.Subscription{}, byKey: map[string]uuid.UUID{}}

	provider := &stubProvider{
		name: "stub",
		exchange: identityport.TokenExchange{
			Token: oauth2.Token{AccessToken: "access-123"},
			Profile: identitydomain.Profile{
				Provider: "stub",
				Subject:  "remote-1",
				Email:    "user@example.com",
			},
		},
	}
	resolver := staticProviderResolver{"stub": provider}

	svc := NewOAuthService(resolver, identities, nil, nil, serviceProviders, subscriptions, clock, zaptest.NewLogger(t), Config{SessionTTL: time.Hour, CookieName: "session"})

	_, _, err := svc.LinkService(ctx, user, "stub", "code-abc", identityport.ExchangeRequest{})
	if !errors.Is(err, ErrIdentityOwnershipConflict) {
		t.Fatalf("expected identity ownership conflict, got %v", err)
	}
}

func TestOAuthServiceBeginSubscriptionOAuth2(t *testing.T) {
	ctx := context.Background()
	now := time.Unix(1727000000, 0).UTC()
	clock := &fakeClock{t: now}

	user := userdomain.User{ID: uuid.New(), Role: userdomain.RoleMember}
	providerID := uuid.New()
	serviceProviders := &memoryServiceProviderRepo{items: map[string]servicedomain.Provider{
		"stub": {ID: providerID, Name: "stub", OAuthType: servicedomain.OAuthTypeOAuth2},
	}}
	subscriptions := &memorySubscriptionRepo{items: map[uuid.UUID]subscriptiondomain.Subscription{}, byKey: map[string]uuid.UUID{}}

	provider := &stubProvider{
		name: "stub",
		authResp: identityport.AuthorizationResponse{
			AuthorizationURL: "https://auth.example/authorize",
			State:            "state-123",
			CodeVerifier:     "verifier",
		},
	}
	resolver := staticProviderResolver{"stub": provider}

	svc := NewOAuthService(resolver, nil, nil, nil, serviceProviders, subscriptions, clock, zaptest.NewLogger(t), Config{})

	result, err := svc.BeginSubscription(ctx, user, "stub", identityport.AuthorizationRequest{State: "state-123"})
	if err != nil {
		t.Fatalf("BeginSubscription returned error: %v", err)
	}
	if result.Authorization == nil {
		t.Fatalf("expected authorization response")
	}
	if result.Authorization.AuthorizationURL == "" {
		t.Fatalf("authorization URL missing")
	}
	if result.Subscription != nil {
		t.Fatalf("did not expect subscription to be created before exchange")
	}
}

func TestOAuthServiceBeginSubscriptionWithoutOAuth(t *testing.T) {
	ctx := context.Background()
	now := time.Unix(1727100000, 0).UTC()
	clock := &fakeClock{t: now}

	user := userdomain.User{ID: uuid.New(), Role: userdomain.RoleMember}
	providerID := uuid.New()
	serviceProviders := &memoryServiceProviderRepo{items: map[string]servicedomain.Provider{
		"timer": {ID: providerID, Name: "timer", OAuthType: servicedomain.OAuthTypeNone},
	}}
	subscriptions := &memorySubscriptionRepo{items: map[uuid.UUID]subscriptiondomain.Subscription{}, byKey: map[string]uuid.UUID{}}

	svc := NewOAuthService(nil, nil, nil, nil, serviceProviders, subscriptions, clock, zaptest.NewLogger(t), Config{})

	result, err := svc.BeginSubscription(ctx, user, "timer", identityport.AuthorizationRequest{})
	if err != nil {
		t.Fatalf("BeginSubscription returned error: %v", err)
	}
	if result.Subscription == nil {
		t.Fatalf("expected subscription to be created")
	}
	if result.Authorization != nil {
		t.Fatalf("did not expect authorization response for non-oauth provider")
	}
	if _, err := subscriptions.FindByUserAndProvider(ctx, user.ID, providerID); err != nil {
		t.Fatalf("subscription not persisted: %v", err)
	}
}

func TestOAuthServiceListIdentitiesRequiresRepository(t *testing.T) {
	svc := NewOAuthService(nil, nil, nil, nil, nil, nil, nil, nil, Config{})

	_, err := svc.ListIdentities(context.Background(), uuid.New())
	if err == nil {
		t.Fatalf("expected error when repository unavailable")
	}
}

func TestOAuthServiceListIdentitiesSuccess(t *testing.T) {
	userID := uuid.New()
	identity := identitydomain.Identity{
		ID:       uuid.New(),
		UserID:   userID,
		Provider: "google",
		Subject:  "subject-1",
	}
	repo := &memoryIdentityRepo{items: map[uuid.UUID]identitydomain.Identity{identity.ID: identity}}

	svc := NewOAuthService(nil, repo, nil, nil, nil, nil, nil, nil, Config{})

	items, err := svc.ListIdentities(context.Background(), userID)
	if err != nil {
		t.Fatalf("ListIdentities returned error: %v", err)
	}
	if len(items) != 1 {
		t.Fatalf("expected 1 identity, got %d", len(items))
	}
	if items[0].ID != identity.ID {
		t.Fatalf("unexpected identity returned")
	}
}

func TestOAuthServiceListProviders(t *testing.T) {
	now := time.Unix(1720000000, 0).UTC()
	githubID := uuid.New()
	timerID := uuid.New()
	repo := &memoryServiceProviderRepo{
		items: map[string]servicedomain.Provider{
			"github": {
				ID:          githubID,
				Name:        "github",
				DisplayName: "GitHub",
				Category:    "developer-tools",
				OAuthType:   servicedomain.OAuthTypeOAuth2,
				Enabled:     true,
				CreatedAt:   now,
				UpdatedAt:   now,
			},
			"timer": {
				ID:          timerID,
				Name:        "timer",
				DisplayName: "Timer",
				Category:    "automation",
				OAuthType:   servicedomain.OAuthTypeNone,
				Enabled:     true,
				CreatedAt:   now,
				UpdatedAt:   now,
			},
		},
	}

	svc := NewOAuthService(nil, nil, nil, nil, repo, nil, nil, nil, Config{})

	providers, err := svc.ListProviders(context.Background())
	if err != nil {
		t.Fatalf("ListProviders returned error: %v", err)
	}
	if len(providers) != 2 {
		t.Fatalf("expected 2 providers, got %d", len(providers))
	}

	seen := map[uuid.UUID]struct{}{}
	for _, provider := range providers {
		seen[provider.ID] = struct{}{}
	}
	if _, ok := seen[githubID]; !ok {
		t.Fatalf("missing github provider in response")
	}
	if _, ok := seen[timerID]; !ok {
		t.Fatalf("missing timer provider in response")
	}
}

func TestOAuthServiceListSubscriptions(t *testing.T) {
	ctx := context.Background()
	now := time.Unix(1720000100, 0).UTC()
	userID := uuid.New()
	providerID := uuid.New()
	subscriptionID := uuid.New()

	provider := servicedomain.Provider{
		ID:          providerID,
		Name:        "github",
		DisplayName: "GitHub",
		Category:    "developer-tools",
		OAuthType:   servicedomain.OAuthTypeOAuth2,
		Enabled:     true,
		CreatedAt:   now,
		UpdatedAt:   now,
	}
	providers := &memoryServiceProviderRepo{items: map[string]servicedomain.Provider{"github": provider}}

	subscription := subscriptiondomain.Subscription{
		ID:         subscriptionID,
		UserID:     userID,
		ProviderID: providerID,
		Status:     subscriptiondomain.StatusActive,
		CreatedAt:  now,
		UpdatedAt:  now,
	}
	subscriptions := &memorySubscriptionRepo{
		items: map[uuid.UUID]subscriptiondomain.Subscription{
			subscriptionID: subscription,
		},
		byKey: map[string]uuid.UUID{},
	}
	subscriptions.byKey[subscriptions.key(userID, providerID)] = subscriptionID

	svc := NewOAuthService(nil, nil, nil, nil, providers, subscriptions, fixedClock{now: now}, nil, Config{})

	records, err := svc.ListSubscriptions(ctx, userID)
	if err != nil {
		t.Fatalf("ListSubscriptions returned error: %v", err)
	}
	if len(records) != 1 {
		t.Fatalf("expected 1 subscription, got %d", len(records))
	}
	record := records[0]
	if record.Subscription.ID != subscriptionID {
		t.Fatalf("unexpected subscription id %s", record.Subscription.ID)
	}
	if record.Provider.ID != providerID {
		t.Fatalf("unexpected provider id %s", record.Provider.ID)
	}
}

func TestOAuthServiceUnsubscribe(t *testing.T) {
	ctx := context.Background()
	now := time.Unix(1720000200, 0).UTC()
	userID := uuid.New()
	providerID := uuid.New()
	subscriptionID := uuid.New()
	identityID := uuid.New()

	provider := servicedomain.Provider{
		ID:          providerID,
		Name:        "github",
		DisplayName: "GitHub",
		Category:    "developer-tools",
		OAuthType:   servicedomain.OAuthTypeOAuth2,
		Enabled:     true,
		CreatedAt:   now,
		UpdatedAt:   now,
	}
	providers := &memoryServiceProviderRepo{items: map[string]servicedomain.Provider{"github": provider}}

	subscription := subscriptiondomain.Subscription{
		ID:          subscriptionID,
		UserID:      userID,
		ProviderID:  providerID,
		IdentityID:  &identityID,
		Status:      subscriptiondomain.StatusActive,
		ScopeGrants: []string{"repo"},
		CreatedAt:   now.Add(-time.Hour),
		UpdatedAt:   now.Add(-time.Hour),
	}
	subscriptions := &memorySubscriptionRepo{
		items: map[uuid.UUID]subscriptiondomain.Subscription{
			subscriptionID: subscription,
		},
		byKey: map[string]uuid.UUID{},
	}
	subscriptions.byKey[subscriptions.key(userID, providerID)] = subscriptionID

	identity := identitydomain.Identity{
		ID:       identityID,
		UserID:   userID,
		Provider: "github",
		Subject:  "user-123",
	}
	identities := &memoryIdentityRepo{
		items: map[uuid.UUID]identitydomain.Identity{
			identityID: identity,
		},
		byKey: map[string]uuid.UUID{},
	}
	identities.byKey[identities.key(identity.Provider, identity.Subject)] = identityID

	clock := fixedClock{now: now.Add(5 * time.Minute)}
	svc := NewOAuthService(nil, identities, nil, nil, providers, subscriptions, clock, nil, Config{})

	updated, err := svc.Unsubscribe(ctx, userID, "github")
	if err != nil {
		t.Fatalf("Unsubscribe returned error: %v", err)
	}
	if updated.Status != subscriptiondomain.StatusRevoked {
		t.Fatalf("expected status revoked, got %s", updated.Status)
	}
	if updated.IdentityID != nil {
		t.Fatalf("expected identity to be cleared, got %v", updated.IdentityID)
	}
	if len(updated.ScopeGrants) != 0 {
		t.Fatalf("expected scope grants to be cleared, got %v", updated.ScopeGrants)
	}
	if !updated.UpdatedAt.Equal(clock.now) {
		t.Fatalf("expected updated at to use clock now, got %v", updated.UpdatedAt)
	}

	stored, err := subscriptions.FindByUserAndProvider(ctx, userID, providerID)
	if err != nil {
		t.Fatalf("FindByUserAndProvider returned error: %v", err)
	}
	if stored.Status != subscriptiondomain.StatusRevoked {
		t.Fatalf("expected stored status revoked, got %s", stored.Status)
	}
	if stored.IdentityID != nil {
		t.Fatalf("expected stored identity cleared, got %v", stored.IdentityID)
	}

	if _, err := identities.FindByID(ctx, identityID); !errors.Is(err, outbound.ErrNotFound) {
		t.Fatalf("expected identity to be deleted, got err=%v", err)
	}
}

type staticProviderResolver map[string]identityport.Provider

func (m staticProviderResolver) Provider(name string) (identityport.Provider, bool) {
	p, ok := m[name]
	return p, ok
}

type fixedClock struct {
	now time.Time
}

func (c fixedClock) Now() time.Time { return c.now }

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

type memoryServiceProviderRepo struct {
	items map[string]servicedomain.Provider
}

func (m *memoryServiceProviderRepo) FindByName(ctx context.Context, name string) (servicedomain.Provider, error) {
	if m.items == nil {
		return servicedomain.Provider{}, outbound.ErrNotFound
	}
	key := strings.ToLower(strings.TrimSpace(name))
	if provider, ok := m.items[key]; ok {
		return provider, nil
	}
	return servicedomain.Provider{}, outbound.ErrNotFound
}

func (m *memoryServiceProviderRepo) FindByID(ctx context.Context, id uuid.UUID) (servicedomain.Provider, error) {
	if m.items == nil {
		return servicedomain.Provider{}, outbound.ErrNotFound
	}
	for _, provider := range m.items {
		if provider.ID == id {
			return provider, nil
		}
	}
	return servicedomain.Provider{}, outbound.ErrNotFound
}

func (m *memoryServiceProviderRepo) List(ctx context.Context) ([]servicedomain.Provider, error) {
	if m.items == nil {
		return []servicedomain.Provider{}, nil
	}
	result := make([]servicedomain.Provider, 0, len(m.items))
	for _, provider := range m.items {
		result = append(result, provider)
	}
	return result, nil
}

type memorySubscriptionRepo struct {
	items map[uuid.UUID]subscriptiondomain.Subscription
	byKey map[string]uuid.UUID
}

func (m *memorySubscriptionRepo) key(userID uuid.UUID, providerID uuid.UUID) string {
	return userID.String() + "|" + providerID.String()
}

func (m *memorySubscriptionRepo) Create(ctx context.Context, subscription subscriptiondomain.Subscription) (subscriptiondomain.Subscription, error) {
	if m.items == nil {
		m.items = map[uuid.UUID]subscriptiondomain.Subscription{}
		m.byKey = map[string]uuid.UUID{}
	}
	if subscription.ID == uuid.Nil {
		subscription.ID = uuid.New()
	}
	key := m.key(subscription.UserID, subscription.ProviderID)
	if _, exists := m.byKey[key]; exists {
		return subscriptiondomain.Subscription{}, outbound.ErrConflict
	}
	clone := cloneSubscription(subscription)
	m.items[clone.ID] = clone
	m.byKey[key] = clone.ID
	return clone, nil
}

func (m *memorySubscriptionRepo) Update(ctx context.Context, subscription subscriptiondomain.Subscription) error {
	if m.items == nil {
		return outbound.ErrNotFound
	}
	if subscription.ID == uuid.Nil {
		return fmt.Errorf("missing id")
	}
	if _, ok := m.items[subscription.ID]; !ok {
		return outbound.ErrNotFound
	}
	clone := cloneSubscription(subscription)
	m.items[clone.ID] = clone
	m.byKey[m.key(clone.UserID, clone.ProviderID)] = clone.ID
	return nil
}

func (m *memorySubscriptionRepo) FindByUserAndProvider(ctx context.Context, userID uuid.UUID, providerID uuid.UUID) (subscriptiondomain.Subscription, error) {
	if m.items == nil {
		return subscriptiondomain.Subscription{}, outbound.ErrNotFound
	}
	key := m.key(userID, providerID)
	id, ok := m.byKey[key]
	if !ok {
		return subscriptiondomain.Subscription{}, outbound.ErrNotFound
	}
	return cloneSubscription(m.items[id]), nil
}

func (m *memorySubscriptionRepo) ListByUser(ctx context.Context, userID uuid.UUID) ([]subscriptiondomain.Subscription, error) {
	result := make([]subscriptiondomain.Subscription, 0)
	for _, subscription := range m.items {
		if subscription.UserID == userID {
			result = append(result, cloneSubscription(subscription))
		}
	}
	return result, nil
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

func cloneSubscription(subscription subscriptiondomain.Subscription) subscriptiondomain.Subscription {
	clone := subscription
	if subscription.ScopeGrants != nil {
		clone.ScopeGrants = append([]string(nil), subscription.ScopeGrants...)
	}
	if subscription.IdentityID != nil {
		id := *subscription.IdentityID
		clone.IdentityID = &id
	}
	return clone
}

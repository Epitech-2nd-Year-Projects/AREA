package auth

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	identitydomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/identity"
	servicedomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/service"
	sessiondomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/session"
	subscriptiondomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/subscription"
	userdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/user"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
	identityport "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound/identity"
	"github.com/google/uuid"
	"go.uber.org/zap"
)

// ErrProviderNotConfigured indicates the requested OAuth provider is unavailable
var ErrProviderNotConfigured = errors.New("auth: oauth provider not configured")

// ErrOAuthEmailMissing is returned when the provider payload does not include an email address
var ErrOAuthEmailMissing = errors.New("auth: oauth email missing")

// ErrIdentityOwnershipConflict is returned when attempting to reuse an identity owned by another user.
var ErrIdentityOwnershipConflict = errors.New("auth: identity already linked to another user")

// ErrSubscriptionNotSupported indicates the provider does not support automated subscriptions yet.
var ErrSubscriptionNotSupported = errors.New("auth: provider does not support subscriptions")

// ProviderResolver exposes configured OAuth providers by name
// Implementations are expected to return providers for normalized (lowercase) identifiers
type ProviderResolver interface {
	Provider(name string) (identityport.Provider, bool)
}

// OAuthService orchestrates OAuth-based authentication and identity persistence
type OAuthService struct {
	providers        ProviderResolver
	identities       identityport.Repository
	users            outbound.UserRepository
	sessions         outbound.SessionRepository
	serviceProviders outbound.ServiceProviderRepository
	subscriptions    outbound.SubscriptionRepository
	clock            Clock
	logger           *zap.Logger
	cfg              Config
}

// SubscriptionInitResult reports the outcome of initiating a subscription flow.
type SubscriptionInitResult struct {
	Authorization *identityport.AuthorizationResponse
	Subscription  *subscriptiondomain.Subscription
}

// SubscriptionOverview couples a persisted subscription with its provider metadata.
type SubscriptionOverview struct {
	Subscription subscriptiondomain.Subscription
	Provider     servicedomain.Provider
}

// NewOAuthService assembles an OAuth service from persistence stores and provider registry.
func NewOAuthService(providers ProviderResolver, identities identityport.Repository, users outbound.UserRepository, sessions outbound.SessionRepository, serviceProviders outbound.ServiceProviderRepository, subscriptions outbound.SubscriptionRepository, clock Clock, logger *zap.Logger, cfg Config) *OAuthService {
	if clock == nil {
		clock = systemClock{}
	}
	if logger == nil {
		logger = zap.NewNop()
	}
	if cfg.SessionTTL == 0 {
		cfg.SessionTTL = 24 * time.Hour
	}
	if cfg.CookieName == "" {
		cfg.CookieName = "area_session"
	}
	return &OAuthService{
		providers:        providers,
		identities:       identities,
		users:            users,
		sessions:         sessions,
		serviceProviders: serviceProviders,
		subscriptions:    subscriptions,
		clock:            clock,
		logger:           logger,
		cfg:              cfg,
	}
}

// AuthorizationURL delegates to the provider to generate an authorization redirect payload
func (s *OAuthService) AuthorizationURL(ctx context.Context, provider string, req identityport.AuthorizationRequest) (identityport.AuthorizationResponse, error) {
	prov, normalized, err := s.resolveProvider(provider)
	if err != nil {
		return identityport.AuthorizationResponse{}, fmt.Errorf("auth.OAuthService.AuthorizationURL: %w", err)
	}

	resp, err := prov.AuthorizationURL(ctx, req)
	if err != nil {
		return identityport.AuthorizationResponse{}, fmt.Errorf("auth.OAuthService.AuthorizationURL[%s]: %w", normalized, err)
	}
	return resp, nil
}

// Exchange processes the authorization code, persists the identity, and issues a session
func (s *OAuthService) Exchange(ctx context.Context, provider string, code string, req identityport.ExchangeRequest, meta Metadata) (LoginResult, identitydomain.Identity, error) {
	if s.identities == nil || s.users == nil || s.sessions == nil {
		return LoginResult{}, identitydomain.Identity{}, fmt.Errorf("auth.OAuthService.Exchange: persistence not configured")
	}

	prov, normalized, err := s.resolveProvider(provider)
	if err != nil {
		return LoginResult{}, identitydomain.Identity{}, fmt.Errorf("auth.OAuthService.Exchange: %w", err)
	}

	exchange, err := prov.Exchange(ctx, code, req)
	if err != nil {
		return LoginResult{}, identitydomain.Identity{}, fmt.Errorf("auth.OAuthService.Exchange[%s]: %w", normalized, err)
	}
	if exchange.Profile.Empty() {
		return LoginResult{}, identitydomain.Identity{}, fmt.Errorf("auth.OAuthService.Exchange[%s]: empty profile", normalized)
	}

	now := s.clock.Now().UTC()

	user, identity, err := s.upsertIdentity(ctx, normalized, exchange, now)
	if err != nil {
		return LoginResult{}, identitydomain.Identity{}, err
	}

	login, err := s.issueSession(ctx, user, normalized, meta, now)
	if err != nil {
		return LoginResult{}, identitydomain.Identity{}, err
	}

	return login, identity, nil
}

// ListProviders returns every service provider recorded in the catalog.
func (s *OAuthService) ListProviders(ctx context.Context) ([]servicedomain.Provider, error) {
	if s.serviceProviders == nil {
		return nil, fmt.Errorf("auth.OAuthService.ListProviders: serviceProviders repository missing")
	}

	providers, err := s.serviceProviders.List(ctx)
	if err != nil {
		return nil, fmt.Errorf("auth.OAuthService.ListProviders: serviceProviders.List: %w", err)
	}
	return providers, nil
}

// ListSubscriptions enumerates the user's subscriptions together with provider metadata.
func (s *OAuthService) ListSubscriptions(ctx context.Context, userID uuid.UUID) ([]SubscriptionOverview, error) {
	if s.subscriptions == nil || s.serviceProviders == nil {
		return nil, fmt.Errorf("auth.OAuthService.ListSubscriptions: repositories missing")
	}
	if userID == uuid.Nil {
		return nil, fmt.Errorf("auth.OAuthService.ListSubscriptions: missing user id")
	}

	items, err := s.subscriptions.ListByUser(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("auth.OAuthService.ListSubscriptions: subscriptions.ListByUser: %w", err)
	}

	overviews := make([]SubscriptionOverview, 0, len(items))
	for _, item := range items {
		provider, providerErr := s.serviceProviders.FindByID(ctx, item.ProviderID)
		if providerErr != nil {
			return nil, fmt.Errorf("auth.OAuthService.ListSubscriptions: serviceProviders.FindByID: %w", providerErr)
		}
		overviews = append(overviews, SubscriptionOverview{
			Subscription: item,
			Provider:     provider,
		})
	}
	return overviews, nil
}

// Unsubscribe revokes the user's access to the provider and clears stored credentials.
func (s *OAuthService) Unsubscribe(ctx context.Context, userID uuid.UUID, provider string) (subscriptiondomain.Subscription, error) {
	if s.subscriptions == nil || s.serviceProviders == nil {
		return subscriptiondomain.Subscription{}, fmt.Errorf("auth.OAuthService.Unsubscribe: repositories missing")
	}
	if userID == uuid.Nil {
		return subscriptiondomain.Subscription{}, fmt.Errorf("auth.OAuthService.Unsubscribe: missing user id")
	}

	normalized := strings.ToLower(strings.TrimSpace(provider))
	if normalized == "" {
		return subscriptiondomain.Subscription{}, fmt.Errorf("auth.OAuthService.Unsubscribe: provider name empty")
	}

	providerRecord, err := s.serviceProviders.FindByName(ctx, normalized)
	if err != nil {
		if errors.Is(err, outbound.ErrNotFound) {
			return subscriptiondomain.Subscription{}, fmt.Errorf("auth.OAuthService.Unsubscribe[%s]: %w", normalized, ErrProviderNotConfigured)
		}
		return subscriptiondomain.Subscription{}, fmt.Errorf("auth.OAuthService.Unsubscribe[%s]: serviceProviders.FindByName: %w", normalized, err)
	}

	subscription, err := s.subscriptions.FindByUserAndProvider(ctx, userID, providerRecord.ID)
	if err != nil {
		return subscriptiondomain.Subscription{}, fmt.Errorf("auth.OAuthService.Unsubscribe[%s]: subscriptions.FindByUserAndProvider: %w", providerRecord.Name, err)
	}

	now := s.clock.Now().UTC()
	subscription.Status = subscriptiondomain.StatusRevoked
	subscription.ScopeGrants = nil
	subscription.UpdatedAt = now

	if subscription.IdentityID != nil {
		if s.identities != nil {
			if delErr := s.identities.Delete(ctx, *subscription.IdentityID); delErr != nil && !errors.Is(delErr, outbound.ErrNotFound) {
				return subscriptiondomain.Subscription{}, fmt.Errorf("auth.OAuthService.Unsubscribe[%s]: identities.Delete: %w", providerRecord.Name, delErr)
			}
		}
		subscription.IdentityID = nil
	}

	if err := s.subscriptions.Update(ctx, subscription); err != nil {
		return subscriptiondomain.Subscription{}, fmt.Errorf("auth.OAuthService.Unsubscribe[%s]: subscriptions.Update: %w", providerRecord.Name, err)
	}

	return subscription, nil
}

// BeginSubscription prepares a subscription flow for the specified provider.
func (s *OAuthService) BeginSubscription(ctx context.Context, user userdomain.User, provider string, req identityport.AuthorizationRequest) (SubscriptionInitResult, error) {
	if s.subscriptions == nil || s.serviceProviders == nil {
		return SubscriptionInitResult{}, fmt.Errorf("auth.OAuthService.BeginSubscription: persistence not configured")
	}
	if user.ID == uuid.Nil {
		return SubscriptionInitResult{}, fmt.Errorf("auth.OAuthService.BeginSubscription: missing user")
	}

	normalized := strings.ToLower(strings.TrimSpace(provider))
	if normalized == "" {
		return SubscriptionInitResult{}, fmt.Errorf("auth.OAuthService.BeginSubscription: provider name empty")
	}

	providerRecord, err := s.serviceProviders.FindByName(ctx, normalized)
	if err != nil {
		if errors.Is(err, outbound.ErrNotFound) {
			return SubscriptionInitResult{}, fmt.Errorf("auth.OAuthService.BeginSubscription[%s]: %w", normalized, ErrProviderNotConfigured)
		}
		return SubscriptionInitResult{}, fmt.Errorf("auth.OAuthService.BeginSubscription[%s]: serviceProviders.FindByName: %w", normalized, err)
	}

	now := s.clock.Now().UTC()

	switch providerRecord.OAuthType {
	case servicedomain.OAuthTypeNone:
		subscription, ensureErr := s.ensureSubscription(ctx, user.ID, providerRecord, nil, nil, now)
		if ensureErr != nil {
			return SubscriptionInitResult{}, ensureErr
		}
		return SubscriptionInitResult{Subscription: &subscription}, nil
	case servicedomain.OAuthTypeAPIKey:
		subscription, ensureErr := s.ensureSubscription(ctx, user.ID, providerRecord, nil, nil, now)
		if ensureErr != nil {
			return SubscriptionInitResult{}, ensureErr
		}
		return SubscriptionInitResult{Subscription: &subscription}, nil
	case servicedomain.OAuthTypeOAuth2:
		prov, _, resolveErr := s.resolveProvider(normalized)
		if resolveErr != nil {
			return SubscriptionInitResult{}, fmt.Errorf("auth.OAuthService.BeginSubscription[%s]: %w", normalized, resolveErr)
		}
		resp, authErr := prov.AuthorizationURL(ctx, req)
		if authErr != nil {
			return SubscriptionInitResult{}, fmt.Errorf("auth.OAuthService.BeginSubscription[%s]: %w", normalized, authErr)
		}
		return SubscriptionInitResult{Authorization: &resp}, nil
	default:
		return SubscriptionInitResult{}, fmt.Errorf("auth.OAuthService.BeginSubscription[%s]: %w", normalized, ErrSubscriptionNotSupported)
	}
}

// CompleteSubscription finalises a provider subscription by exchanging the OAuth code and persisting tokens.
func (s *OAuthService) CompleteSubscription(ctx context.Context, user userdomain.User, provider string, code string, req identityport.ExchangeRequest) (subscriptiondomain.Subscription, identitydomain.Identity, error) {
	if s.identities == nil || s.serviceProviders == nil || s.subscriptions == nil {
		return subscriptiondomain.Subscription{}, identitydomain.Identity{}, fmt.Errorf("auth.OAuthService.CompleteSubscription: persistence not configured")
	}
	if user.ID == uuid.Nil {
		return subscriptiondomain.Subscription{}, identitydomain.Identity{}, fmt.Errorf("auth.OAuthService.CompleteSubscription: missing user")
	}

	normalized := strings.ToLower(strings.TrimSpace(provider))
	if normalized == "" {
		return subscriptiondomain.Subscription{}, identitydomain.Identity{}, fmt.Errorf("auth.OAuthService.CompleteSubscription: provider name empty")
	}

	providerRecord, err := s.serviceProviders.FindByName(ctx, normalized)
	if err != nil {
		if errors.Is(err, outbound.ErrNotFound) {
			return subscriptiondomain.Subscription{}, identitydomain.Identity{}, fmt.Errorf("auth.OAuthService.CompleteSubscription[%s]: %w", normalized, ErrProviderNotConfigured)
		}
		return subscriptiondomain.Subscription{}, identitydomain.Identity{}, fmt.Errorf("auth.OAuthService.CompleteSubscription[%s]: serviceProviders.FindByName: %w", normalized, err)
	}
	if providerRecord.OAuthType != servicedomain.OAuthTypeOAuth2 {
		return subscriptiondomain.Subscription{}, identitydomain.Identity{}, fmt.Errorf("auth.OAuthService.CompleteSubscription[%s]: %w", normalized, ErrSubscriptionNotSupported)
	}

	prov, _, resolveErr := s.resolveProvider(normalized)
	if resolveErr != nil {
		return subscriptiondomain.Subscription{}, identitydomain.Identity{}, fmt.Errorf("auth.OAuthService.CompleteSubscription[%s]: %w", normalized, resolveErr)
	}

	exchange, exchErr := prov.Exchange(ctx, code, req)
	if exchErr != nil {
		s.logger.Error("oauth provider exchange failed",
			zap.String("provider", normalized),
			zap.String("redirect_uri", strings.TrimSpace(req.RedirectURI)),
			zap.Error(exchErr))
		return subscriptiondomain.Subscription{}, identitydomain.Identity{}, fmt.Errorf("auth.OAuthService.CompleteSubscription[%s]: %w", normalized, exchErr)
	}
	if exchange.Profile.Empty() {
		return subscriptiondomain.Subscription{}, identitydomain.Identity{}, fmt.Errorf("auth.OAuthService.CompleteSubscription[%s]: empty profile", normalized)
	}

	now := s.clock.Now().UTC()

	identity, identityErr := s.linkIdentityToUser(ctx, user, normalized, exchange, now)
	if identityErr != nil {
		s.logger.Error("oauth identity link failed",
			zap.String("provider", normalized),
			zap.Error(identityErr))
		return subscriptiondomain.Subscription{}, identitydomain.Identity{}, identityErr
	}

	scopeGrants := selectScopes(exchange.Token.Scope, identity.Scopes)
	subscription, ensureErr := s.ensureSubscription(ctx, user.ID, providerRecord, &identity.ID, scopeGrants, now)
	if ensureErr != nil {
		s.logger.Error("subscription persistence failed",
			zap.String("provider", normalized),
			zap.String("user_id", user.ID.String()),
			zap.String("identity_id", identity.ID.String()),
			zap.Error(ensureErr))
		return subscriptiondomain.Subscription{}, identity, ensureErr
	}

	return subscription, identity, nil
}

// LinkService completes an OAuth exchange for an authenticated user and records the subscription.
func (s *OAuthService) LinkService(ctx context.Context, user userdomain.User, provider string, code string, req identityport.ExchangeRequest) (subscriptiondomain.Subscription, identitydomain.Identity, error) {
	return s.CompleteSubscription(ctx, user, provider, code, req)
}

// ListIdentities lists linked identities for the specified user
func (s *OAuthService) ListIdentities(ctx context.Context, userID uuid.UUID) ([]identitydomain.Identity, error) {
	if s == nil || s.identities == nil {
		return nil, fmt.Errorf("auth.OAuthService.ListIdentities: identities repository unavailable")
	}
	if userID == uuid.Nil {
		return nil, fmt.Errorf("auth.OAuthService.ListIdentities: missing user id")
	}

	items, err := s.identities.ListByUser(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("auth.OAuthService.ListIdentities: identities.ListByUser: %w", err)
	}
	return items, nil
}

func (s *OAuthService) resolveProvider(name string) (identityport.Provider, string, error) {
	if s.providers == nil {
		return nil, "", fmt.Errorf("auth.OAuthService.resolveProvider: providers unavailable")
	}
	normalized := strings.ToLower(strings.TrimSpace(name))
	if normalized == "" {
		return nil, "", fmt.Errorf("auth.OAuthService.resolveProvider: provider name empty")
	}
	prov, ok := s.providers.Provider(normalized)
	if !ok {
		return nil, normalized, fmt.Errorf("auth.OAuthService.resolveProvider: %s: %w", normalized, ErrProviderNotConfigured)
	}
	return prov, normalized, nil
}

func (s *OAuthService) upsertIdentity(ctx context.Context, provider string, exchange identityport.TokenExchange, now time.Time) (userdomain.User, identitydomain.Identity, error) {
	profile := exchange.Profile

	identity, err := s.identities.FindByProviderSubject(ctx, provider, profile.Subject)
	if err != nil && !errors.Is(err, outbound.ErrNotFound) {
		return userdomain.User{}, identitydomain.Identity{}, fmt.Errorf("auth.OAuthService.upsertIdentity[%s]: identities.FindByProviderSubject: %w", provider, err)
	}

	token := exchange.Token
	expiresAt := identity.ExpiresAt
	if !token.ExpiresAt.IsZero() {
		expiry := token.ExpiresAt
		expiresAt = &expiry
	}

	scopes := token.Scope

	if errors.Is(err, outbound.ErrNotFound) {
		user, createErr := s.resolveOrCreateUser(ctx, profile, now)
		if createErr != nil {
			return userdomain.User{}, identitydomain.Identity{}, fmt.Errorf("auth.OAuthService.upsertIdentity[%s]: %w", provider, createErr)
		}

		identity = identitydomain.Identity{
			ID:        uuid.New(),
			UserID:    user.ID,
			Provider:  provider,
			Subject:   profile.Subject,
			CreatedAt: now,
			UpdatedAt: now,
		}
		identity = identity.WithTokens(token.AccessToken, token.RefreshToken, expiresAt, scopes)

		created, createIdentityErr := s.identities.Create(ctx, identity)
		if createIdentityErr != nil {
			return userdomain.User{}, identitydomain.Identity{}, fmt.Errorf("auth.OAuthService.upsertIdentity[%s]: identities.Create: %w", provider, createIdentityErr)
		}
		return user, created, nil
	}

	refreshToken := token.RefreshToken
	if refreshToken == "" {
		refreshToken = identity.RefreshToken
	}
	if len(scopes) == 0 {
		scopes = identity.Scopes
	}

	updated := identity.WithTokens(token.AccessToken, refreshToken, expiresAt, scopes)
	updated.Provider = provider
	updated.Subject = profile.Subject
	updated.UserID = identity.UserID
	updated.CreatedAt = identity.CreatedAt
	updated.UpdatedAt = now

	if err := s.identities.Update(ctx, updated); err != nil {
		return userdomain.User{}, identitydomain.Identity{}, fmt.Errorf("auth.OAuthService.upsertIdentity[%s]: identities.Update: %w", provider, err)
	}

	user, userErr := s.users.FindByID(ctx, identity.UserID)
	if userErr != nil {
		return userdomain.User{}, identitydomain.Identity{}, fmt.Errorf("auth.OAuthService.upsertIdentity[%s]: users.FindByID: %w", provider, userErr)
	}

	return user, updated, nil
}

func (s *OAuthService) ensureSubscription(ctx context.Context, userID uuid.UUID, provider servicedomain.Provider, identityID *uuid.UUID, scopeGrants []string, now time.Time) (subscriptiondomain.Subscription, error) {
	if s.subscriptions == nil {
		return subscriptiondomain.Subscription{}, fmt.Errorf("auth.OAuthService.ensureSubscription[%s]: subscriptions repository missing", provider.Name)
	}

	subscription, err := s.subscriptions.FindByUserAndProvider(ctx, userID, provider.ID)
	if err != nil {
		if !errors.Is(err, outbound.ErrNotFound) {
			return subscriptiondomain.Subscription{}, fmt.Errorf("auth.OAuthService.ensureSubscription[%s]: subscriptions.FindByUserAndProvider: %w", provider.Name, err)
		}

		create := subscriptiondomain.Subscription{
			ID:          uuid.New(),
			UserID:      userID,
			ProviderID:  provider.ID,
			IdentityID:  cloneUUID(identityID),
			Status:      subscriptiondomain.StatusActive,
			ScopeGrants: cloneStrings(scopeGrants),
			CreatedAt:   now,
			UpdatedAt:   now,
		}

		created, createErr := s.subscriptions.Create(ctx, create)
		if createErr != nil {
			return subscriptiondomain.Subscription{}, fmt.Errorf("auth.OAuthService.ensureSubscription[%s]: subscriptions.Create: %w", provider.Name, createErr)
		}
		return created, nil
	}

	subscription.IdentityID = cloneUUID(identityID)
	if scopeGrants != nil {
		subscription.ScopeGrants = cloneStrings(scopeGrants)
	} else if subscription.ScopeGrants != nil {
		subscription.ScopeGrants = cloneStrings(subscription.ScopeGrants)
	}
	subscription.Status = subscriptiondomain.StatusActive
	subscription.UpdatedAt = now

	if err := s.subscriptions.Update(ctx, subscription); err != nil {
		return subscriptiondomain.Subscription{}, fmt.Errorf("auth.OAuthService.ensureSubscription[%s]: subscriptions.Update: %w", provider.Name, err)
	}
	return subscription, nil
}

func (s *OAuthService) linkIdentityToUser(ctx context.Context, user userdomain.User, provider string, exchange identityport.TokenExchange, now time.Time) (identitydomain.Identity, error) {
	if s.identities == nil {
		return identitydomain.Identity{}, fmt.Errorf("auth.OAuthService.linkIdentityToUser: identities repository missing")
	}

	profile := exchange.Profile
	identity, err := s.identities.FindByProviderSubject(ctx, provider, profile.Subject)
	if err != nil && !errors.Is(err, outbound.ErrNotFound) {
		return identitydomain.Identity{}, fmt.Errorf("auth.OAuthService.linkIdentityToUser[%s]: identities.FindByProviderSubject: %w", provider, err)
	}

	token := exchange.Token
	var expiresAt *time.Time
	if identity.ExpiresAt != nil {
		copyExpiry := identity.ExpiresAt.UTC()
		expiresAt = &copyExpiry
	}
	if !token.ExpiresAt.IsZero() {
		expiry := token.ExpiresAt
		expiresAt = &expiry
	}

	scopes := selectScopes(token.Scope, identity.Scopes)

	if errors.Is(err, outbound.ErrNotFound) {
		identity = identitydomain.Identity{
			ID:        uuid.New(),
			UserID:    user.ID,
			Provider:  provider,
			Subject:   profile.Subject,
			CreatedAt: now,
			UpdatedAt: now,
		}
		identity = identity.WithTokens(token.AccessToken, token.RefreshToken, expiresAt, cloneStrings(scopes))

		created, createErr := s.identities.Create(ctx, identity)
		if createErr != nil {
			return identitydomain.Identity{}, fmt.Errorf("auth.OAuthService.linkIdentityToUser[%s]: identities.Create: %w", provider, createErr)
		}
		return created, nil
	}

	if identity.UserID != user.ID {
		return identitydomain.Identity{}, ErrIdentityOwnershipConflict
	}

	refreshToken := token.RefreshToken
	if refreshToken == "" {
		refreshToken = identity.RefreshToken
	}
	if len(scopes) == 0 {
		scopes = identity.Scopes
	}

	updated := identity.WithTokens(token.AccessToken, refreshToken, expiresAt, cloneStrings(scopes))
	updated.Provider = provider
	updated.Subject = profile.Subject
	updated.UserID = identity.UserID
	updated.CreatedAt = identity.CreatedAt
	updated.UpdatedAt = now

	if err := s.identities.Update(ctx, updated); err != nil {
		return identitydomain.Identity{}, fmt.Errorf("auth.OAuthService.linkIdentityToUser[%s]: identities.Update: %w", provider, err)
	}

	return updated, nil
}

func (s *OAuthService) resolveOrCreateUser(ctx context.Context, profile identitydomain.Profile, now time.Time) (userdomain.User, error) {
	email := strings.TrimSpace(strings.ToLower(profile.Email))
	if email == "" {
		return userdomain.User{}, ErrOAuthEmailMissing
	}

	user, err := s.users.FindByEmail(ctx, email)
	if err == nil {
		if !user.Active() {
			user.Status = userdomain.StatusActive
			user.UpdatedAt = now
			if updateErr := s.users.Update(ctx, user); updateErr != nil {
				s.logger.Warn("failed to activate user from oauth", zap.Error(updateErr))
			}
		}
		return user, nil
	}

	if !errors.Is(err, outbound.ErrNotFound) {
		return userdomain.User{}, fmt.Errorf("auth.OAuthService.resolveOrCreateUser: users.FindByEmail: %w", err)
	}

	user = userdomain.User{
		ID:        uuid.New(),
		Email:     email,
		Status:    userdomain.StatusActive,
		Role:      userdomain.RoleMember,
		CreatedAt: now,
		UpdatedAt: now,
	}

	created, createErr := s.users.Create(ctx, user)
	if createErr != nil {
		if errors.Is(createErr, outbound.ErrConflict) {
			existing, lookupErr := s.users.FindByEmail(ctx, email)
			if lookupErr != nil {
				return userdomain.User{}, fmt.Errorf("auth.OAuthService.resolveOrCreateUser: users.FindByEmail(after conflict): %w", lookupErr)
			}
			return existing, nil
		}
		return userdomain.User{}, fmt.Errorf("auth.OAuthService.resolveOrCreateUser: users.Create: %w", createErr)
	}

	return created, nil
}

func (s *OAuthService) issueSession(ctx context.Context, user userdomain.User, provider string, meta Metadata, now time.Time) (LoginResult, error) {
	if s.sessions == nil {
		return LoginResult{}, fmt.Errorf("auth.OAuthService.issueSession: session repository missing")
	}

	session := s.buildSession(user, provider, meta, now)
	created, err := s.sessions.Create(ctx, session)
	if err != nil {
		return LoginResult{}, fmt.Errorf("auth.OAuthService.issueSession: sessions.Create: %w", err)
	}

	user.LastLoginAt = &now
	user.UpdatedAt = now
	if err := s.users.Update(ctx, user); err != nil {
		s.logger.Warn("failed to update last login from oauth", zap.Error(err))
	}

	return LoginResult{User: user, Session: created, CookieName: s.cfg.CookieName}, nil
}

func (s *OAuthService) buildSession(user userdomain.User, provider string, meta Metadata, now time.Time) sessiondomain.Session {
	return sessiondomain.Session{
		ID:           uuid.New(),
		UserID:       user.ID,
		IssuedAt:     now,
		ExpiresAt:    now.Add(s.cfg.SessionTTL),
		IP:           meta.ClientIP,
		UserAgent:    meta.UserAgent,
		AuthProvider: provider,
	}
}

func selectScopes(primary []string, fallbacks ...[]string) []string {
	if len(primary) > 0 {
		return cloneStrings(primary)
	}
	for _, candidate := range fallbacks {
		if len(candidate) > 0 {
			return cloneStrings(candidate)
		}
	}
	return nil
}

func cloneStrings(values []string) []string {
	if len(values) == 0 {
		return nil
	}
	clone := make([]string, len(values))
	copy(clone, values)
	return clone
}

func cloneUUID(value *uuid.UUID) *uuid.UUID {
	if value == nil {
		return nil
	}
	clone := *value
	return &clone
}

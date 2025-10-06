package auth

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	identitydomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/identity"
	sessiondomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/session"
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

// ProviderResolver exposes configured OAuth providers by name
// Implementations are expected to return providers for normalized (lowercase) identifiers
type ProviderResolver interface {
	Provider(name string) (identityport.Provider, bool)
}

// OAuthService orchestrates OAuth-based authentication and identity persistence
type OAuthService struct {
	providers  ProviderResolver
	identities identityport.Repository
	users      outbound.UserRepository
	sessions   outbound.SessionRepository
	clock      Clock
	logger     *zap.Logger
	cfg        Config
}

// NewOAuthService assembles an OAuth service from persistence stores and provider registry
func NewOAuthService(providers ProviderResolver, identities identityport.Repository, users outbound.UserRepository, sessions outbound.SessionRepository, clock Clock, logger *zap.Logger, cfg Config) *OAuthService {
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
		providers:  providers,
		identities: identities,
		users:      users,
		sessions:   sessions,
		clock:      clock,
		logger:     logger,
		cfg:        cfg,
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

	login, err := s.issueSession(ctx, user, meta, now)
	if err != nil {
		return LoginResult{}, identitydomain.Identity{}, err
	}

	return login, identity, nil
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

func (s *OAuthService) issueSession(ctx context.Context, user userdomain.User, meta Metadata, now time.Time) (LoginResult, error) {
	if s.sessions == nil {
		return LoginResult{}, fmt.Errorf("auth.OAuthService.issueSession: session repository missing")
	}

	session := s.buildSession(user, meta, now)
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

func (s *OAuthService) buildSession(user userdomain.User, meta Metadata, now time.Time) sessiondomain.Session {
	return sessiondomain.Session{
		ID:        uuid.New(),
		UserID:    user.ID,
		IssuedAt:  now,
		ExpiresAt: now.Add(s.cfg.SessionTTL),
		IP:        meta.ClientIP,
		UserAgent: meta.UserAgent,
	}
}

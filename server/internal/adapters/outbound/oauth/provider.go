package oauth

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"

	identitydomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/identity"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/oauth2"
	identityport "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound/identity"
)

// ProviderCredentials wires runtime secrets and redirect metadata for a provider
type ProviderCredentials struct {
	ClientID     string
	ClientSecret string
	RedirectURI  string
	Scopes       []string
}

// ManagerConfig configures the OAuth provider manager
// Allowed restricts the providers that should be instantiated; when empty all configured providers are used
type ManagerConfig struct {
	Allowed   []string
	Providers map[string]ProviderCredentials
}

type provider struct {
	name          string
	descriptor    ProviderDescriptor
	client        *oauth2.Client
	httpClient    oauth2.HTTPClient
	redirectURI   string
	defaultScopes []string
	userAgent     string
}

type providerConfig struct {
	oauthOptions []oauth2.Option
	httpClient   oauth2.HTTPClient
	userAgent    string
}

// ProviderOption configures a provider instance before use
type ProviderOption func(*providerConfig)

// WithProviderHTTPClient reuses the provided http client for token and user info requests
func WithProviderHTTPClient(client oauth2.HTTPClient) ProviderOption {
	return func(cfg *providerConfig) {
		if client != nil {
			cfg.httpClient = client
			cfg.oauthOptions = append(cfg.oauthOptions, oauth2.WithHTTPClient(client))
		}
	}
}

// WithProviderClock injects a custom clock into the oauth client
func WithProviderClock(clock oauth2.Clock) ProviderOption {
	return func(cfg *providerConfig) {
		if clock != nil {
			cfg.oauthOptions = append(cfg.oauthOptions, oauth2.WithClock(clock))
		}
	}
}

// WithProviderUserAgent overrides the default user agent header for user info requests
func WithProviderUserAgent(agent string) ProviderOption {
	return func(cfg *providerConfig) {
		if strings.TrimSpace(agent) != "" {
			cfg.userAgent = agent
		}
	}
}

// NewProvider builds an OAuth provider implementation from its descriptor and credentials
func NewProvider(name string, descriptor ProviderDescriptor, creds ProviderCredentials, opts ...ProviderOption) (identityport.Provider, error) {
	name = strings.ToLower(strings.TrimSpace(name))
	if name == "" {
		return nil, fmt.Errorf("oauth.NewProvider: name is required")
	}
	if strings.TrimSpace(creds.ClientID) == "" {
		return nil, fmt.Errorf("oauth.NewProvider[%s]: client id is required", name)
	}
	if strings.TrimSpace(descriptor.AuthorizationURL) == "" {
		return nil, fmt.Errorf("oauth.NewProvider[%s]: authorization url missing", name)
	}
	if strings.TrimSpace(descriptor.TokenURL) == "" {
		return nil, fmt.Errorf("oauth.NewProvider[%s]: token url missing", name)
	}
	if strings.TrimSpace(descriptor.UserInfoURL) == "" {
		return nil, fmt.Errorf("oauth.NewProvider[%s]: userinfo url missing", name)
	}
	if descriptor.ProfileExtractor == nil {
		return nil, fmt.Errorf("oauth.NewProvider[%s]: profile extractor missing", name)
	}
	if strings.TrimSpace(creds.RedirectURI) == "" {
		return nil, fmt.Errorf("oauth.NewProvider[%s]: redirect uri missing", name)
	}

	cfg := providerConfig{}
	for _, opt := range opts {
		if opt != nil {
			opt(&cfg)
		}
	}

	oauthCfg := oauth2.Config{
		Name:         descriptor.DisplayName,
		ClientID:     creds.ClientID,
		ClientSecret: creds.ClientSecret,
		AuthURL:      descriptor.AuthorizationURL,
		TokenURL:     descriptor.TokenURL,
		UserInfoURL:  descriptor.UserInfoURL,
		Scopes:       fallbackScopes(creds.Scopes, descriptor.DefaultScopes),
		Prompt:       descriptor.DefaultPrompt,
		Audience:     descriptor.Audience,
	}

	client, err := oauth2.NewClient(oauthCfg, cfg.oauthOptions...)
	if err != nil {
		return nil, fmt.Errorf("oauth.NewProvider[%s]: new oauth client: %w", name, err)
	}

	httpClient := cfg.httpClient
	if httpClient == nil {
		httpClient = http.DefaultClient
	}

	userAgent := cfg.userAgent
	if userAgent == "" {
		userAgent = descriptor.UserInfoHeaders["User-Agent"]
		if userAgent == "" {
			userAgent = "AREA-Server"
		}
	}

	return &provider{
		name:          name,
		descriptor:    descriptor,
		client:        client,
		httpClient:    httpClient,
		redirectURI:   creds.RedirectURI,
		defaultScopes: fallbackScopes(creds.Scopes, descriptor.DefaultScopes),
		userAgent:     userAgent,
	}, nil
}

// NewManager constructs providers according to configuration and registry definitions
func NewManager(registry Registry, cfg ManagerConfig, opts ...ProviderOption) (*Manager, error) {
	if registry == nil {
		registry = BuiltIn()
	}
	if cfg.Providers == nil {
		cfg.Providers = make(map[string]ProviderCredentials)
	}

	names := cfg.Allowed
	if len(names) == 0 {
		names = make([]string, 0, len(cfg.Providers))
		for name := range cfg.Providers {
			names = append(names, name)
		}
	}

	providers := make(map[string]identityport.Provider, len(names))
	for _, name := range names {
		key := strings.ToLower(strings.TrimSpace(name))
		if key == "" {
			continue
		}

		descriptor, ok := registry[key]
		if !ok {
			return nil, fmt.Errorf("oauth.NewManager: descriptor for %s not found", key)
		}
		creds, ok := cfg.Providers[key]
		if !ok {
			return nil, fmt.Errorf("oauth.NewManager: credentials for %s not configured", key)
		}

		provider, err := NewProvider(key, descriptor, creds, opts...)
		if err != nil {
			return nil, err
		}
		providers[key] = provider
	}

	return &Manager{providers: providers}, nil
}

// Manager exposes resolved providers keyed by name
type Manager struct {
	providers map[string]identityport.Provider
}

// Provider returns the provider implementation for the requested name
func (m *Manager) Provider(name string) (identityport.Provider, bool) {
	if m == nil {
		return nil, false
	}
	provider, ok := m.providers[strings.ToLower(strings.TrimSpace(name))]
	return provider, ok
}

// Names lists the registered provider identifiers
func (m *Manager) Names() []string {
	if m == nil {
		return nil
	}
	result := make([]string, 0, len(m.providers))
	for name := range m.providers {
		result = append(result, name)
	}
	return result
}

func (p *provider) Name() string {
	return p.name
}

func (p *provider) AuthorizationURL(ctx context.Context, req identityport.AuthorizationRequest) (identityport.AuthorizationResponse, error) {
	redirect := strings.TrimSpace(req.RedirectURI)
	if redirect == "" {
		redirect = p.redirectURI
	}
	if redirect == "" {
		return identityport.AuthorizationResponse{}, fmt.Errorf("oauth.Provider[%s].AuthorizationURL: redirect uri missing", p.name)
	}

	scopes := req.Scopes
	if len(scopes) == 0 {
		scopes = p.defaultScopes
	}

	extra := make(map[string]string, len(p.descriptor.AuthorizationParams))
	for key, value := range p.descriptor.AuthorizationParams {
		extra[key] = value
	}

	oauthResp, err := p.client.AuthorizationURL(ctx, oauth2.AuthorizationRequest{
		RedirectURI: redirect,
		Scopes:      scopes,
		State:       req.State,
		Prompt:      firstNonEmpty(req.Prompt, p.descriptor.DefaultPrompt),
		PKCE:        req.UsePKCE,
		Extra:       extra,
	})
	if err != nil {
		return identityport.AuthorizationResponse{}, fmt.Errorf("oauth.Provider[%s].AuthorizationURL: %w", p.name, err)
	}

	return identityport.AuthorizationResponse{
		AuthorizationURL:    oauthResp.URL,
		State:               oauthResp.State,
		CodeVerifier:        oauthResp.CodeVerifier,
		CodeChallenge:       oauthResp.CodeChallenge,
		CodeChallengeMethod: oauthResp.CodeChallengeMethod,
	}, nil
}

func (p *provider) Exchange(ctx context.Context, code string, req identityport.ExchangeRequest) (identityport.TokenExchange, error) {
	redirect := strings.TrimSpace(req.RedirectURI)
	if redirect == "" {
		redirect = p.redirectURI
	}
	if redirect == "" {
		return identityport.TokenExchange{}, fmt.Errorf("oauth.Provider[%s].Exchange: redirect uri missing", p.name)
	}

	token, err := p.client.Exchange(ctx, oauth2.ExchangeRequest{
		Code:         code,
		RedirectURI:  redirect,
		CodeVerifier: req.CodeVerifier,
	})
	if err != nil {
		return identityport.TokenExchange{}, fmt.Errorf("oauth.Provider[%s].Exchange: %w", p.name, err)
	}

	profile, profileRaw, err := p.fetchProfile(ctx, token.AccessToken)
	if err != nil {
		return identityport.TokenExchange{}, fmt.Errorf("oauth.Provider[%s].Exchange: %w", p.name, err)
	}

	return identityport.TokenExchange{
		Token:   token,
		Profile: profile,
		Raw: map[string]any{
			"token":   token.Raw,
			"profile": profileRaw,
		},
	}, nil
}

func (p *provider) Refresh(ctx context.Context, identity identitydomain.Identity) (identityport.TokenExchange, error) {
	if strings.TrimSpace(identity.RefreshToken) == "" {
		return identityport.TokenExchange{}, fmt.Errorf("oauth.Provider[%s].Refresh: refresh token missing", p.name)
	}

	scopes := identity.Scopes
	if len(scopes) == 0 {
		scopes = p.defaultScopes
	}

	token, err := p.client.Refresh(ctx, oauth2.RefreshRequest{
		RefreshToken: identity.RefreshToken,
		Scopes:       scopes,
	})
	if err != nil {
		return identityport.TokenExchange{}, fmt.Errorf("oauth.Provider[%s].Refresh: %w", p.name, err)
	}

	profile, profileRaw, err := p.fetchProfile(ctx, token.AccessToken)
	if err != nil {
		return identityport.TokenExchange{}, fmt.Errorf("oauth.Provider[%s].Refresh: %w", p.name, err)
	}
	if profile.Subject == "" {
		profile.Subject = identity.Subject
	}
	if profile.Provider == "" {
		profile.Provider = identity.Provider
	}

	return identityport.TokenExchange{
		Token:   token,
		Profile: profile,
		Raw: map[string]any{
			"token":   token.Raw,
			"profile": profileRaw,
		},
	}, nil
}

func (p *provider) fetchProfile(ctx context.Context, accessToken string) (identitydomain.Profile, map[string]any, error) {
	if strings.TrimSpace(accessToken) == "" {
		return identitydomain.Profile{}, nil, fmt.Errorf("access token missing")
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, p.descriptor.UserInfoURL, nil)
	if err != nil {
		return identitydomain.Profile{}, nil, fmt.Errorf("userinfo request: %w", err)
	}
	req.Header.Set("Authorization", "Bearer "+accessToken)
	req.Header.Set("Accept", "application/json")
	req.Header.Set("User-Agent", p.userAgent)
	for key, value := range p.descriptor.UserInfoHeaders {
		if strings.EqualFold(key, "authorization") || strings.EqualFold(key, "accept") || strings.EqualFold(key, "user-agent") {
			continue
		}
		req.Header.Set(key, value)
	}

	resp, err := p.httpClient.Do(req)
	if err != nil {
		return identitydomain.Profile{}, nil, fmt.Errorf("userinfo http: %w", err)
	}
	defer func() {
		_ = resp.Body.Close()
	}()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return identitydomain.Profile{}, nil, fmt.Errorf("userinfo status %d", resp.StatusCode)
	}

	decoder := json.NewDecoder(resp.Body)
	decoder.UseNumber()
	var raw map[string]any
	if err := decoder.Decode(&raw); err != nil {
		return identitydomain.Profile{}, nil, fmt.Errorf("userinfo decode: %w", err)
	}

	profile, err := p.descriptor.ProfileExtractor(raw)
	if err != nil {
		return identitydomain.Profile{}, nil, err
	}
	if profile.Provider == "" {
		profile.Provider = p.name
	}
	if profile.Raw == nil {
		profile.Raw = raw
	}

	return profile, raw, nil
}

func fallbackScopes(primary []string, secondary []string) []string {
	if len(primary) > 0 {
		return append([]string(nil), primary...)
	}
	if len(secondary) > 0 {
		return append([]string(nil), secondary...)
	}
	return []string{}
}

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if trimmed := strings.TrimSpace(value); trimmed != "" {
			return trimmed
		}
	}
	return ""
}

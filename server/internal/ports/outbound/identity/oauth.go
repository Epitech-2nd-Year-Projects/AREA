package identity

import (
	"context"

	identitydomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/identity"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/oauth2"
)

// AuthorizationRequest carries options for initiating an OAuth flow
type AuthorizationRequest struct {
	RedirectURI string
	Scopes      []string
	State       string
	UsePKCE     bool
	Prompt      string
}

// AuthorizationResponse returns the data required to redirect a user to an OAuth provider
type AuthorizationResponse struct {
	AuthorizationURL    string
	State               string
	CodeVerifier        string
	CodeChallenge       string
	CodeChallengeMethod oauth2.CodeChallengeMethod
}

// ExchangeRequest holds contextual data to swap an authorization code for access tokens
type ExchangeRequest struct {
	RedirectURI  string
	CodeVerifier string
}

// TokenExchange represents the result of exchanging or refreshing OAuth credentials
type TokenExchange struct {
	Token   oauth2.Token
	Profile identitydomain.Profile
	Raw     map[string]any
}

// Provider exposes the operations required to integrate an OAuth2 identity provider
// Implementations must be safe for concurrent use
// They should generate cryptographic state and PKCE values when absent in the request
type Provider interface {
	Name() string
	AuthorizationURL(ctx context.Context, req AuthorizationRequest) (AuthorizationResponse, error)
	Exchange(ctx context.Context, code string, req ExchangeRequest) (TokenExchange, error)
	Refresh(ctx context.Context, identity identitydomain.Identity) (TokenExchange, error)
}

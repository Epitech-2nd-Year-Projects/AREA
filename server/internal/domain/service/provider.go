package service

import (
	"time"

	"github.com/google/uuid"
)

// OAuthType enumerates the authentication mechanism required by a service provider.
type OAuthType string

const (
	// OAuthTypeNone indicates the provider does not require credentials.
	OAuthTypeNone OAuthType = "none"
	// OAuthTypeOAuth2 indicates the provider uses an OAuth2 flow.
	OAuthTypeOAuth2 OAuthType = "oauth2"
	// OAuthTypeAPIKey indicates the provider expects an API key.
	OAuthTypeAPIKey OAuthType = "apikey"
)

// Provider represents an automation service integration surfaced in the catalog.
type Provider struct {
	ID          uuid.UUID
	Name        string
	DisplayName string
	Category    string
	OAuthType   OAuthType
	Enabled     bool
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

// RequiresOAuth reports whether the provider mandates an OAuth2 authorisation flow.
func (p Provider) RequiresOAuth() bool {
	return p.OAuthType == OAuthTypeOAuth2
}

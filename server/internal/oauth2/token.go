package oauth2

import "time"

// Token represents OAuth2 credentials issued by a provider
type Token struct {
	AccessToken  string
	RefreshToken string
	TokenType    string
	ExpiresAt    time.Time
	Scope        []string
	IDToken      string
	Raw          map[string]any
}

// Expired reports whether the token lifetime has elapsed accounting for skew
func (t Token) Expired(now time.Time, skew time.Duration) bool {
	if t.ExpiresAt.IsZero() {
		return false
	}
	if skew < 0 {
		skew = 0
	}

	threshold := now.Add(skew)
	return !t.ExpiresAt.After(threshold)
}

// HasRefreshToken signals whether the token includes a refresh token
func (t Token) HasRefreshToken() bool {
	return t.RefreshToken != ""
}

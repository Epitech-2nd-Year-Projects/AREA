package oauth

import (
	"encoding/json"
	"fmt"
	"strconv"
	"strings"

	identitydomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/identity"
)

// ProfileExtractor converts raw user info responses into identity profiles
// Implementations should return an error when the payload misses required fields
type ProfileExtractor func(raw map[string]any) (identitydomain.Profile, error)

// ProviderDescriptor captures immutable OAuth provider characteristics
// These values typically originate from the provider documentation
type ProviderDescriptor struct {
	DisplayName         string
	AuthorizationURL    string
	TokenURL            string
	UserInfoURL         string
	DefaultScopes       []string
	DefaultPrompt       string
	Audience            string
	AuthorizationParams map[string]string
	UserInfoHeaders     map[string]string
	ProfileExtractor    ProfileExtractor
}

// Registry enumerates the descriptors known to the application
// Keys are normalized provider identifiers (lowercase)
type Registry map[string]ProviderDescriptor

// BuiltIn returns the descriptors for the core providers supported by AREA
func BuiltIn() Registry {
	return Registry{
		"google": {
			DisplayName:      "Google",
			AuthorizationURL: "https://accounts.google.com/o/oauth2/v2/auth",
			TokenURL:         "https://oauth2.googleapis.com/token",
			UserInfoURL:      "https://openidconnect.googleapis.com/v1/userinfo",
			DefaultScopes:    []string{"openid", "email", "profile"},
			AuthorizationParams: map[string]string{
				"access_type":            "offline",
				"include_granted_scopes": "true",
			},
			ProfileExtractor: googleProfileExtractor,
		},
		"github": {
			DisplayName:      "GitHub",
			AuthorizationURL: "https://github.com/login/oauth/authorize",
			TokenURL:         "https://github.com/login/oauth/access_token",
			UserInfoURL:      "https://api.github.com/user",
			DefaultScopes:    []string{"read:user", "user:email"},
			UserInfoHeaders: map[string]string{
				"Accept":     "application/vnd.github+json",
				"User-Agent": "AREA-Server",
			},
			ProfileExtractor: githubProfileExtractor,
		},
	}
}

func googleProfileExtractor(raw map[string]any) (identitydomain.Profile, error) {
	subject := stringFrom(raw["sub"])
	if subject == "" {
		return identitydomain.Profile{}, fmt.Errorf("google: sub missing")
	}

	profile := identitydomain.Profile{
		Provider:   "google",
		Subject:    subject,
		Email:      stringFrom(raw["email"]),
		Name:       stringFrom(raw["name"]),
		PictureURL: stringFrom(raw["picture"]),
		Raw:        raw,
	}
	return profile, nil
}

func githubProfileExtractor(raw map[string]any) (identitydomain.Profile, error) {
	var subject string
	switch id := raw["id"].(type) {
	case string:
		subject = strings.TrimSpace(id)
	case json.Number:
		subject = id.String()
	case float64:
		subject = strconv.FormatInt(int64(id), 10)
	case int:
		subject = strconv.Itoa(id)
	case int64:
		subject = strconv.FormatInt(id, 10)
	case nil:
		subject = ""
	default:
		subject = fmt.Sprintf("%v", id)
	}
	if subject == "" {
		return identitydomain.Profile{}, fmt.Errorf("github: id missing")
	}

	name := strings.TrimSpace(stringFrom(raw["name"]))
	if name == "" {
		name = stringFrom(raw["login"])
	}

	profile := identitydomain.Profile{
		Provider:   "github",
		Subject:    subject,
		Email:      stringFrom(raw["email"]),
		Name:       name,
		PictureURL: stringFrom(raw["avatar_url"]),
		Raw:        raw,
	}
	return profile, nil
}

func stringFrom(value any) string {
	switch v := value.(type) {
	case string:
		return strings.TrimSpace(v)
	case fmt.Stringer:
		return strings.TrimSpace(v.String())
	case float64:
		return strconv.FormatFloat(v, 'f', -1, 64)
	case int:
		return strconv.Itoa(v)
	case int64:
		return strconv.FormatInt(v, 10)
	default:
		return ""
	}
}

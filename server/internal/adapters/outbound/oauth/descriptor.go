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
	UserInfoMethod      string
	UserInfoBody        string
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
		"gitlab": {
			DisplayName:      "GitLab",
			AuthorizationURL: "https://gitlab.com/oauth/authorize",
			TokenURL:         "https://gitlab.com/oauth/token",
			UserInfoURL:      "https://gitlab.com/api/v4/user",
			DefaultScopes:    []string{"read_user", "api"},
			UserInfoHeaders: map[string]string{
				"User-Agent": "AREA-Server",
			},
			ProfileExtractor: gitlabProfileExtractor,
		},
		"dropbox": {
			DisplayName:      "Dropbox",
			AuthorizationURL: "https://www.dropbox.com/oauth2/authorize",
			TokenURL:         "https://api.dropboxapi.com/oauth2/token",
			UserInfoURL:      "https://api.dropboxapi.com/2/users/get_current_account",
			UserInfoMethod:   "POST",
			UserInfoBody:     "null",
			DefaultScopes:    []string{"account_info.read", "files.metadata.read", "files.metadata.write"},
			AuthorizationParams: map[string]string{
				"token_access_type": "offline",
			},
			UserInfoHeaders: map[string]string{
				"Content-Type": "application/json",
				"User-Agent":   "AREA-Server",
			},
			ProfileExtractor: dropboxProfileExtractor,
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

func gitlabProfileExtractor(raw map[string]any) (identitydomain.Profile, error) {
	subject := stringFrom(raw["id"])
	if subject == "" {
		return identitydomain.Profile{}, fmt.Errorf("gitlab: id missing")
	}

	username := stringFrom(raw["username"])
	name := strings.TrimSpace(stringFrom(raw["name"]))
	if name == "" {
		name = username
	}

	profile := identitydomain.Profile{
		Provider:   "gitlab",
		Subject:    subject,
		Email:      stringFrom(raw["email"]),
		Name:       name,
		PictureURL: stringFrom(raw["avatar_url"]),
		Raw:        raw,
	}
	return profile, nil
}

func dropboxProfileExtractor(raw map[string]any) (identitydomain.Profile, error) {
	subject := stringFrom(raw["account_id"])
	if subject == "" {
		return identitydomain.Profile{}, fmt.Errorf("dropbox: account_id missing")
	}

	name := stringFrom(raw["name"])
	if name == "" {
		if nested, ok := raw["name"].(map[string]any); ok {
			name = stringFrom(nested["display_name"])
			if name == "" {
				name = stringFrom(nested["abbreviated_name"])
			}
		}
	}
	email := stringFrom(raw["email"])
	picture := stringFrom(raw["profile_photo_url"])

	profile := identitydomain.Profile{
		Provider:   "dropbox",
		Subject:    subject,
		Email:      email,
		Name:       name,
		PictureURL: picture,
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

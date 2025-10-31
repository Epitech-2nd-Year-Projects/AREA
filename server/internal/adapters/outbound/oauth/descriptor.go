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
	TokenAuthMethod     string
	TokenFormat         string
	TokenHeaders        map[string]string
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
		"spotify": {
			DisplayName:      "Spotify",
			AuthorizationURL: "https://accounts.spotify.com/authorize",
			TokenURL:         "https://accounts.spotify.com/api/token",
			UserInfoURL:      "https://api.spotify.com/v1/me",
			DefaultScopes: []string{
				"user-read-email",
				"user-read-private",
				"user-library-read",
				"playlist-modify-public",
				"playlist-modify-private",
			},
			UserInfoHeaders: map[string]string{
				"Accept":     "application/json",
				"User-Agent": "AREA-Server",
			},
			ProfileExtractor: spotifyProfileExtractor,
		},
		"notion": {
			DisplayName:      "Notion",
			AuthorizationURL: "https://api.notion.com/v1/oauth/authorize",
			TokenURL:         "https://api.notion.com/v1/oauth/token",
			UserInfoURL:      "https://api.notion.com/v1/users/me",
			DefaultScopes: []string{
				"read",
				"write",
			},
			AuthorizationParams: map[string]string{
				"owner": "user",
			},
			UserInfoHeaders: map[string]string{
				"Accept":          "application/json",
				"Notion-Version":  "2022-06-28",
				"User-Agent":      "AREA-Server",
				"Content-Type":    "application/json",
				"Accept-Language": "en-US",
			},
			TokenAuthMethod: "basic",
			TokenFormat:     "json",
			TokenHeaders: map[string]string{
				"Notion-Version": "2022-06-28",
			},
			ProfileExtractor: notionProfileExtractor,
		},
		"slack": {
			DisplayName:      "Slack",
			AuthorizationURL: "https://slack.com/oauth/v2/authorize",
			TokenURL:         "https://slack.com/api/oauth.v2.access",
			UserInfoURL:      "https://slack.com/api/auth.test",
			DefaultScopes:    []string{"chat:write", "channels:history", "groups:history", "im:history", "mpim:history", "users:read", "offline_access"},
			UserInfoHeaders: map[string]string{
				"User-Agent": "AREA-Server",
			},
			ProfileExtractor: slackProfileExtractor,
		},
		"linear": {
			DisplayName:      "Linear",
			AuthorizationURL: "https://linear.app/oauth/authorize",
			TokenURL:         "https://api.linear.app/oauth/token",
			UserInfoURL:      "https://api.linear.app/graphql",
			UserInfoMethod:   "POST",
			UserInfoBody:     `{"query":"query Viewer { viewer { id name email avatarUrl } }"}`,
			DefaultScopes:    []string{"read", "write", "issues:read", "issues:create", "offline_access"},
			UserInfoHeaders: map[string]string{
				"Content-Type": "application/json",
				"User-Agent":   "AREA-Server",
			},
			ProfileExtractor: linearProfileExtractor,
		},
		"microsoft": {
			DisplayName:      "Microsoft",
			AuthorizationURL: "https://login.microsoftonline.com/common/oauth2/v2.0/authorize",
			TokenURL:         "https://login.microsoftonline.com/common/oauth2/v2.0/token",
			UserInfoURL:      "https://graph.microsoft.com/v1.0/me",
			DefaultScopes: []string{
				"offline_access",
				"openid",
				"profile",
				"email",
				"Mail.Read",
				"Mail.Send",
			},
			UserInfoHeaders: map[string]string{
				"Accept":     "application/json",
				"User-Agent": "AREA-Server",
			},
			ProfileExtractor: microsoftProfileExtractor,
		},
		"reddit": {
			DisplayName:      "Reddit",
			AuthorizationURL: "https://www.reddit.com/api/v1/authorize",
			TokenURL:         "https://www.reddit.com/api/v1/access_token",
			UserInfoURL:      "https://oauth.reddit.com/api/v1/me",
			DefaultScopes: []string{
				"identity",
				"read",
				"submit",
			},
			AuthorizationParams: map[string]string{
				"duration": "permanent",
			},
			UserInfoHeaders: map[string]string{
				"User-Agent": "AREA-Server",
			},
			TokenAuthMethod: "basic",
			TokenHeaders: map[string]string{
				"User-Agent": "AREA-Server",
			},
			ProfileExtractor: redditProfileExtractor,
		},
		"zoom": {
			DisplayName:      "Zoom",
			AuthorizationURL: "https://zoom.us/oauth/authorize",
			TokenURL:         "https://zoom.us/oauth/token",
			UserInfoURL:      "https://api.zoom.us/v2/users/me",
			UserInfoHeaders: map[string]string{
				"User-Agent": "AREA-Server",
			},
			ProfileExtractor: zoomProfileExtractor,
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

func spotifyProfileExtractor(raw map[string]any) (identitydomain.Profile, error) {
	if raw == nil {
		return identitydomain.Profile{}, fmt.Errorf("spotify: user info payload missing")
	}

	subject := strings.TrimSpace(stringFrom(raw["id"]))
	if subject == "" {
		subject = strings.TrimSpace(stringFrom(raw["uri"]))
	}
	if subject == "" {
		return identitydomain.Profile{}, fmt.Errorf("spotify: id missing")
	}

	displayName := strings.TrimSpace(stringFrom(raw["display_name"]))
	if displayName == "" {
		displayName = subject
	}

	email := strings.TrimSpace(stringFrom(raw["email"]))

	picture := ""
	if images, ok := raw["images"].([]any); ok {
		for _, item := range images {
			if image, ok := item.(map[string]any); ok {
				if url := strings.TrimSpace(stringFrom(image["url"])); url != "" {
					picture = url
					break
				}
			}
		}
	}

	profile := identitydomain.Profile{
		Provider:   "spotify",
		Subject:    subject,
		Email:      email,
		Name:       displayName,
		PictureURL: picture,
		Raw:        raw,
	}
	return profile, nil
}

func notionProfileExtractor(raw map[string]any) (identitydomain.Profile, error) {
	if raw == nil {
		return identitydomain.Profile{}, fmt.Errorf("notion: user info payload missing")
	}

	subject := strings.TrimSpace(stringFrom(raw["id"]))
	if subject == "" {
		return identitydomain.Profile{}, fmt.Errorf("notion: id missing")
	}

	name := strings.TrimSpace(stringFrom(raw["name"]))

	email := ""
	if person, ok := raw["person"].(map[string]any); ok {
		email = strings.TrimSpace(stringFrom(person["email"]))
	}

	picture := strings.TrimSpace(stringFrom(raw["avatar_url"]))

	profile := identitydomain.Profile{
		Provider:   "notion",
		Subject:    subject,
		Email:      email,
		Name:       name,
		PictureURL: picture,
		Raw:        raw,
	}
	return profile, nil
}

func slackProfileExtractor(raw map[string]any) (identitydomain.Profile, error) {
	if raw == nil {
		return identitydomain.Profile{}, fmt.Errorf("slack: user info payload missing")
	}

	if okVal, exists := raw["ok"]; exists {
		switch v := okVal.(type) {
		case bool:
			if !v {
				errMsg := stringFrom(raw["error"])
				if errMsg == "" {
					errMsg = "request failed"
				}
				return identitydomain.Profile{}, fmt.Errorf("slack: %s", errMsg)
			}
		case string:
			if strings.EqualFold(strings.TrimSpace(v), "false") {
				errMsg := stringFrom(raw["error"])
				if errMsg == "" {
					errMsg = "request failed"
				}
				return identitydomain.Profile{}, fmt.Errorf("slack: %s", errMsg)
			}
		}
	}

	subject := stringFrom(raw["user_id"])
	if subject == "" {
		subject = stringFrom(raw["bot_id"])
	}
	if subject == "" {
		return identitydomain.Profile{}, fmt.Errorf("slack: user_id missing")
	}

	name := stringFrom(raw["user"])
	if name == "" {
		name = stringFrom(raw["team"])
	}

	profile := identitydomain.Profile{
		Provider:   "slack",
		Subject:    subject,
		Email:      stringFrom(raw["user_email"]),
		Name:       name,
		PictureURL: stringFrom(raw["user_image_72"]),
		Raw:        raw,
	}
	return profile, nil
}

func zoomProfileExtractor(raw map[string]any) (identitydomain.Profile, error) {
	if raw == nil {
		return identitydomain.Profile{}, fmt.Errorf("zoom: user info payload missing")
	}

	subject := stringFrom(raw["id"])
	if subject == "" {
		subject = stringFrom(raw["account_id"])
	}
	if subject == "" {
		return identitydomain.Profile{}, fmt.Errorf("zoom: id missing")
	}

	displayName := strings.TrimSpace(stringFrom(raw["display_name"]))
	if displayName == "" {
		firstName := strings.TrimSpace(stringFrom(raw["first_name"]))
		lastName := strings.TrimSpace(stringFrom(raw["last_name"]))
		displayName = strings.TrimSpace(strings.Join(filterNonEmpty([]string{firstName, lastName}), " "))
	}

	picture := stringFrom(raw["pic_url"])
	if picture == "" {
		picture = stringFrom(raw["avatar"])
	}

	profile := identitydomain.Profile{
		Provider:   "zoom",
		Subject:    subject,
		Email:      stringFrom(raw["email"]),
		Name:       displayName,
		PictureURL: picture,
		Raw:        raw,
	}
	return profile, nil
}

func linearProfileExtractor(raw map[string]any) (identitydomain.Profile, error) {
	data, ok := raw["data"].(map[string]any)
	if !ok {
		return identitydomain.Profile{}, fmt.Errorf("linear: data missing")
	}
	viewer, ok := data["viewer"].(map[string]any)
	if !ok {
		return identitydomain.Profile{}, fmt.Errorf("linear: viewer missing")
	}

	subject := stringFrom(viewer["id"])
	if subject == "" {
		return identitydomain.Profile{}, fmt.Errorf("linear: id missing")
	}

	profile := identitydomain.Profile{
		Provider:   "linear",
		Subject:    subject,
		Email:      stringFrom(viewer["email"]),
		Name:       stringFrom(viewer["name"]),
		PictureURL: stringFrom(viewer["avatarUrl"]),
		Raw:        raw,
	}
	return profile, nil
}

func microsoftProfileExtractor(raw map[string]any) (identitydomain.Profile, error) {
	subject := stringFrom(raw["id"])
	if subject == "" {
		return identitydomain.Profile{}, fmt.Errorf("microsoft: id missing")
	}

	email := strings.TrimSpace(stringFrom(raw["mail"]))
	if email == "" {
		email = strings.TrimSpace(stringFrom(raw["userPrincipalName"]))
	}

	profile := identitydomain.Profile{
		Provider:   "microsoft",
		Subject:    subject,
		Email:      email,
		Name:       stringFrom(raw["displayName"]),
		PictureURL: "",
		Raw:        raw,
	}
	return profile, nil
}

func redditProfileExtractor(raw map[string]any) (identitydomain.Profile, error) {
	subject := stringFrom(raw["id"])
	if subject == "" {
		return identitydomain.Profile{}, fmt.Errorf("reddit: id missing")
	}

	username := stringFrom(raw["name"])
	email := strings.TrimSpace(stringFrom(raw["email"]))

	profile := identitydomain.Profile{
		Provider:   "reddit",
		Subject:    subject,
		Email:      email,
		Name:       username,
		PictureURL: stringFrom(raw["icon_img"]),
		Raw:        raw,
	}
	return profile, nil
}

func filterNonEmpty(values []string) []string {
	result := make([]string, 0, len(values))
	for _, value := range values {
		if trimmed := strings.TrimSpace(value); trimmed != "" {
			result = append(result, trimmed)
		}
	}
	return result
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

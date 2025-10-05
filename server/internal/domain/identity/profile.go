package identity

// Profile captures the remote identity information returned by an OAuth provider
type Profile struct {
	Provider   string
	Subject    string
	Email      string
	Name       string
	PictureURL string
	Raw        map[string]any
}

// Empty reports whether the profile is missing its identifying attributes
func (p Profile) Empty() bool {
	return p.Provider == "" || p.Subject == ""
}

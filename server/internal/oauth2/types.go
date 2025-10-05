package oauth2

// CodeChallengeMethod enumerates the supported PKCE challenge strategies
type CodeChallengeMethod string

const (
	// CodeChallengeMethodPlain represents the RFC7636 plain method
	CodeChallengeMethodPlain CodeChallengeMethod = "plain"
	// CodeChallengeMethodS256 represents the RFC7636 S256 method
	CodeChallengeMethodS256 CodeChallengeMethod = "S256"
)

// Valid reports whether the code challenge method is supported
func (m CodeChallengeMethod) Valid() bool {
	switch m {
	case CodeChallengeMethodPlain, CodeChallengeMethodS256:
		return true
	default:
		return false
	}
}

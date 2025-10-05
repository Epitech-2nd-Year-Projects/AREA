package oauth2

import (
	"crypto/sha256"
	"encoding/base64"
	"fmt"
)

// DeriveCodeChallenge computes a PKCE code challenge from the provided verifier
func DeriveCodeChallenge(verifier string, method CodeChallengeMethod) (string, error) {
	if !method.Valid() {
		return "", fmt.Errorf("oauth2.DeriveCodeChallenge: unsupported method %q", method)
	}
	if verifier == "" {
		return "", fmt.Errorf("oauth2.DeriveCodeChallenge: verifier is empty")
	}

	switch method {
	case CodeChallengeMethodPlain:
		return verifier, nil
	case CodeChallengeMethodS256:
		sum := sha256.Sum256([]byte(verifier))
		return base64.RawURLEncoding.EncodeToString(sum[:]), nil
	default:
		return "", fmt.Errorf("oauth2.DeriveCodeChallenge: unknown method %q", method)
	}
}

// GeneratePKCE returns a verifier, challenge, and method using the recommended settings
func GeneratePKCE() (verifier string, challenge string, method CodeChallengeMethod, err error) {
	verifier, err = GenerateCodeVerifier(64)
	if err != nil {
		return "", "", "", fmt.Errorf("oauth2.GeneratePKCE: %w", err)
	}
	challenge, err = DeriveCodeChallenge(verifier, CodeChallengeMethodS256)
	if err != nil {
		return "", "", "", fmt.Errorf("oauth2.GeneratePKCE: %w", err)
	}
	return verifier, challenge, CodeChallengeMethodS256, nil
}

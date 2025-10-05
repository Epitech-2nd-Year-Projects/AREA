package oauth2

import (
	"crypto/rand"
	"encoding/base64"
	"fmt"
)

const (
	pkceMinLength = 43
	pkceMaxLength = 128
)

var pkceAlphabet = []byte("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")

// GenerateState returns a cryptographically secure state parameter suitable for OAuth flows
func GenerateState(size int) (string, error) {
	if size <= 0 {
		size = 32
	}
	buf := make([]byte, size)
	if _, err := rand.Read(buf); err != nil {
		return "", fmt.Errorf("oauth2.GenerateState: rand.Read: %w", err)
	}
	return base64.RawURLEncoding.EncodeToString(buf), nil
}

// GenerateCodeVerifier produces a PKCE code verifier of the requested length
func GenerateCodeVerifier(length int) (string, error) {
	if length == 0 {
		length = 64
	}
	if length < pkceMinLength || length > pkceMaxLength {
		return "", fmt.Errorf("oauth2.GenerateCodeVerifier: length %d outside [%d,%d]", length, pkceMinLength, pkceMaxLength)
	}

	buf := make([]byte, length)
	rangeMax := byte(len(pkceAlphabet))
	if _, err := rand.Read(buf); err != nil {
		return "", fmt.Errorf("oauth2.GenerateCodeVerifier: rand.Read: %w", err)
	}
	for i := range buf {
		buf[i] = pkceAlphabet[int(buf[i])%int(rangeMax)]
	}
	return string(buf), nil
}

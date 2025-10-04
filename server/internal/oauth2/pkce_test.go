package oauth2

import (
	"encoding/base64"
	"testing"
)

func TestGenerateCodeVerifierLength(t *testing.T) {
	verifier, err := GenerateCodeVerifier(64)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(verifier) != 64 {
		t.Fatalf("expected length 64 got %d", len(verifier))
	}

	if _, err := GenerateCodeVerifier(10); err == nil {
		t.Fatalf("expected error for short length")
	}
	if _, err := GenerateCodeVerifier(200); err == nil {
		t.Fatalf("expected error for long length")
	}
}

func TestDeriveCodeChallenge(t *testing.T) {
	verifier := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"
	challenge, err := DeriveCodeChallenge(verifier, CodeChallengeMethodS256)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	decoded, err := base64.RawURLEncoding.DecodeString(challenge)
	if err != nil {
		t.Fatalf("challenge not base64url: %v", err)
	}
	if len(decoded) != 32 {
		t.Fatalf("expected 32 byte digest got %d", len(decoded))
	}

	plain, err := DeriveCodeChallenge(verifier, CodeChallengeMethodPlain)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if plain != verifier {
		t.Fatalf("expected plain challenge equal to verifier")
	}

	if _, err := DeriveCodeChallenge("", CodeChallengeMethodS256); err == nil {
		t.Fatalf("expected error for empty verifier")
	}
	if _, err := DeriveCodeChallenge(verifier, "invalid"); err == nil {
		t.Fatalf("expected error for invalid method")
	}
}

func TestGeneratePKCE(t *testing.T) {
	verifier, challenge, method, err := GeneratePKCE()
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(verifier) == 0 || len(challenge) == 0 {
		t.Fatalf("expected non empty values")
	}
	if method != CodeChallengeMethodS256 {
		t.Fatalf("expected method S256 got %s", method)
	}
}

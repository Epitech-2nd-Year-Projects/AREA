package oauth2

import (
	"encoding/base64"
	"testing"
)

func TestGenerateState(t *testing.T) {
	state, err := GenerateState(16)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(state) == 0 {
		t.Fatalf("expected non empty state")
	}
	if _, err := base64.RawURLEncoding.DecodeString(state); err != nil {
		t.Fatalf("state not base64: %v", err)
	}
}

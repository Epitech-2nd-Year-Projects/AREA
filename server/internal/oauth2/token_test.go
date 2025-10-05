package oauth2

import (
	"testing"
	"time"
)

func TestTokenExpired(t *testing.T) {
	now := time.Unix(1700000000, 0).UTC()
	futureToken := Token{ExpiresAt: now.Add(2 * time.Minute)}
	if futureToken.Expired(now, time.Minute) {
		t.Fatalf("token should not be expired with skew")
	}

	if !futureToken.Expired(now.Add(3*time.Minute), 0) {
		t.Fatalf("token should be expired")
	}

	nonExpiring := Token{}
	if nonExpiring.Expired(now, time.Minute) {
		t.Fatalf("zero expiry token should not expire")
	}
}

func TestTokenHasRefreshToken(t *testing.T) {
	empty := Token{}
	if empty.HasRefreshToken() {
		t.Fatalf("expected empty token to report false")
	}

	withRefresh := Token{RefreshToken: "abc"}
	if !withRefresh.HasRefreshToken() {
		t.Fatalf("expected true when refresh token present")
	}
}

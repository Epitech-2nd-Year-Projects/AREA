package identity

import (
	"testing"
	"time"

	"github.com/google/uuid"
)

func TestIdentityTokenExpired(t *testing.T) {
	now := time.Unix(1700000000, 0).UTC()
	expiredAt := now.Add(-1 * time.Minute)
	future := now.Add(5 * time.Minute)

	tests := []struct {
		name     string
		identity Identity
		expected bool
	}{
		{
			name:     "no expiry",
			identity: Identity{ID: uuid.New()},
			expected: false,
		},
		{
			name: "expired",
			identity: Identity{
				ExpiresAt: &expiredAt,
			},
			expected: true,
		},
		{
			name: "future",
			identity: Identity{
				ExpiresAt: &future,
			},
			expected: false,
		},
	}

	for _, tt := range tests {
		caseData := tt
		t.Run(caseData.name, func(t *testing.T) {
			result := caseData.identity.TokenExpired(now)
			if result != caseData.expected {
				t.Fatalf("expected %v got %v", caseData.expected, result)
			}
		})
	}
}

func TestIdentityWithTokens(t *testing.T) {
	var (
		expires = time.Unix(1700000300, 0).UTC()
		scopes  = []string{"profile", "email"}
	)

	identity := Identity{}
	updated := identity.WithTokens("access", "refresh", &expires, scopes)

	if updated.AccessToken != "access" {
		t.Fatalf("expected access got %s", updated.AccessToken)
	}
	if updated.RefreshToken != "refresh" {
		t.Fatalf("expected refresh got %s", updated.RefreshToken)
	}
	if updated.ExpiresAt != &expires {
		t.Fatalf("expected expires pointer equality")
	}
	if len(updated.Scopes) != len(scopes) {
		t.Fatalf("expected %d scopes got %d", len(scopes), len(updated.Scopes))
	}
	if len(identity.AccessToken) != 0 {
		t.Fatalf("expected original unchanged")
	}
}

package identity

import "testing"

func TestProfileEmpty(t *testing.T) {
	tests := []struct {
		name     string
		profile  Profile
		expected bool
	}{
		{
			name:     "missing provider",
			profile:  Profile{Subject: "123"},
			expected: true,
		},
		{
			name:     "missing subject",
			profile:  Profile{Provider: "google"},
			expected: true,
		},
		{
			name:     "complete",
			profile:  Profile{Provider: "google", Subject: "123"},
			expected: false,
		},
	}

	for _, tt := range tests {
		caseData := tt
		t.Run(caseData.name, func(t *testing.T) {
			result := caseData.profile.Empty()
			if result != caseData.expected {
				t.Fatalf("expected %v got %v", caseData.expected, result)
			}
		})
	}
}

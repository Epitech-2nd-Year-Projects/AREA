package area

import (
	"context"
	"testing"

	areadomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/area"
	componentdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/component"
	"github.com/google/uuid"
)

type recordingProvisioner struct {
	calls int
	area  areadomain.Area
}

func (r *recordingProvisioner) Provision(ctx context.Context, area areadomain.Area) error {
	r.calls++
	r.area = area
	return nil
}

func TestRegistryProvisioner_MatchesExactComponent(t *testing.T) {
	registry := NewRegistryProvisioner()
	exact := &recordingProvisioner{}
	registry.Register("scheduler", "timer_interval", exact)

	area := areadomain.Area{
		Action: &areadomain.Link{
			Config: componentdomain.Config{
				ID: uuid.New(),
				Component: &componentdomain.Component{
					Name: "timer_interval",
					Provider: componentdomain.Provider{
						Name: "Scheduler",
					},
				},
			},
		},
	}

	if err := registry.Provision(context.Background(), area); err != nil {
		t.Fatalf("Provision returned error: %v", err)
	}
	if exact.calls != 1 {
		t.Fatalf("expected exact provisioner to be called once, got %d", exact.calls)
	}
}

func TestRegistryProvisioner_FallbackWhenNoMatch(t *testing.T) {
	fallback := &recordingProvisioner{}
	registry := NewRegistryProvisioner(WithProvisionerFallback(fallback))
	area := areadomain.Area{
		Action: &areadomain.Link{
			Config: componentdomain.Config{
				ID: uuid.New(),
				Component: &componentdomain.Component{
					Name: "unknown_component",
					Provider: componentdomain.Provider{
						Name: "unknown_provider",
					},
				},
			},
		},
	}

	if err := registry.Provision(context.Background(), area); err != nil {
		t.Fatalf("Provision returned error: %v", err)
	}
	if fallback.calls != 1 {
		t.Fatalf("expected fallback provisioner to be called, got %d", fallback.calls)
	}
}

func TestRegistryProvisioner_ProviderLevelRegistration(t *testing.T) {
	provider := &recordingProvisioner{}
	registry := NewRegistryProvisioner()
	registry.Register("github", "", provider)

	area := areadomain.Area{
		Action: &areadomain.Link{
			Config: componentdomain.Config{
				ID: uuid.New(),
				Component: &componentdomain.Component{
					Name: "issues_new_comment",
					Provider: componentdomain.Provider{
						Name: "GitHub",
					},
				},
			},
		},
	}

	if err := registry.Provision(context.Background(), area); err != nil {
		t.Fatalf("Provision returned error: %v", err)
	}
	if provider.calls != 1 {
		t.Fatalf("expected provider-level provisioner to be called, got %d", provider.calls)
	}
}

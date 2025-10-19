package area

import (
	"context"
	"strings"

	areadomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/area"
)

// ActionProvisionerFunc adapts ordinary functions to the ActionProvisioner interface
type ActionProvisionerFunc func(ctx context.Context, area areadomain.Area) error

// Provision executes the wrapped function if non-nil
func (f ActionProvisionerFunc) Provision(ctx context.Context, area areadomain.Area) error {
	if f == nil {
		return nil
	}
	return f(ctx, area)
}

// NoopProvisioner implements ActionProvisioner but performs no work
type NoopProvisioner struct{}

// Provision satisfies the ActionProvisioner contract without side effects
func (NoopProvisioner) Provision(ctx context.Context, area areadomain.Area) error {
	return nil
}

type provisionerKey struct {
	provider  string
	component string
}

// RegistryProvisioner routes provisioning to registered handlers based on the action metadata
type RegistryProvisioner struct {
	registry map[provisionerKey]ActionProvisioner
	fallback ActionProvisioner
}

// RegistryOption configures a RegistryProvisioner instance
type RegistryOption func(*RegistryProvisioner)

// WithProvisionerFallback sets the fallback ActionProvisioner used when no specific handler matches
func WithProvisionerFallback(p ActionProvisioner) RegistryOption {
	return func(r *RegistryProvisioner) {
		r.fallback = p
	}
}

// NewRegistryProvisioner builds a registry-backed ActionProvisioner
func NewRegistryProvisioner(opts ...RegistryOption) *RegistryProvisioner {
	reg := &RegistryProvisioner{
		registry: make(map[provisionerKey]ActionProvisioner),
	}
	for _, opt := range opts {
		if opt != nil {
			opt(reg)
		}
	}
	return reg
}

// Register associates the given ActionProvisioner with the supplied provider/component identifiers
func (r *RegistryProvisioner) Register(provider string, component string, provisioner ActionProvisioner) {
	if r == nil || provisioner == nil {
		return
	}
	key := provisionerKey{
		provider:  normalizeProvisionKey(provider),
		component: normalizeProvisionKey(component),
	}
	r.registry[key] = provisioner
}

// Provision dispatches to the matching registered provisioner or the configured fallback
func (r *RegistryProvisioner) Provision(ctx context.Context, area areadomain.Area) error {
	if r == nil {
		return nil
	}
	provisioner := r.match(area)
	if provisioner == nil {
		return nil
	}
	return provisioner.Provision(ctx, area)
}

func (r *RegistryProvisioner) match(area areadomain.Area) ActionProvisioner {
	if area.Action == nil || area.Action.Config.Component == nil {
		if r.fallback != nil {
			return r.fallback
		}
		return nil
	}

	componentName := normalizeProvisionKey(area.Action.Config.Component.Name)
	providerName := normalizeProvisionKey(area.Action.Config.Component.Provider.Name)

	// Priority: exact provider+component > provider-only > component-only > fallback
	if provisioner, ok := r.registry[provisionerKey{provider: providerName, component: componentName}]; ok {
		return provisioner
	}
	if provisioner, ok := r.registry[provisionerKey{provider: providerName}]; ok {
		return provisioner
	}
	if provisioner, ok := r.registry[provisionerKey{component: componentName}]; ok {
		return provisioner
	}
	if r.fallback != nil {
		return r.fallback
	}
	return nil
}

func normalizeProvisionKey(value string) string {
	return strings.ToLower(strings.TrimSpace(value))
}

// Ensure RegistryProvisioner complies with ActionProvisioner
var _ ActionProvisioner = (*RegistryProvisioner)(nil)

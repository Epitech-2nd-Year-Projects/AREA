package components

import (
	"context"
	"errors"
	"fmt"
	"strings"

	componentdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/component"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
)

// Service exposes catalog listings filtered for client configuration
type Service struct {
	repo outbound.ComponentRepository
}

// NewService assembles a catalog service backed by a component repository
func NewService(repo outbound.ComponentRepository) *Service {
	return &Service{repo: repo}
}

// ListOptions define catalog filters supplied by clients
type ListOptions struct {
	Kind     string
	Provider string
}

// ErrInvalidKind indicates the requested kind filter is unsupported
var ErrInvalidKind = errors.New("components: invalid kind")

// List retrieves enabled components honoring the provided filters
func (s *Service) List(ctx context.Context, opts ListOptions) ([]componentdomain.Component, error) {
	if s == nil || s.repo == nil {
		return nil, fmt.Errorf("components.Service.List: repository unavailable")
	}

	var kindPtr *componentdomain.Kind
	if trimmed := strings.TrimSpace(strings.ToLower(opts.Kind)); trimmed != "" {
		kind := componentdomain.Kind(trimmed)
		switch kind {
		case componentdomain.KindAction, componentdomain.KindReaction:
			kindPtr = &kind
		default:
			return nil, fmt.Errorf("components.Service.List: %w", ErrInvalidKind)
		}
	}

	filters := outbound.ComponentListOptions{
		Kind:     kindPtr,
		Provider: strings.TrimSpace(strings.ToLower(opts.Provider)),
	}

	items, err := s.repo.List(ctx, filters)
	if err != nil {
		return nil, fmt.Errorf("components.Service.List: repo.List: %w", err)
	}
	return items, nil
}

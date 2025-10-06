package components

import (
	"context"
	"errors"
	"fmt"
	"strings"

	componentdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/component"
	subscriptiondomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/subscription"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
	"github.com/google/uuid"
)

// Service exposes catalog listings filtered for client configuration
type Service struct {
	repo          outbound.ComponentRepository
	subscriptions outbound.SubscriptionRepository
}

// NewService assembles a catalog service backed by component and subscription repositories
func NewService(repo outbound.ComponentRepository, subscriptions outbound.SubscriptionRepository) *Service {
	return &Service{repo: repo, subscriptions: subscriptions}
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

	filters, err := buildListFilters(opts)
	if err != nil {
		return nil, fmt.Errorf("components.Service.List: %w", err)
	}

	items, err := s.repo.List(ctx, filters)
	if err != nil {
		return nil, fmt.Errorf("components.Service.List: repo.List: %w", err)
	}
	return items, nil
}

// ListAvailable fetches components whose providers are subscribed by the specified user
func (s *Service) ListAvailable(ctx context.Context, userID uuid.UUID, opts ListOptions) ([]componentdomain.Component, error) {
	if s == nil || s.repo == nil || s.subscriptions == nil {
		return nil, fmt.Errorf("components.Service.ListAvailable: repositories unavailable")
	}
	if userID == uuid.Nil {
		return nil, fmt.Errorf("components.Service.ListAvailable: missing user id")
	}

	subs, err := s.subscriptions.ListByUser(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("components.Service.ListAvailable: subscriptions.ListByUser: %w", err)
	}

	providers := make(map[uuid.UUID]struct{}, len(subs))
	for _, sub := range subs {
		if sub.Status == subscriptiondomain.StatusActive {
			providers[sub.ProviderID] = struct{}{}
		}
	}

	if len(providers) == 0 {
		return []componentdomain.Component{}, nil
	}

	filters, err := buildListFilters(opts)
	if err != nil {
		return nil, fmt.Errorf("components.Service.ListAvailable: %w", err)
	}

	items, err := s.repo.List(ctx, filters)
	if err != nil {
		return nil, fmt.Errorf("components.Service.ListAvailable: repo.List: %w", err)
	}

	filtered := make([]componentdomain.Component, 0, len(items))
	for _, item := range items {
		if _, ok := providers[item.ProviderID]; ok {
			filtered = append(filtered, item)
		}
	}
	return filtered, nil
}

func buildListFilters(opts ListOptions) (outbound.ComponentListOptions, error) {
	var kindPtr *componentdomain.Kind
	if trimmed := strings.TrimSpace(strings.ToLower(opts.Kind)); trimmed != "" {
		kind := componentdomain.Kind(trimmed)
		switch kind {
		case componentdomain.KindAction, componentdomain.KindReaction:
			kindPtr = &kind
		default:
			return outbound.ComponentListOptions{}, ErrInvalidKind
		}
	}

	return outbound.ComponentListOptions{
		Kind:     kindPtr,
		Provider: strings.TrimSpace(strings.ToLower(opts.Provider)),
	}, nil
}

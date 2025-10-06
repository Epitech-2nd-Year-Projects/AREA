package components

import (
	"context"
	"errors"
	"testing"

	componentdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/component"
	subscriptiondomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/subscription"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
	"github.com/google/uuid"
)

type stubComponentRepo struct {
	items    []componentdomain.Component
	err      error
	lastOpts outbound.ComponentListOptions
}

func (s *stubComponentRepo) FindByID(ctx context.Context, id uuid.UUID) (componentdomain.Component, error) {
	return componentdomain.Component{}, outbound.ErrNotFound
}

func (s *stubComponentRepo) FindByIDs(ctx context.Context, ids []uuid.UUID) (map[uuid.UUID]componentdomain.Component, error) {
	return map[uuid.UUID]componentdomain.Component{}, nil
}

func (s *stubComponentRepo) List(ctx context.Context, opts outbound.ComponentListOptions) ([]componentdomain.Component, error) {
	s.lastOpts = opts
	if s.err != nil {
		return nil, s.err
	}
	return append([]componentdomain.Component(nil), s.items...), nil
}

type stubSubscriptionRepo struct {
	items map[uuid.UUID][]subscriptiondomain.Subscription
	err   error
}

func (s *stubSubscriptionRepo) Create(ctx context.Context, subscription subscriptiondomain.Subscription) (subscriptiondomain.Subscription, error) {
	return subscription, nil
}

func (s *stubSubscriptionRepo) Update(ctx context.Context, subscription subscriptiondomain.Subscription) error {
	return nil
}

func (s *stubSubscriptionRepo) FindByUserAndProvider(ctx context.Context, userID uuid.UUID, providerID uuid.UUID) (subscriptiondomain.Subscription, error) {
	return subscriptiondomain.Subscription{}, outbound.ErrNotFound
}

func (s *stubSubscriptionRepo) ListByUser(ctx context.Context, userID uuid.UUID) ([]subscriptiondomain.Subscription, error) {
	if s.err != nil {
		return nil, s.err
	}
	if s.items == nil {
		return []subscriptiondomain.Subscription{}, nil
	}
	return append([]subscriptiondomain.Subscription(nil), s.items[userID]...), nil
}

func TestServiceListInvalidKind(t *testing.T) {
	repo := &stubComponentRepo{}
	svc := NewService(repo, nil)

	_, err := svc.List(context.Background(), ListOptions{Kind: "unsupported"})
	if !errors.Is(err, ErrInvalidKind) {
		t.Fatalf("expected ErrInvalidKind, got %v", err)
	}
}

func TestServiceListAppliesFilters(t *testing.T) {
	providerID := uuid.New()
	repo := &stubComponentRepo{
		items: []componentdomain.Component{{
			ID:          uuid.New(),
			Provider:    componentdomain.Provider{ID: providerID, Name: "scheduler", DisplayName: "Scheduler"},
			Kind:        componentdomain.KindAction,
			Name:        "timer_interval",
			DisplayName: "Recurring timer",
			Enabled:     true,
		}},
	}

	svc := NewService(repo, nil)

	results, err := svc.List(context.Background(), ListOptions{Kind: "ACTION", Provider: " Scheduler "})
	if err != nil {
		t.Fatalf("List returned error: %v", err)
	}
	if len(results) != 1 {
		t.Fatalf("expected 1 component, got %d", len(results))
	}
	if repo.lastOpts.Kind == nil || *repo.lastOpts.Kind != componentdomain.KindAction {
		t.Fatalf("expected kind filter to be action, got %v", repo.lastOpts.Kind)
	}
	if repo.lastOpts.Provider != "scheduler" {
		t.Fatalf("expected provider filter 'scheduler', got %q", repo.lastOpts.Provider)
	}
}

func TestServiceListAvailableFiltersBySubscriptions(t *testing.T) {
	ctx := context.Background()
	providerAction := uuid.New()
	providerOther := uuid.New()
	repo := &stubComponentRepo{
		items: []componentdomain.Component{
			{ID: uuid.New(), ProviderID: providerAction, Kind: componentdomain.KindAction, Name: "timer_interval"},
			{ID: uuid.New(), ProviderID: providerOther, Kind: componentdomain.KindReaction, Name: "gmail_send"},
		},
	}

	userID := uuid.New()
	subsRepo := &stubSubscriptionRepo{items: map[uuid.UUID][]subscriptiondomain.Subscription{
		userID: {
			{UserID: userID, ProviderID: providerAction, Status: subscriptiondomain.StatusActive},
			{UserID: userID, ProviderID: providerOther, Status: subscriptiondomain.StatusRevoked},
		},
	}}

	svc := NewService(repo, subsRepo)

	components, err := svc.ListAvailable(ctx, userID, ListOptions{})
	if err != nil {
		t.Fatalf("ListAvailable returned error: %v", err)
	}
	if len(components) != 1 {
		t.Fatalf("expected 1 component, got %d", len(components))
	}
	if components[0].ProviderID != providerAction {
		t.Fatalf("expected provider %s, got %s", providerAction, components[0].ProviderID)
	}
}

func TestServiceListAvailableRequiresUser(t *testing.T) {
	svc := NewService(&stubComponentRepo{}, &stubSubscriptionRepo{})

	_, err := svc.ListAvailable(context.Background(), uuid.Nil, ListOptions{})
	if err == nil {
		t.Fatalf("expected error when user id missing")
	}
}

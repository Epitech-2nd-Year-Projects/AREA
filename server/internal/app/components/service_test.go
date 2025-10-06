package components

import (
	"context"
	"errors"
	"testing"

	componentdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/component"
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

func TestServiceListInvalidKind(t *testing.T) {
	repo := &stubComponentRepo{}
	svc := NewService(repo)

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

	svc := NewService(repo)

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

package area

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"

	areadomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/area"
	componentdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/component"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
	"github.com/google/uuid"
)

type stubClock struct{ now time.Time }

func (c stubClock) Now() time.Time { return c.now }

func TestService_CreateAndList(t *testing.T) {
	ctx := context.Background()
	clock := stubClock{now: time.Unix(1720000000, 0).UTC()}
	repo := &memoryAreaRepo{items: map[uuid.UUID]areadomain.Area{}}
	componentID := uuid.New()
	components := &memoryComponentRepo{items: map[uuid.UUID]componentdomain.Component{
		componentID: {
			ID:         componentID,
			Kind:       componentdomain.KindAction,
			Enabled:    true,
			ProviderID: uuid.New(),
		},
	}}
	svc := NewService(repo, components, clock)

	userID := uuid.New()
	area, err := svc.Create(ctx, userID, "Morning digest", "Send me a digest every morning", ActionInput{
		ComponentID: componentID,
		Params:      map[string]any{"channel": "mail"},
	})
	if err != nil {
		t.Fatalf("Create returned error: %v", err)
	}
	if area.Name != "Morning digest" {
		t.Fatalf("unexpected name %s", area.Name)
	}
	if area.Description == nil || *area.Description != "Send me a digest every morning" {
		t.Fatalf("description not persisted")
	}
	if area.Status != areadomain.StatusEnabled {
		t.Fatalf("expected enabled status got %s", area.Status)
	}
	if !area.CreatedAt.Equal(clock.now) {
		t.Fatalf("created at mismatch")
	}

	if area.Action == nil {
		t.Fatalf("expected action to be set")
	}
	if area.Action.Config.Component == nil {
		t.Fatalf("expected action component metadata to be attached")
	}

	areas, err := svc.List(ctx, userID)
	if err != nil {
		t.Fatalf("List returned error: %v", err)
	}
	if len(areas) != 1 {
		t.Fatalf("expected one area, got %d", len(areas))
	}
	if areas[0].ID != area.ID {
		t.Fatalf("listed area does not match created area")
	}
	if areas[0].Action == nil || areas[0].Action.Config.Component == nil {
		t.Fatalf("expected action component enrichment on list")
	}
}

func TestService_CreateValidation(t *testing.T) {
	ctx := context.Background()
	repo := &memoryAreaRepo{items: map[uuid.UUID]areadomain.Area{}}
	componentID := uuid.New()
	components := &memoryComponentRepo{items: map[uuid.UUID]componentdomain.Component{
		componentID: {
			ID:         componentID,
			Kind:       componentdomain.KindAction,
			Enabled:    true,
			ProviderID: uuid.New(),
		},
	}}
	svc := NewService(repo, components, stubClock{now: time.Now()})

	tests := []struct {
		name        string
		description string
		expectedErr error
	}{
		{name: "", expectedErr: ErrNameRequired},
		{name: strings.Repeat("a", nameMaxLength+1), expectedErr: ErrNameTooLong},
		{name: "Valid", description: strings.Repeat("b", descriptionMaxLength+1), expectedErr: ErrDescriptionTooLong},
	}

	for _, tc := range tests {
		t.Run(tc.expectedErr.Error(), func(t *testing.T) {
			_, err := svc.Create(ctx, uuid.New(), tc.name, tc.description, ActionInput{ComponentID: componentID})
			if err == nil {
				t.Fatalf("expected error %v, got nil", tc.expectedErr)
			}
			if !errors.Is(err, tc.expectedErr) {
				t.Fatalf("expected error %v, got %v", tc.expectedErr, err)
			}
		})
	}
}

func TestService_CreateActionValidation(t *testing.T) {
	ctx := context.Background()
	repo := &memoryAreaRepo{items: map[uuid.UUID]areadomain.Area{}}
	components := &memoryComponentRepo{items: map[uuid.UUID]componentdomain.Component{}}
	svc := NewService(repo, components, stubClock{now: time.Now()})

	_, err := svc.Create(ctx, uuid.New(), "Valid", "", ActionInput{})
	if !errors.Is(err, ErrActionComponentRequired) {
		t.Fatalf("expected ErrActionComponentRequired got %v", err)
	}

	reactionID := uuid.New()
	components.items[reactionID] = componentdomain.Component{ID: reactionID, Kind: componentdomain.KindReaction, Enabled: true}
	_, err = svc.Create(ctx, uuid.New(), "Valid", "", ActionInput{ComponentID: reactionID})
	if !errors.Is(err, ErrActionComponentInvalid) {
		t.Fatalf("expected ErrActionComponentInvalid got %v", err)
	}

	actionID := uuid.New()
	components.items[actionID] = componentdomain.Component{ID: actionID, Kind: componentdomain.KindAction, Enabled: false}
	_, err = svc.Create(ctx, uuid.New(), "Valid", "", ActionInput{ComponentID: actionID})
	if !errors.Is(err, ErrActionComponentDisabled) {
		t.Fatalf("expected ErrActionComponentDisabled got %v", err)
	}
}

type memoryAreaRepo struct {
	items map[uuid.UUID]areadomain.Area
}

func (m *memoryAreaRepo) Create(ctx context.Context, area areadomain.Area, link areadomain.Link) (areadomain.Area, error) {
	if m.items == nil {
		m.items = map[uuid.UUID]areadomain.Area{}
	}
	if area.ID == uuid.Nil {
		area.ID = uuid.New()
	}
	if link.ID == uuid.Nil {
		link.ID = uuid.New()
	}
	link.AreaID = area.ID
	link.Config.ID = uuid.New()
	link.CreatedAt = area.CreatedAt
	link.UpdatedAt = area.UpdatedAt
	area.Action = &link
	m.items[area.ID] = area
	return area, nil
}

func (m *memoryAreaRepo) FindByID(ctx context.Context, id uuid.UUID) (areadomain.Area, error) {
	area, ok := m.items[id]
	if !ok {
		return areadomain.Area{}, outbound.ErrNotFound
	}
	return area, nil
}

func (m *memoryAreaRepo) ListByUser(ctx context.Context, userID uuid.UUID) ([]areadomain.Area, error) {
	var areas []areadomain.Area
	for _, area := range m.items {
		if area.UserID == userID {
			areas = append(areas, area)
		}
	}
	return areas, nil
}

type memoryComponentRepo struct {
	items map[uuid.UUID]componentdomain.Component
}

func (m *memoryComponentRepo) FindByID(ctx context.Context, id uuid.UUID) (componentdomain.Component, error) {
	component, ok := m.items[id]
	if !ok {
		return componentdomain.Component{}, outbound.ErrNotFound
	}
	return component, nil
}

func (m *memoryComponentRepo) FindByIDs(ctx context.Context, ids []uuid.UUID) (map[uuid.UUID]componentdomain.Component, error) {
	result := make(map[uuid.UUID]componentdomain.Component, len(ids))
	for _, id := range ids {
		if component, ok := m.items[id]; ok {
			result[id] = component
		}
	}
	return result, nil
}

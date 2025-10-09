package area

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"testing"
	"time"

	actiondomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/action"
	areadomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/area"
	componentdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/component"
	subscriptiondomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/subscription"
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
	reactionID := uuid.New()
	components := &memoryComponentRepo{items: map[uuid.UUID]componentdomain.Component{
		componentID: {
			ID:         componentID,
			Kind:       componentdomain.KindAction,
			Enabled:    true,
			ProviderID: uuid.New(),
		},
		reactionID: {
			ID:         reactionID,
			Kind:       componentdomain.KindReaction,
			Enabled:    true,
			ProviderID: uuid.New(),
		},
	}}
	subs := allowAllSubscriptions{}
	svc := NewService(repo, components, subs, nil, nil, clock, nil)

	userID := uuid.New()
	area, err := svc.Create(ctx, userID, "Morning digest", "Send me a digest every morning", ActionInput{
		ComponentID: componentID,
		Params:      map[string]any{"channel": "mail"},
	}, []ReactionInput{
		{
			ComponentID: reactionID,
			Params:      map[string]any{"message": "Hello"},
		},
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
	if len(area.Reactions) != 1 {
		t.Fatalf("expected one reaction, got %d", len(area.Reactions))
	}
	if area.Reactions[0].Config.Component == nil {
		t.Fatalf("expected reaction component metadata to be attached")
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
	if len(areas[0].Reactions) != 1 || areas[0].Reactions[0].Config.Component == nil {
		t.Fatalf("expected reaction component enrichment on list")
	}
}

func TestService_CreateValidation(t *testing.T) {
	ctx := context.Background()
	repo := &memoryAreaRepo{items: map[uuid.UUID]areadomain.Area{}}
	componentID := uuid.New()
	reactionID := uuid.New()
	components := &memoryComponentRepo{items: map[uuid.UUID]componentdomain.Component{
		componentID: {
			ID:         componentID,
			Kind:       componentdomain.KindAction,
			Enabled:    true,
			ProviderID: uuid.New(),
		},
		reactionID: {
			ID:         reactionID,
			Kind:       componentdomain.KindReaction,
			Enabled:    true,
			ProviderID: uuid.New(),
		},
	}}
	svc := NewService(repo, components, nil, nil, nil, stubClock{now: time.Now()}, nil)

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
			_, err := svc.Create(ctx, uuid.New(), tc.name, tc.description, ActionInput{ComponentID: componentID}, []ReactionInput{{ComponentID: reactionID}})
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
	reactionComponentID := uuid.New()
	components := &memoryComponentRepo{items: map[uuid.UUID]componentdomain.Component{
		reactionComponentID: {
			ID:         reactionComponentID,
			Kind:       componentdomain.KindReaction,
			Enabled:    true,
			ProviderID: uuid.New(),
		},
	}}
	subs := allowAllSubscriptions{}
	svc := NewService(repo, components, subs, nil, nil, stubClock{now: time.Now()}, nil)

	_, err := svc.Create(ctx, uuid.New(), "Valid", "", ActionInput{}, []ReactionInput{{ComponentID: reactionComponentID}})
	if !errors.Is(err, ErrActionComponentRequired) {
		t.Fatalf("expected ErrActionComponentRequired got %v", err)
	}

	otherReactionID := uuid.New()
	components.items[otherReactionID] = componentdomain.Component{ID: otherReactionID, Kind: componentdomain.KindReaction, Enabled: true}
	_, err = svc.Create(ctx, uuid.New(), "Valid", "", ActionInput{ComponentID: otherReactionID}, []ReactionInput{{ComponentID: reactionComponentID}})
	if !errors.Is(err, ErrActionComponentInvalid) {
		t.Fatalf("expected ErrActionComponentInvalid got %v", err)
	}

	actionID := uuid.New()
	components.items[actionID] = componentdomain.Component{ID: actionID, Kind: componentdomain.KindAction, Enabled: false}
	_, err = svc.Create(ctx, uuid.New(), "Valid", "", ActionInput{ComponentID: actionID}, []ReactionInput{{ComponentID: reactionComponentID}})
	if !errors.Is(err, ErrActionComponentDisabled) {
		t.Fatalf("expected ErrActionComponentDisabled got %v", err)
	}
}

func TestService_CreateReactionValidation(t *testing.T) {
	ctx := context.Background()
	repo := &memoryAreaRepo{items: map[uuid.UUID]areadomain.Area{}}
	components := &memoryComponentRepo{items: map[uuid.UUID]componentdomain.Component{}}
	actionID := uuid.New()
	components.items[actionID] = componentdomain.Component{ID: actionID, Kind: componentdomain.KindAction, Enabled: true, ProviderID: uuid.New()}
	reactionID := uuid.New()
	components.items[reactionID] = componentdomain.Component{ID: reactionID, Kind: componentdomain.KindReaction, Enabled: true, ProviderID: uuid.New()}
	subs := allowAllSubscriptions{}
	svc := NewService(repo, components, subs, nil, nil, stubClock{now: time.Now()}, nil)

	_, err := svc.Create(ctx, uuid.New(), "Valid", "", ActionInput{ComponentID: actionID}, nil)
	if !errors.Is(err, ErrReactionsRequired) {
		t.Fatalf("expected ErrReactionsRequired got %v", err)
	}

	missingID := uuid.New()
	_, err = svc.Create(ctx, uuid.New(), "Valid", "", ActionInput{ComponentID: actionID}, []ReactionInput{{ComponentID: missingID}})
	if !errors.Is(err, ErrReactionComponentInvalid) {
		t.Fatalf("expected ErrReactionComponentInvalid got %v", err)
	}

	components.items[missingID] = componentdomain.Component{ID: missingID, Kind: componentdomain.KindAction, Enabled: true, ProviderID: uuid.New()}
	_, err = svc.Create(ctx, uuid.New(), "Valid", "", ActionInput{ComponentID: actionID}, []ReactionInput{{ComponentID: missingID}})
	if !errors.Is(err, ErrReactionComponentInvalid) {
		t.Fatalf("expected ErrReactionComponentInvalid got %v", err)
	}

	disabledID := uuid.New()
	components.items[disabledID] = componentdomain.Component{ID: disabledID, Kind: componentdomain.KindReaction, Enabled: false, ProviderID: uuid.New()}
	_, err = svc.Create(ctx, uuid.New(), "Valid", "", ActionInput{ComponentID: actionID}, []ReactionInput{{ComponentID: disabledID}})
	if !errors.Is(err, ErrReactionComponentDisabled) {
		t.Fatalf("expected ErrReactionComponentDisabled got %v", err)
	}
}

func TestService_CreateRequiresSubscription(t *testing.T) {
	ctx := context.Background()
	repo := &memoryAreaRepo{items: map[uuid.UUID]areadomain.Area{}}
	providerID := uuid.New()
	actionID := uuid.New()
	reactionID := uuid.New()
	components := &memoryComponentRepo{items: map[uuid.UUID]componentdomain.Component{
		actionID: {
			ID:         actionID,
			Kind:       componentdomain.KindAction,
			Enabled:    true,
			ProviderID: providerID,
		},
		reactionID: {
			ID:         reactionID,
			Kind:       componentdomain.KindReaction,
			Enabled:    true,
			ProviderID: providerID,
		},
	}}
	subs := denyingSubscriptions{}
	svc := NewService(repo, components, subs, nil, nil, stubClock{now: time.Now()}, nil)

	_, err := svc.Create(ctx, uuid.New(), "Test", "", ActionInput{ComponentID: actionID}, []ReactionInput{{ComponentID: reactionID}})
	if !errors.Is(err, ErrProviderSubscriptionMissing) {
		t.Fatalf("expected ErrProviderSubscriptionMissing got %v", err)
	}
}

func TestService_CreateValidatesParams(t *testing.T) {
	ctx := context.Background()
	repo := &memoryAreaRepo{items: map[uuid.UUID]areadomain.Area{}}
	providerID := uuid.New()
	actionID := uuid.New()
	reactionID := uuid.New()
	metadata := map[string]any{
		"parameters": []any{
			map[string]any{
				"key":      "value",
				"type":     "integer",
				"required": true,
			},
		},
	}
	components := &memoryComponentRepo{items: map[uuid.UUID]componentdomain.Component{
		actionID: {
			ID:         actionID,
			Kind:       componentdomain.KindAction,
			Enabled:    true,
			ProviderID: providerID,
			Metadata:   metadata,
		},
		reactionID: {
			ID:         reactionID,
			Kind:       componentdomain.KindReaction,
			Enabled:    true,
			ProviderID: providerID,
			Metadata:   metadata,
		},
	}}
	subs := allowAllSubscriptions{}
	svc := NewService(repo, components, subs, nil, nil, stubClock{now: time.Now()}, nil)

	_, err := svc.Create(ctx, uuid.New(), "Test", "", ActionInput{ComponentID: actionID, Params: map[string]any{"value": "oops"}}, []ReactionInput{{ComponentID: reactionID, Params: map[string]any{"value": 1}}})
	if !errors.Is(err, ErrComponentParamsInvalid) {
		t.Fatalf("expected ErrComponentParamsInvalid got %v", err)
	}
}

type memoryAreaRepo struct {
	items map[uuid.UUID]areadomain.Area
}

func (m *memoryAreaRepo) Create(ctx context.Context, area areadomain.Area, action areadomain.Link, reactions []areadomain.Link) (areadomain.Area, error) {
	if m.items == nil {
		m.items = map[uuid.UUID]areadomain.Area{}
	}
	if area.ID == uuid.Nil {
		area.ID = uuid.New()
	}
	if action.ID == uuid.Nil {
		action.ID = uuid.New()
	}
	action.AreaID = area.ID
	if action.Config.ID == uuid.Nil {
		action.Config.ID = uuid.New()
	}
	action.CreatedAt = area.CreatedAt
	action.UpdatedAt = area.UpdatedAt
	area.Action = &action
	area.Reactions = make([]areadomain.Link, 0, len(reactions))
	for _, reaction := range reactions {
		if reaction.ID == uuid.Nil {
			reaction.ID = uuid.New()
		}
		reaction.AreaID = area.ID
		if reaction.Config.ID == uuid.Nil {
			reaction.Config.ID = uuid.New()
		}
		reaction.CreatedAt = area.CreatedAt
		reaction.UpdatedAt = area.UpdatedAt
		area.Reactions = append(area.Reactions, reaction)
	}
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

func (m *memoryAreaRepo) Delete(ctx context.Context, id uuid.UUID) error {
	delete(m.items, id)
	return nil
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

func (m *memoryComponentRepo) List(ctx context.Context, opts outbound.ComponentListOptions) ([]componentdomain.Component, error) {
	components := make([]componentdomain.Component, 0, len(m.items))
	for _, component := range m.items {
		if opts.Kind != nil && component.Kind != *opts.Kind {
			continue
		}
		if opts.Provider != "" && !strings.EqualFold(component.Provider.Name, opts.Provider) {
			continue
		}
		components = append(components, component)
	}
	return components, nil
}

type allowAllSubscriptions struct{}

func (allowAllSubscriptions) Create(ctx context.Context, subscription subscriptiondomain.Subscription) (subscriptiondomain.Subscription, error) {
	return subscription, nil
}

func (allowAllSubscriptions) Update(ctx context.Context, subscription subscriptiondomain.Subscription) error {
	return nil
}

func (allowAllSubscriptions) FindByUserAndProvider(ctx context.Context, userID uuid.UUID, providerID uuid.UUID) (subscriptiondomain.Subscription, error) {
	return subscriptiondomain.Subscription{
		ID:         uuid.New(),
		UserID:     userID,
		ProviderID: providerID,
		Status:     subscriptiondomain.StatusActive,
	}, nil
}

func (allowAllSubscriptions) ListByUser(ctx context.Context, userID uuid.UUID) ([]subscriptiondomain.Subscription, error) {
	return []subscriptiondomain.Subscription{}, nil
}

type denyingSubscriptions struct{}

func (denyingSubscriptions) Create(ctx context.Context, subscription subscriptiondomain.Subscription) (subscriptiondomain.Subscription, error) {
	return subscription, nil
}

func (denyingSubscriptions) Update(ctx context.Context, subscription subscriptiondomain.Subscription) error {
	return nil
}

func (denyingSubscriptions) FindByUserAndProvider(ctx context.Context, userID uuid.UUID, providerID uuid.UUID) (subscriptiondomain.Subscription, error) {
	return subscriptiondomain.Subscription{}, outbound.ErrNotFound
}

func (denyingSubscriptions) ListByUser(ctx context.Context, userID uuid.UUID) ([]subscriptiondomain.Subscription, error) {
	return []subscriptiondomain.Subscription{}, nil
}

type recordingPipeline struct {
	inputs []ExecutionInput
}

func (p *recordingPipeline) Enqueue(ctx context.Context, input ExecutionInput) error {
	p.inputs = append(p.inputs, input)
	return nil
}

type stubActionSourceRepo struct {
	sources map[uuid.UUID]actiondomain.Source
}

func (s *stubActionSourceRepo) UpsertScheduleSource(ctx context.Context, componentConfigID uuid.UUID, schedule string, cursor map[string]any) (actiondomain.Source, error) {
	return actiondomain.Source{}, fmt.Errorf("not implemented")
}

func (s *stubActionSourceRepo) ListDueScheduleSources(ctx context.Context, before time.Time, limit int) ([]actiondomain.ScheduleBinding, error) {
	return nil, fmt.Errorf("not implemented")
}

func (s *stubActionSourceRepo) UpdateScheduleCursor(ctx context.Context, sourceID uuid.UUID, componentConfigID uuid.UUID, cursor map[string]any) error {
	return fmt.Errorf("not implemented")
}

func (s *stubActionSourceRepo) FindByComponentConfig(ctx context.Context, componentConfigID uuid.UUID) (actiondomain.Source, error) {
	if source, ok := s.sources[componentConfigID]; ok {
		return source, nil
	}
	return actiondomain.Source{}, outbound.ErrNotFound
}

func TestService_Execute(t *testing.T) {
	ctx := context.Background()
	repo := &memoryAreaRepo{items: map[uuid.UUID]areadomain.Area{}}
	actionID := uuid.New()
	reactionID := uuid.New()
	providerID := uuid.New()
	components := &memoryComponentRepo{items: map[uuid.UUID]componentdomain.Component{
		actionID: {
			ID: actionID, Kind: componentdomain.KindAction, Enabled: true,
			ProviderID: providerID,
			Provider:   componentdomain.Provider{ID: providerID, Name: "github", DisplayName: "GitHub"},
		},
		reactionID: {
			ID: reactionID, Kind: componentdomain.KindReaction, Enabled: true,
			ProviderID: providerID,
			Provider:   componentdomain.Provider{ID: providerID, Name: "github", DisplayName: "GitHub"},
		},
	}}

	actionConfigID := uuid.New()
	reactionConfigID := uuid.New()
	actionSourceID := uuid.New()
	sources := &stubActionSourceRepo{sources: map[uuid.UUID]actiondomain.Source{
		actionConfigID: {
			ID:                actionSourceID,
			ComponentConfigID: actionConfigID,
			Mode:              actiondomain.ModeSchedule,
			IsActive:          true,
		},
	}}
	subs := allowAllSubscriptions{}
	pipeline := &recordingPipeline{}
	svc := NewService(repo, components, subs, sources, pipeline, stubClock{now: time.Now()}, nil)

	userID := uuid.New()
	areaID := uuid.New()
	repo.items[areaID] = areadomain.Area{
		ID:     areaID,
		UserID: userID,
		Name:   "Test AREA",
		Status: areadomain.StatusEnabled,
		Action: &areadomain.Link{
			ID:   uuid.New(),
			Role: areadomain.LinkRoleAction,
			Config: componentdomain.Config{
				ID:          actionConfigID,
				ComponentID: actionID,
			},
		},
		Reactions: []areadomain.Link{{
			ID:   uuid.New(),
			Role: areadomain.LinkRoleReaction,
			Config: componentdomain.Config{
				ID:          reactionConfigID,
				ComponentID: reactionID,
			},
		}},
	}

	if err := svc.Execute(ctx, userID, areaID); err != nil {
		t.Fatalf("Execute returned error: %v", err)
	}
	if len(pipeline.inputs) != 1 {
		t.Fatalf("expected 1 pipeline invocation, got %d", len(pipeline.inputs))
	}
	input := pipeline.inputs[0]
	if input.SourceID != actionSourceID {
		t.Fatalf("unexpected source id: %s", input.SourceID)
	}
	if input.Area.ID != areaID {
		t.Fatalf("unexpected area propagated")
	}
	if len(input.Area.Reactions) != 1 {
		t.Fatalf("expected one reaction in pipeline payload")
	}
	if input.Area.Reactions[0].Config.ComponentID != reactionID {
		t.Fatalf("unexpected reaction component propagated")
	}
}

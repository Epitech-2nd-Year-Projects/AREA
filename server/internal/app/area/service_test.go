package area

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"

	areadomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/area"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
	"github.com/google/uuid"
)

type stubClock struct{ now time.Time }

func (c stubClock) Now() time.Time { return c.now }

func TestService_CreateAndList(t *testing.T) {
	ctx := context.Background()
	clock := stubClock{now: time.Unix(1720000000, 0).UTC()}
	repo := &memoryAreaRepo{items: map[uuid.UUID]areadomain.Area{}}
	svc := NewService(repo, clock)

	userID := uuid.New()
	area, err := svc.Create(ctx, userID, "Morning digest", "Send me a digest every morning")
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
}

func TestService_CreateValidation(t *testing.T) {
	ctx := context.Background()
	repo := &memoryAreaRepo{items: map[uuid.UUID]areadomain.Area{}}
	svc := NewService(repo, stubClock{now: time.Now()})

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
			_, err := svc.Create(ctx, uuid.New(), tc.name, tc.description)
			if err == nil {
				t.Fatalf("expected error %v, got nil", tc.expectedErr)
			}
			if !errors.Is(err, tc.expectedErr) {
				t.Fatalf("expected error %v, got %v", tc.expectedErr, err)
			}
		})
	}
}

type memoryAreaRepo struct {
	items map[uuid.UUID]areadomain.Area
}

func (m *memoryAreaRepo) Create(ctx context.Context, area areadomain.Area) (areadomain.Area, error) {
	if m.items == nil {
		m.items = map[uuid.UUID]areadomain.Area{}
	}
	if area.ID == uuid.Nil {
		area.ID = uuid.New()
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

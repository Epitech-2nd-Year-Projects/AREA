package area

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"
	"unicode/utf8"

	areadomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/area"
	componentdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/component"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
	"github.com/google/uuid"
)

// Clock abstracts time for deterministic testing
type Clock interface {
	Now() time.Time
}

type systemClock struct{}

func (systemClock) Now() time.Time { return time.Now() }

// Service orchestrates creation and retrieval of AREA automations
type Service struct {
	repo       outbound.AreaRepository
	components outbound.ComponentRepository
	clock      Clock
}

// Validation errors returned by the service
var (
	ErrNameRequired            = errors.New("area: name required")
	ErrNameTooLong             = errors.New("area: name exceeds limit")
	ErrDescriptionTooLong      = errors.New("area: description exceeds limit")
	ErrActionComponentRequired = errors.New("area: action component required")
	ErrActionComponentInvalid  = errors.New("area: action component invalid")
	ErrActionComponentDisabled = errors.New("area: action component disabled")
)

const (
	nameMaxLength        = 128
	descriptionMaxLength = 512
)

// NewService builds a Service bound to the provided repository
func NewService(repo outbound.AreaRepository, components outbound.ComponentRepository, clock Clock) *Service {
	if clock == nil {
		clock = systemClock{}
	}
	return &Service{repo: repo, components: components, clock: clock}
}

// ActionInput carries action configuration used when creating an AREA
type ActionInput struct {
	ComponentID uuid.UUID
	Name        string
	Params      map[string]any
}

// Create registers a new automation owned by the given user
func (s *Service) Create(ctx context.Context, userID uuid.UUID, name string, description string, action ActionInput) (areadomain.Area, error) {
	if s.repo == nil {
		return areadomain.Area{}, fmt.Errorf("area.Service.Create: repository unavailable")
	}
	if s.components == nil {
		return areadomain.Area{}, fmt.Errorf("area.Service.Create: component repository unavailable")
	}

	name = strings.TrimSpace(name)
	if name == "" {
		return areadomain.Area{}, fmt.Errorf("area.Service.Create: %w", ErrNameRequired)
	}
	if utf8.RuneCountInString(name) > nameMaxLength {
		return areadomain.Area{}, fmt.Errorf("area.Service.Create: %w", ErrNameTooLong)
	}

	desc := strings.TrimSpace(description)
	if desc != "" && utf8.RuneCountInString(desc) > descriptionMaxLength {
		return areadomain.Area{}, fmt.Errorf("area.Service.Create: %w", ErrDescriptionTooLong)
	}

	if action.ComponentID == uuid.Nil {
		return areadomain.Area{}, fmt.Errorf("area.Service.Create: %w", ErrActionComponentRequired)
	}

	component, err := s.components.FindByID(ctx, action.ComponentID)
	if err != nil {
		if errors.Is(err, outbound.ErrNotFound) {
			return areadomain.Area{}, fmt.Errorf("area.Service.Create: %w", ErrActionComponentInvalid)
		}
		return areadomain.Area{}, fmt.Errorf("area.Service.Create: components.FindByID: %w", err)
	}
	if component.Kind != componentdomain.KindAction {
		return areadomain.Area{}, fmt.Errorf("area.Service.Create: %w", ErrActionComponentInvalid)
	}
	if !component.Enabled {
		return areadomain.Area{}, fmt.Errorf("area.Service.Create: %w", ErrActionComponentDisabled)
	}

	params := action.Params
	if params == nil {
		params = map[string]any{}
	}

	now := s.clock.Now().UTC()
	area := areadomain.Area{
		ID:        uuid.New(),
		UserID:    userID,
		Name:      name,
		Status:    areadomain.StatusEnabled,
		CreatedAt: now,
		UpdatedAt: now,
	}
	if desc != "" {
		area = area.WithDescription(desc)
	}

	config := componentdomain.Config{
		UserID:      userID,
		ComponentID: component.ID,
		Name:        strings.TrimSpace(action.Name),
		Params:      params,
		Active:      true,
	}

	link := areadomain.Link{
		Role:     areadomain.LinkRoleAction,
		Position: 1,
		Config:   config,
	}

	stored, err := s.repo.Create(ctx, area, link)
	if err != nil {
		return areadomain.Area{}, fmt.Errorf("area.Service.Create: repo.Create: %w", err)
	}
	if stored.Action != nil {
		stored.Action.Config.Component = &component
	}
	return stored, nil
}

// List fetches all areas owned by the given user
func (s *Service) List(ctx context.Context, userID uuid.UUID) ([]areadomain.Area, error) {
	if s.repo == nil {
		return nil, fmt.Errorf("area.Service.List: repository unavailable")
	}
	areas, err := s.repo.ListByUser(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("area.Service.List: repo.ListByUser: %w", err)
	}
	return s.populateComponents(ctx, areas)
}

// Get returns a single area by identifier ensuring ownership
func (s *Service) Get(ctx context.Context, userID uuid.UUID, areaID uuid.UUID) (areadomain.Area, error) {
	if s.repo == nil {
		return areadomain.Area{}, fmt.Errorf("area.Service.Get: repository unavailable")
	}
	area, err := s.repo.FindByID(ctx, areaID)
	if err != nil {
		return areadomain.Area{}, fmt.Errorf("area.Service.Get: repo.FindByID: %w", err)
	}
	if !area.OwnedBy(userID) {
		return areadomain.Area{}, fmt.Errorf("area.Service.Get: not owner")
	}
	areas, err := s.populateComponents(ctx, []areadomain.Area{area})
	if err != nil {
		return areadomain.Area{}, err
	}
	if len(areas) == 0 {
		return areadomain.Area{}, fmt.Errorf("area.Service.Get: area missing after enrichment")
	}
	return areas[0], nil
}

func (s *Service) populateComponents(ctx context.Context, areas []areadomain.Area) ([]areadomain.Area, error) {
	if s.components == nil {
		return areas, nil
	}

	ids := make(map[uuid.UUID]struct{})
	for _, area := range areas {
		if area.Action != nil {
			if area.Action.Config.Component != nil {
				continue
			}
			if area.Action.Config.ComponentID == uuid.Nil {
				continue
			}
			ids[area.Action.Config.ComponentID] = struct{}{}
		}
	}
	if len(ids) == 0 {
		return areas, nil
	}

	idList := make([]uuid.UUID, 0, len(ids))
	for id := range ids {
		idList = append(idList, id)
	}

	components, err := s.components.FindByIDs(ctx, idList)
	if err != nil {
		return nil, fmt.Errorf("area.Service.populateComponents: components.FindByIDs: %w", err)
	}

	for i := range areas {
		action := areas[i].Action
		if action == nil {
			continue
		}
		if action.Config.Component != nil {
			continue
		}
		component, ok := components[action.Config.ComponentID]
		if ok {
			action.Config.Component = &component
		}
	}
	return areas, nil
}

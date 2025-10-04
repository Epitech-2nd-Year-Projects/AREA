package area

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"
	"unicode/utf8"

	areadomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/area"
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
	repo  outbound.AreaRepository
	clock Clock
}

// Validation errors returned by the service
var (
	ErrNameRequired       = errors.New("area: name required")
	ErrNameTooLong        = errors.New("area: name exceeds limit")
	ErrDescriptionTooLong = errors.New("area: description exceeds limit")
)

const (
	nameMaxLength        = 128
	descriptionMaxLength = 512
)

// NewService builds a Service bound to the provided repository
func NewService(repo outbound.AreaRepository, clock Clock) *Service {
	if clock == nil {
		clock = systemClock{}
	}
	return &Service{repo: repo, clock: clock}
}

// Create registers a new automation owned by the given user
func (s *Service) Create(ctx context.Context, userID uuid.UUID, name string, description string) (areadomain.Area, error) {
	if s.repo == nil {
		return areadomain.Area{}, fmt.Errorf("area.Service.Create: repository unavailable")
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

	stored, err := s.repo.Create(ctx, area)
	if err != nil {
		return areadomain.Area{}, fmt.Errorf("area.Service.Create: repo.Create: %w", err)
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
	return areas, nil
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
	return area, nil
}

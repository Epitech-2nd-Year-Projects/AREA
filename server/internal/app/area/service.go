package area

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"
	"unicode/utf8"

	areadomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/area"
	componentdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/component"
	subscriptiondomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/subscription"
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
	repo          outbound.AreaRepository
	components    outbound.ComponentRepository
	subscriptions outbound.SubscriptionRepository
	sources       outbound.ActionSourceRepository
	pipeline      ExecutionPipeline
	clock         Clock
	provisioner   ActionProvisioner
}

// Validation errors returned by the service
var (
	ErrNameRequired                = errors.New("area: name required")
	ErrNameTooLong                 = errors.New("area: name exceeds limit")
	ErrDescriptionTooLong          = errors.New("area: description exceeds limit")
	ErrActionComponentRequired     = errors.New("area: action component required")
	ErrActionComponentInvalid      = errors.New("area: action component invalid")
	ErrActionComponentDisabled     = errors.New("area: action component disabled")
	ErrReactionsRequired           = errors.New("area: at least one reaction required")
	ErrReactionComponentInvalid    = errors.New("area: reaction component invalid")
	ErrReactionComponentDisabled   = errors.New("area: reaction component disabled")
	ErrAreaNotOwned                = errors.New("area: not owner")
	ErrAreaMisconfigured           = errors.New("area: misconfigured")
	ErrProviderSubscriptionMissing = errors.New("area: provider subscription missing")
	ErrComponentParamsInvalid      = errors.New("area: component params invalid")
)

const (
	nameMaxLength        = 128
	descriptionMaxLength = 512
)

// ActionProvisioner configures action-specific infrastructure once an AREA is stored
type ActionProvisioner interface {
	Provision(ctx context.Context, area areadomain.Area) error
}

// NewService builds a Service bound to the provided repository
func NewService(repo outbound.AreaRepository, components outbound.ComponentRepository, subscriptions outbound.SubscriptionRepository, sources outbound.ActionSourceRepository, pipeline ExecutionPipeline, clock Clock, provisioner ActionProvisioner) *Service {
	if clock == nil {
		clock = systemClock{}
	}
	return &Service{
		repo:          repo,
		components:    components,
		subscriptions: subscriptions,
		sources:       sources,
		pipeline:      pipeline,
		clock:         clock,
		provisioner:   provisioner,
	}
}

// ActionInput carries action configuration used when creating an AREA
type ActionInput struct {
	ComponentID uuid.UUID
	Name        string
	Params      map[string]any
}

// ReactionInput carries reaction configuration used when creating an AREA
type ReactionInput struct {
	ComponentID uuid.UUID
	Name        string
	Params      map[string]any
}

// ExecutionOptions control how an AREA execution is enqueued
type ExecutionOptions struct {
	SourceID    uuid.UUID
	Payload     map[string]any
	Fingerprint string
	OccurredAt  time.Time
}

// Create registers a new automation owned by the given user
func (s *Service) Create(ctx context.Context, userID uuid.UUID, name string, description string, action ActionInput, reactions []ReactionInput) (areadomain.Area, error) {
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
	if err := s.ensureProviderSubscription(ctx, userID, component.ProviderID); err != nil {
		return areadomain.Area{}, fmt.Errorf("area.Service.Create: ensure action subscription: %w", err)
	}

	if len(reactions) == 0 {
		return areadomain.Area{}, fmt.Errorf("area.Service.Create: %w", ErrReactionsRequired)
	}

	reactionIDs := make([]uuid.UUID, 0, len(reactions))
	for _, reaction := range reactions {
		if reaction.ComponentID == uuid.Nil {
			return areadomain.Area{}, fmt.Errorf("area.Service.Create: %w", ErrReactionComponentInvalid)
		}
		reactionIDs = append(reactionIDs, reaction.ComponentID)
	}

	reactionComponents, err := s.components.FindByIDs(ctx, reactionIDs)
	if err != nil {
		return areadomain.Area{}, fmt.Errorf("area.Service.Create: components.FindByIDs: %w", err)
	}
	reactionModels := make([]componentdomain.Component, 0, len(reactions))
	for _, input := range reactions {
		component, ok := reactionComponents[input.ComponentID]
		if !ok {
			return areadomain.Area{}, fmt.Errorf("area.Service.Create: %w", ErrReactionComponentInvalid)
		}
		if component.Kind != componentdomain.KindReaction {
			return areadomain.Area{}, fmt.Errorf("area.Service.Create: %w", ErrReactionComponentInvalid)
		}
		if !component.Enabled {
			return areadomain.Area{}, fmt.Errorf("area.Service.Create: %w", ErrReactionComponentDisabled)
		}
		if err := s.ensureProviderSubscription(ctx, userID, component.ProviderID); err != nil {
			return areadomain.Area{}, fmt.Errorf("area.Service.Create: ensure reaction subscription: %w", err)
		}
		reactionModels = append(reactionModels, component)
	}

	params := action.Params
	if params == nil {
		params = map[string]any{}
	}
	if err := s.validateComponentParams(component, params); err != nil {
		return areadomain.Area{}, fmt.Errorf("area.Service.Create: %w", err)
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
		CreatedAt:   now,
		UpdatedAt:   now,
	}

	link := areadomain.Link{
		Role:      areadomain.LinkRoleAction,
		Position:  1,
		Config:    config,
		CreatedAt: now,
		UpdatedAt: now,
	}

	reactionLinks := make([]areadomain.Link, 0, len(reactions))
	for idx, input := range reactions {
		params := input.Params
		if params == nil {
			params = map[string]any{}
		}
		component := reactionModels[idx]
		if err := s.validateComponentParams(component, params); err != nil {
			return areadomain.Area{}, fmt.Errorf("area.Service.Create: %w", err)
		}
		reactionConfig := componentdomain.Config{
			UserID:      userID,
			ComponentID: component.ID,
			Name:        strings.TrimSpace(input.Name),
			Params:      params,
			Active:      true,
			CreatedAt:   now,
			UpdatedAt:   now,
		}
		reactionLink := areadomain.Link{
			Role:      areadomain.LinkRoleReaction,
			Position:  idx + 1,
			Config:    reactionConfig,
			CreatedAt: now,
			UpdatedAt: now,
		}
		reactionLinks = append(reactionLinks, reactionLink)
	}

	stored, err := s.repo.Create(ctx, area, link, reactionLinks)
	if err != nil {
		return areadomain.Area{}, fmt.Errorf("area.Service.Create: repo.Create: %w", err)
	}
	if stored.Action != nil {
		stored.Action.Config.Component = &component
	}
	for i := range stored.Reactions {
		for _, reaction := range reactionModels {
			if stored.Reactions[i].Config.ComponentID == reaction.ID {
				reactionCopy := reaction
				stored.Reactions[i].Config.Component = &reactionCopy
				break
			}
		}
	}

	if s.provisioner != nil {
		if err := s.provisioner.Provision(ctx, stored); err != nil {
			if cleanupErr := s.repo.Delete(ctx, stored.ID); cleanupErr != nil {
				return areadomain.Area{}, fmt.Errorf("area.Service.Create: provision: %w (cleanup failed: %v)", err, cleanupErr)
			}
			return areadomain.Area{}, fmt.Errorf("area.Service.Create: provision: %w", err)
		}
	}
	return stored, nil
}

// Execute enqueues jobs for the specified area owned by the user
func (s *Service) Execute(ctx context.Context, userID uuid.UUID, areaID uuid.UUID) error {
	return s.ExecuteWithOptions(ctx, userID, areaID, ExecutionOptions{})
}

// ExecuteWithOptions enqueues jobs for the specified area, allowing source overrides
func (s *Service) ExecuteWithOptions(ctx context.Context, userID uuid.UUID, areaID uuid.UUID, opts ExecutionOptions) error {
	if s.repo == nil {
		return fmt.Errorf("area.Service.Execute: repository unavailable")
	}
	if s.pipeline == nil {
		return fmt.Errorf("area.Service.Execute: pipeline unavailable")
	}

	area, err := s.repo.FindByID(ctx, areaID)
	if err != nil {
		return fmt.Errorf("area.Service.Execute: repo.FindByID: %w", err)
	}
	if !area.OwnedBy(userID) {
		return fmt.Errorf("area.Service.Execute: %w", ErrAreaNotOwned)
	}
	if area.Action == nil || len(area.Reactions) == 0 {
		return fmt.Errorf("area.Service.Execute: %w", ErrAreaMisconfigured)
	}

	enriched, err := s.populateComponents(ctx, []areadomain.Area{area})
	if err != nil {
		return err
	}
	if len(enriched) == 0 {
		return fmt.Errorf("area.Service.Execute: area enrichment failed")
	}
	area = enriched[0]

	sourceID := opts.SourceID
	if sourceID == uuid.Nil {
		sourceID, err = s.resolveSourceID(ctx, area)
		if err != nil {
			return fmt.Errorf("area.Service.Execute: resolve source: %w", err)
		}
	}

	payload := opts.Payload
	if payload == nil {
		payload = map[string]any{}
	}

	err = s.pipeline.Enqueue(ctx, ExecutionInput{
		Area:        area,
		SourceID:    sourceID,
		Payload:     payload,
		Fingerprint: opts.Fingerprint,
		OccurredAt:  opts.OccurredAt,
	})
	if err != nil {
		return fmt.Errorf("area.Service.Execute: enqueue pipeline: %w", err)
	}
	return nil
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
			if area.Action.Config.Component == nil && area.Action.Config.ComponentID != uuid.Nil {
				ids[area.Action.Config.ComponentID] = struct{}{}
			}
		}
		for _, reaction := range area.Reactions {
			if reaction.Config.Component == nil && reaction.Config.ComponentID != uuid.Nil {
				ids[reaction.Config.ComponentID] = struct{}{}
			}
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
		if action := areas[i].Action; action != nil && action.Config.Component == nil {
			if component, ok := components[action.Config.ComponentID]; ok {
				componentCopy := component
				action.Config.Component = &componentCopy
			}
		}
		for j := range areas[i].Reactions {
			reaction := &areas[i].Reactions[j]
			if reaction.Config.Component != nil {
				continue
			}
			if component, ok := components[reaction.Config.ComponentID]; ok {
				componentCopy := component
				reaction.Config.Component = &componentCopy
			}
		}
	}
	return areas, nil
}

func (s *Service) resolveSourceID(ctx context.Context, area areadomain.Area) (uuid.UUID, error) {
	if s.sources == nil {
		return uuid.Nil, fmt.Errorf("area.Service.resolveSourceID: source repository unavailable")
	}
	if area.Action == nil || area.Action.Config.ID == uuid.Nil {
		return uuid.Nil, fmt.Errorf("area.Service.resolveSourceID: action config missing")
	}

	source, err := s.sources.FindByComponentConfig(ctx, area.Action.Config.ID)
	if err != nil {
		return uuid.Nil, err
	}
	return source.ID, nil
}

func (s *Service) ensureProviderSubscription(ctx context.Context, userID uuid.UUID, providerID uuid.UUID) error {
	if s.subscriptions == nil {
		return fmt.Errorf("area.Service.ensureProviderSubscription: subscriptions repository unavailable")
	}
	if providerID == uuid.Nil {
		return fmt.Errorf("area.Service.ensureProviderSubscription: provider id missing")
	}
	subscription, err := s.subscriptions.FindByUserAndProvider(ctx, userID, providerID)
	if err != nil {
		if errors.Is(err, outbound.ErrNotFound) {
			return ErrProviderSubscriptionMissing
		}
		return fmt.Errorf("area.Service.ensureProviderSubscription: subscriptions.FindByUserAndProvider: %w", err)
	}
	if subscription.Status != subscriptiondomain.StatusActive {
		return ErrProviderSubscriptionMissing
	}
	return nil
}

func (s *Service) validateComponentParams(component componentdomain.Component, params map[string]any) error {
	if err := validateParamsAgainstMetadata(component.Metadata, params); err != nil {
		return fmt.Errorf("%w: %v", ErrComponentParamsInvalid, err)
	}
	return nil
}

type parameterSpec struct {
	Key      string
	Type     string
	Required bool
	Options  []string
	Minimum  *float64
	Maximum  *float64
}

func validateParamsAgainstMetadata(metadata map[string]any, params map[string]any) error {
	specs, err := extractParameterSpecs(metadata)
	if err != nil {
		return err
	}
	for _, spec := range specs {
		value, present := params[spec.Key]
		if !present {
			if spec.Required {
				return fmt.Errorf("missing required parameter %q", spec.Key)
			}
			continue
		}
		if err := spec.validate(value); err != nil {
			return fmt.Errorf("parameter %q invalid: %w", spec.Key, err)
		}
	}
	return nil
}

func extractParameterSpecs(metadata map[string]any) ([]parameterSpec, error) {
	if len(metadata) == 0 {
		return nil, nil
	}
	raw, ok := metadata["parameters"]
	if !ok {
		return nil, nil
	}
	items, ok := raw.([]any)
	if !ok {
		return nil, fmt.Errorf("metadata parameters malformed")
	}
	specs := make([]parameterSpec, 0, len(items))
	for _, item := range items {
		obj, ok := item.(map[string]any)
		if !ok {
			continue
		}
		spec := parameterSpec{}
		if key, ok := obj["key"].(string); ok {
			spec.Key = strings.TrimSpace(key)
		}
		if spec.Key == "" {
			continue
		}
		if typ, ok := obj["type"].(string); ok {
			spec.Type = strings.ToLower(strings.TrimSpace(typ))
		}
		if required, ok := obj["required"].(bool); ok {
			spec.Required = required
		}
		if options, ok := obj["options"].([]any); ok {
			spec.Options = parseOptionValues(options)
		}
		if min, ok := numberValue(obj["minimum"]); ok {
			spec.Minimum = &min
		}
		if max, ok := numberValue(obj["maximum"]); ok {
			spec.Maximum = &max
		}
		specs = append(specs, spec)
	}
	return specs, nil
}

func parseOptionValues(options []any) []string {
	values := make([]string, 0, len(options))
	for _, option := range options {
		switch v := option.(type) {
		case string:
			values = append(values, strings.TrimSpace(v))
		case map[string]any:
			if raw, ok := v["value"].(string); ok {
				values = append(values, strings.TrimSpace(raw))
			}
		}
	}
	return values
}

func numberValue(value any) (float64, bool) {
	switch v := value.(type) {
	case float64:
		return v, true
	case float32:
		return float64(v), true
	case int:
		return float64(v), true
	case int64:
		return float64(v), true
	case json.Number:
		if f, err := v.Float64(); err == nil {
			return f, true
		}
	}
	return 0, false
}

func (spec parameterSpec) validate(value any) error {
	switch spec.Type {
	case "integer":
		val, ok := numberValue(value)
		if !ok || val != float64(int64(val)) {
			return fmt.Errorf("expected integer")
		}
		if spec.Minimum != nil && val < *spec.Minimum {
			return fmt.Errorf("must be >= %.0f", *spec.Minimum)
		}
		if spec.Maximum != nil && val > *spec.Maximum {
			return fmt.Errorf("must be <= %.0f", *spec.Maximum)
		}
	case "number":
		if _, ok := numberValue(value); !ok {
			return fmt.Errorf("expected number")
		}
	case "boolean":
		if _, ok := value.(bool); !ok {
			return fmt.Errorf("expected boolean")
		}
	case "array", "emaillist":
		if !isArrayValue(value) && !isStringValue(value) {
			return fmt.Errorf("expected array")
		}
		if strings.EqualFold(spec.Type, "emaillist") && isArrayValue(value) {
			if err := ensureArrayElementsString(value); err != nil {
				return err
			}
		}
	case "enum":
		str, ok := toStringValue(value)
		if !ok {
			return fmt.Errorf("expected string")
		}
		if len(spec.Options) > 0 && !containsString(spec.Options, str) {
			return fmt.Errorf("invalid option")
		}
	default:
		if !isStringValue(value) {
			return fmt.Errorf("expected string")
		}
	}
	return nil
}

func isArrayValue(value any) bool {
	switch value.(type) {
	case []any, []string:
		return true
	default:
		return false
	}
}

func ensureArrayElementsString(value any) error {
	switch items := value.(type) {
	case []any:
		for _, item := range items {
			if _, ok := item.(string); !ok {
				return fmt.Errorf("expected array of strings")
			}
		}
	case []string:
		return nil
	default:
		return fmt.Errorf("expected array of strings")
	}
	return nil
}

func isStringValue(value any) bool {
	_, ok := value.(string)
	return ok
}

func toStringValue(value any) (string, bool) {
	switch v := value.(type) {
	case string:
		return strings.TrimSpace(v), true
	default:
		return "", false
	}
}

func containsString(items []string, target string) bool {
	for _, item := range items {
		if strings.EqualFold(item, target) {
			return true
		}
	}
	return false
}

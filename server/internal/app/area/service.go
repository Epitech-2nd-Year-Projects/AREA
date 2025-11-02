package area

import (
	"context"
	"crypto/subtle"
	"encoding/json"
	"errors"
	"fmt"
	"reflect"
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
	ErrWebhookNotFound             = errors.New("area: webhook source not found")
	ErrWebhookSecretMissing        = errors.New("area: webhook secret missing")
	ErrWebhookSecretInvalid        = errors.New("area: webhook secret invalid")
	ErrAreaUpdateNoChanges         = errors.New("area: no changes detected")
	ErrAreaConfigNotFound          = errors.New("area: component config not found")
	ErrAreaStatusInvalid           = errors.New("area: invalid status")
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

// UpdateAreaCommand carries optional fields that can be patched on an automation
type UpdateAreaCommand struct {
	Name           *string
	Description    *string
	DescriptionSet bool
	Action         *UpdateActionCommand
	Reactions      []UpdateReactionCommand
}

// UpdateActionCommand encapsulates updates applied to the action configuration
type UpdateActionCommand struct {
	ConfigID  uuid.UUID
	Name      *string
	NameSet   bool
	Params    map[string]any
	ParamsSet bool
}

// UpdateReactionCommand encapsulates updates applied to a reaction configuration
type UpdateReactionCommand struct {
	ConfigID  uuid.UUID
	Name      *string
	NameSet   bool
	Params    map[string]any
	ParamsSet bool
}

// DuplicateOptions customises the duplication of an existing automation
type DuplicateOptions struct {
	Name        *string
	Description *string
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

// ProcessWebhook ingests a webhook event for the specified path and secret
func (s *Service) ProcessWebhook(ctx context.Context, path string, secret string, payload map[string]any, fingerprint string, occurredAt time.Time) error {
	if s.sources == nil {
		return fmt.Errorf("area.Service.ProcessWebhook: source repository unavailable")
	}

	cleanPath := strings.Trim(strings.TrimSpace(path), "/")
	if cleanPath == "" {
		return fmt.Errorf("area.Service.ProcessWebhook: path missing")
	}

	binding, err := s.sources.FindWebhookBindingByPath(ctx, cleanPath)
	if err != nil {
		if errors.Is(err, outbound.ErrNotFound) {
			return ErrWebhookNotFound
		}
		return fmt.Errorf("area.Service.ProcessWebhook: sources.FindWebhookBindingByPath: %w", err)
	}

	expected := ""
	if binding.Source.WebhookSecret != nil {
		expected = strings.TrimSpace(*binding.Source.WebhookSecret)
	}
	incoming := strings.TrimSpace(secret)
	if incoming == "" {
		return ErrWebhookSecretMissing
	}
	if expected == "" || subtle.ConstantTimeCompare([]byte(expected), []byte(incoming)) != 1 {
		return ErrWebhookSecretInvalid
	}

	if payload == nil {
		payload = map[string]any{}
	}

	eventTime := occurredAt.UTC()
	if eventTime.IsZero() {
		eventTime = s.clock.Now().UTC()
	}
	if fingerprint == "" {
		fingerprint = uuid.NewString()
	}

	options := ExecutionOptions{
		SourceID:    binding.Source.ID,
		Payload:     payload,
		Fingerprint: fingerprint,
		OccurredAt:  eventTime,
	}
	if err := s.ExecuteWithOptions(ctx, binding.UserID, binding.AreaID, options); err != nil {
		return fmt.Errorf("area.Service.ProcessWebhook: execute: %w", err)
	}

	cursor := map[string]any{
		"last_received": s.clock.Now().UTC().Format(time.RFC3339Nano),
	}
	if fingerprint != "" {
		cursor["last_fingerprint"] = fingerprint
	}
	_ = s.sources.UpdateWebhookCursor(ctx, binding.Source.ID, binding.Source.ComponentConfigID, cursor)

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
		return areadomain.Area{}, fmt.Errorf("area.Service.Get: %w", ErrAreaNotOwned)
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

// Update applies partial modifications to an automation ensuring ownership
func (s *Service) Update(ctx context.Context, userID uuid.UUID, areaID uuid.UUID, cmd UpdateAreaCommand) (areadomain.Area, error) {
	if s.repo == nil {
		return areadomain.Area{}, fmt.Errorf("area.Service.Update: repository unavailable")
	}
	area, err := s.repo.FindByID(ctx, areaID)
	if err != nil {
		return areadomain.Area{}, fmt.Errorf("area.Service.Update: repo.FindByID: %w", err)
	}
	if !area.OwnedBy(userID) {
		return areadomain.Area{}, fmt.Errorf("area.Service.Update: %w", ErrAreaNotOwned)
	}

	enriched, err := s.populateComponents(ctx, []areadomain.Area{area})
	if err != nil {
		return areadomain.Area{}, fmt.Errorf("area.Service.Update: populateComponents: %w", err)
	}
	if len(enriched) == 0 {
		return areadomain.Area{}, fmt.Errorf("area.Service.Update: enrichment failed")
	}
	area = enriched[0]
	updated := cloneArea(area)

	now := s.clock.Now().UTC()
	metadataChanged := false
	configChanges := make([]componentdomain.Config, 0)

	if cmd.Name != nil {
		name := strings.TrimSpace(*cmd.Name)
		if name == "" {
			return areadomain.Area{}, fmt.Errorf("area.Service.Update: %w", ErrNameRequired)
		}
		if utf8.RuneCountInString(name) > nameMaxLength {
			return areadomain.Area{}, fmt.Errorf("area.Service.Update: %w", ErrNameTooLong)
		}
		if name != area.Name {
			updated.Name = name
			metadataChanged = true
		}
	}

	if cmd.DescriptionSet {
		description, err := normalizeDescription(cmd.Description)
		if err != nil {
			return areadomain.Area{}, fmt.Errorf("area.Service.Update: %w", err)
		}
		if !stringPointersEqual(area.Description, description) {
			updated.Description = description
			metadataChanged = true
		}
	}

	if cmd.Action != nil {
		if updated.Action == nil || updated.Action.Config.ID == uuid.Nil {
			return areadomain.Area{}, fmt.Errorf("area.Service.Update: %w", ErrAreaMisconfigured)
		}
		if cmd.Action.ConfigID == uuid.Nil || cmd.Action.ConfigID != updated.Action.Config.ID {
			return areadomain.Area{}, fmt.Errorf("area.Service.Update: %w", ErrAreaConfigNotFound)
		}
		actionConfig := updated.Action.Config
		configChanged := false

		if cmd.Action.NameSet {
			name := ""
			if cmd.Action.Name != nil {
				name = strings.TrimSpace(*cmd.Action.Name)
				if utf8.RuneCountInString(name) > nameMaxLength {
					return areadomain.Area{}, fmt.Errorf("area.Service.Update: %w", ErrNameTooLong)
				}
			}
			if strings.TrimSpace(actionConfig.Name) != name {
				actionConfig.Name = name
				configChanged = true
			}
		}

		if cmd.Action.ParamsSet {
			params := cloneParamsMap(cmd.Action.Params)
			if actionConfig.Component == nil {
				return areadomain.Area{}, fmt.Errorf("area.Service.Update: action component missing")
			}
			if err := s.validateComponentParams(*actionConfig.Component, params); err != nil {
				return areadomain.Area{}, fmt.Errorf("area.Service.Update: %w", err)
			}
			if !mapsEqual(actionConfig.Params, params) {
				actionConfig.Params = params
				configChanged = true
			}
		}

		if configChanged {
			actionConfig.UpdatedAt = now
			updated.Action.Config = actionConfig
			configChanges = append(configChanges, actionConfig)
		}
	}

	if len(cmd.Reactions) > 0 {
		reactionByConfig := make(map[uuid.UUID]*areadomain.Link, len(updated.Reactions))
		for i := range updated.Reactions {
			reaction := &updated.Reactions[i]
			if reaction.Config.ID != uuid.Nil {
				reactionByConfig[reaction.Config.ID] = reaction
			}
		}

		for _, patch := range cmd.Reactions {
			reaction, ok := reactionByConfig[patch.ConfigID]
			if !ok {
				return areadomain.Area{}, fmt.Errorf("area.Service.Update: %w", ErrAreaConfigNotFound)
			}
			reactionConfig := reaction.Config
			configChanged := false

			if patch.NameSet {
				name := ""
				if patch.Name != nil {
					name = strings.TrimSpace(*patch.Name)
					if utf8.RuneCountInString(name) > nameMaxLength {
						return areadomain.Area{}, fmt.Errorf("area.Service.Update: %w", ErrNameTooLong)
					}
				}
				if strings.TrimSpace(reactionConfig.Name) != name {
					reactionConfig.Name = name
					configChanged = true
				}
			}

			if patch.ParamsSet {
				params := cloneParamsMap(patch.Params)
				if reactionConfig.Component == nil {
					return areadomain.Area{}, fmt.Errorf("area.Service.Update: reaction component missing")
				}
				if err := s.validateComponentParams(*reactionConfig.Component, params); err != nil {
					return areadomain.Area{}, fmt.Errorf("area.Service.Update: %w", err)
				}
				if !mapsEqual(reactionConfig.Params, params) {
					reactionConfig.Params = params
					configChanged = true
				}
			}

			if configChanged {
				reactionConfig.UpdatedAt = now
				reaction.Config = reactionConfig
				configChanges = append(configChanges, reactionConfig)
			}
		}
	}

	if !metadataChanged && len(configChanges) == 0 {
		return areadomain.Area{}, fmt.Errorf("area.Service.Update: %w", ErrAreaUpdateNoChanges)
	}

	updated.UpdatedAt = now
	if metadataChanged || len(configChanges) > 0 {
		updated.Status = area.Status
		if err := s.repo.UpdateMetadata(ctx, updated); err != nil {
			return areadomain.Area{}, fmt.Errorf("area.Service.Update: repo.UpdateMetadata: %w", err)
		}
	}

	for _, cfg := range configChanges {
		if err := s.repo.UpdateConfig(ctx, cfg); err != nil {
			return areadomain.Area{}, fmt.Errorf("area.Service.Update: repo.UpdateConfig: %w", err)
		}
	}

	result, err := s.populateComponents(ctx, []areadomain.Area{updated})
	if err != nil {
		return areadomain.Area{}, fmt.Errorf("area.Service.Update: populateComponents: %w", err)
	}
	if len(result) == 0 {
		return areadomain.Area{}, fmt.Errorf("area.Service.Update: enrichment failed")
	}
	return result[0], nil
}

// UpdateStatus toggles the lifecycle status of an automation
func (s *Service) UpdateStatus(ctx context.Context, userID uuid.UUID, areaID uuid.UUID, status areadomain.Status) (areadomain.Area, error) {
	if s.repo == nil {
		return areadomain.Area{}, fmt.Errorf("area.Service.UpdateStatus: repository unavailable")
	}
	if status != areadomain.StatusEnabled && status != areadomain.StatusDisabled && status != areadomain.StatusArchived {
		return areadomain.Area{}, fmt.Errorf("area.Service.UpdateStatus: %w", ErrAreaStatusInvalid)
	}

	area, err := s.repo.FindByID(ctx, areaID)
	if err != nil {
		return areadomain.Area{}, fmt.Errorf("area.Service.UpdateStatus: repo.FindByID: %w", err)
	}
	if !area.OwnedBy(userID) {
		return areadomain.Area{}, fmt.Errorf("area.Service.UpdateStatus: %w", ErrAreaNotOwned)
	}

	if area.Status == status {
		return s.Get(ctx, userID, areaID)
	}

	area.Status = status
	area.UpdatedAt = s.clock.Now().UTC()
	if err := s.repo.UpdateMetadata(ctx, area); err != nil {
		return areadomain.Area{}, fmt.Errorf("area.Service.UpdateStatus: repo.UpdateMetadata: %w", err)
	}
	return s.Get(ctx, userID, areaID)
}

// Duplicate clones an existing automation and persists it for the same user
func (s *Service) Duplicate(ctx context.Context, userID uuid.UUID, areaID uuid.UUID, opts DuplicateOptions) (areadomain.Area, error) {
	if s.repo == nil {
		return areadomain.Area{}, fmt.Errorf("area.Service.Duplicate: repository unavailable")
	}
	area, err := s.repo.FindByID(ctx, areaID)
	if err != nil {
		return areadomain.Area{}, fmt.Errorf("area.Service.Duplicate: repo.FindByID: %w", err)
	}
	if !area.OwnedBy(userID) {
		return areadomain.Area{}, fmt.Errorf("area.Service.Duplicate: %w", ErrAreaNotOwned)
	}

	enriched, err := s.populateComponents(ctx, []areadomain.Area{area})
	if err != nil {
		return areadomain.Area{}, fmt.Errorf("area.Service.Duplicate: populateComponents: %w", err)
	}
	if len(enriched) == 0 {
		return areadomain.Area{}, fmt.Errorf("area.Service.Duplicate: enrichment failed")
	}
	area = enriched[0]

	name := area.Name
	if opts.Name != nil {
		value := strings.TrimSpace(*opts.Name)
		if value == "" {
			return areadomain.Area{}, fmt.Errorf("area.Service.Duplicate: %w", ErrNameRequired)
		}
		if utf8.RuneCountInString(value) > nameMaxLength {
			return areadomain.Area{}, fmt.Errorf("area.Service.Duplicate: %w", ErrNameTooLong)
		}
		name = value
	} else {
		name = generateDuplicateName(area.Name)
	}

	desc := ""
	if opts.Description != nil {
		desc = strings.TrimSpace(*opts.Description)
	} else if area.Description != nil {
		desc = strings.TrimSpace(*area.Description)
	}

	if area.Action == nil || area.Action.Config.ComponentID == uuid.Nil {
		return areadomain.Area{}, fmt.Errorf("area.Service.Duplicate: %w", ErrAreaMisconfigured)
	}

	actionInput := ActionInput{
		ComponentID: area.Action.Config.ComponentID,
		Name:        strings.TrimSpace(area.Action.Config.Name),
		Params:      cloneParamsMap(area.Action.Config.Params),
	}

	reactionInputs := make([]ReactionInput, 0, len(area.Reactions))
	for _, reaction := range area.Reactions {
		reactionInputs = append(reactionInputs, ReactionInput{
			ComponentID: reaction.Config.ComponentID,
			Name:        strings.TrimSpace(reaction.Config.Name),
			Params:      cloneParamsMap(reaction.Config.Params),
		})
	}

	duplicate, err := s.Create(ctx, userID, name, desc, actionInput, reactionInputs)
	if err != nil {
		return areadomain.Area{}, fmt.Errorf("area.Service.Duplicate: create: %w", err)
	}

	if area.Status != areadomain.StatusEnabled {
		duplicate.Status = area.Status
		duplicate.UpdatedAt = s.clock.Now().UTC()
		if err := s.repo.UpdateMetadata(ctx, duplicate); err != nil {
			return areadomain.Area{}, fmt.Errorf("area.Service.Duplicate: repo.UpdateMetadata: %w", err)
		}
	}

	return duplicate, nil
}

// Delete removes an automation owned by the given user
func (s *Service) Delete(ctx context.Context, userID uuid.UUID, areaID uuid.UUID) error {
	if s.repo == nil {
		return fmt.Errorf("area.Service.Delete: repository unavailable")
	}

	area, err := s.repo.FindByID(ctx, areaID)
	if err != nil {
		return fmt.Errorf("area.Service.Delete: repo.FindByID: %w", err)
	}
	if !area.OwnedBy(userID) {
		return fmt.Errorf("area.Service.Delete: %w", ErrAreaNotOwned)
	}

	if err := s.repo.Delete(ctx, areaID); err != nil {
		return fmt.Errorf("area.Service.Delete: repo.Delete: %w", err)
	}
	return nil
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

func cloneArea(area areadomain.Area) areadomain.Area {
	clone := area
	if area.Action != nil {
		actionCopy := *area.Action
		actionCopy.Config = cloneConfig(area.Action.Config)
		clone.Action = &actionCopy
	}
	if len(area.Reactions) > 0 {
		clone.Reactions = make([]areadomain.Link, len(area.Reactions))
		for i, reaction := range area.Reactions {
			clone.Reactions[i] = cloneLink(reaction)
		}
	}
	return clone
}

func cloneLink(link areadomain.Link) areadomain.Link {
	copy := link
	copy.Config = cloneConfig(link.Config)
	return copy
}

func cloneConfig(cfg componentdomain.Config) componentdomain.Config {
	copy := cfg
	if cfg.Component != nil {
		componentCopy := *cfg.Component
		copy.Component = &componentCopy
	}
	copy.Params = cloneParamsMap(cfg.Params)
	return copy
}

func cloneParamsMap(source map[string]any) map[string]any {
	if len(source) == 0 {
		return map[string]any{}
	}
	clone := make(map[string]any, len(source))
	for key, value := range source {
		clone[key] = value
	}
	return clone
}

func stringPointersEqual(a *string, b *string) bool {
	switch {
	case a == nil && b == nil:
		return true
	case a == nil || b == nil:
		return false
	default:
		return *a == *b
	}
}

func normalizeDescription(value *string) (*string, error) {
	if value == nil {
		return nil, nil
	}
	trimmed := strings.TrimSpace(*value)
	if trimmed == "" {
		return nil, nil
	}
	if utf8.RuneCountInString(trimmed) > descriptionMaxLength {
		return nil, ErrDescriptionTooLong
	}
	desc := trimmed
	return &desc, nil
}

func generateDuplicateName(base string) string {
	trimmed := strings.TrimSpace(base)
	if trimmed == "" {
		trimmed = "Automation"
	}
	suffix := " (copy)"
	total := trimmed + suffix
	if utf8.RuneCountInString(total) <= nameMaxLength {
		return total
	}
	maxBase := nameMaxLength - utf8.RuneCountInString(suffix)
	if maxBase <= 0 {
		runes := []rune(suffix)
		if len(runes) > nameMaxLength {
			return string(runes[:nameMaxLength])
		}
		return suffix
	}
	runes := []rune(trimmed)
	if len(runes) > maxBase {
		runes = runes[:maxBase]
	}
	return string(runes) + suffix
}

func mapsEqual(a map[string]any, b map[string]any) bool {
	if len(a) == 0 && len(b) == 0 {
		return true
	}
	return reflect.DeepEqual(a, b)
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

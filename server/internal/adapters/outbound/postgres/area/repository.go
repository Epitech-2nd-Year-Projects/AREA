package area

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	areadomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/area"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Repository persists AREA entities using Postgres via GORM
type Repository struct {
	db *gorm.DB
}

// NewRepository constructs a Repository backed by the provided gorm handle
func NewRepository(db *gorm.DB) Repository {
	return Repository{db: db}
}

// Create inserts a new area row and returns the stored aggregate
func (r Repository) Create(ctx context.Context, area areadomain.Area, action areadomain.Link, reactions []areadomain.Link) (areadomain.Area, error) {
	if r.db == nil {
		return areadomain.Area{}, fmt.Errorf("postgres.area.Repository.Create: nil db handle")
	}
	if !action.IsAction() {
		return areadomain.Area{}, fmt.Errorf("postgres.area.Repository.Create: expected action link")
	}
	for _, reaction := range reactions {
		if reaction.Role != areadomain.LinkRoleReaction {
			return areadomain.Area{}, fmt.Errorf("postgres.area.Repository.Create: invalid reaction role")
		}
	}

	tx := r.db.WithContext(ctx).Begin()
	if err := tx.Error; err != nil {
		return areadomain.Area{}, fmt.Errorf("postgres.area.Repository.Create: begin tx: %w", err)
	}
	rollback := func(err error) (areadomain.Area, error) {
		_ = tx.Rollback()
		return areadomain.Area{}, err
	}

	model := areaFromDomain(area)
	if model.ID == uuid.Nil {
		model.ID = uuid.New()
	}
	if model.CreatedAt.IsZero() {
		model.CreatedAt = time.Now().UTC()
	}
	if model.UpdatedAt.IsZero() {
		model.UpdatedAt = model.CreatedAt
	}

	if err := tx.Create(&model).Error; err != nil {
		if isUniqueViolation(err) {
			return rollback(outbound.ErrConflict)
		}
		return rollback(fmt.Errorf("postgres.area.Repository.Create: create area: %w", err))
	}

	configModel, err := configFromDomain(action.Config)
	if err != nil {
		return rollback(fmt.Errorf("postgres.area.Repository.Create: encode config: %w", err))
	}
	if configModel.UserID == uuid.Nil {
		configModel.UserID = model.UserID
	}
	if configModel.ID == uuid.Nil {
		configModel.ID = uuid.New()
	}
	if configModel.CreatedAt.IsZero() {
		configModel.CreatedAt = model.CreatedAt
	} else {
		configModel.CreatedAt = configModel.CreatedAt.UTC()
	}
	if configModel.UpdatedAt.IsZero() {
		configModel.UpdatedAt = model.UpdatedAt
	} else {
		configModel.UpdatedAt = configModel.UpdatedAt.UTC()
	}

	if err := tx.Create(&configModel).Error; err != nil {
		return rollback(fmt.Errorf("postgres.area.Repository.Create: create config: %w", err))
	}

	linkModel := linkFromDomain(action)
	if linkModel.ID == uuid.Nil {
		linkModel.ID = uuid.New()
	}
	linkModel.AreaID = model.ID
	linkModel.ComponentConfigID = configModel.ID
	if linkModel.Position == 0 {
		linkModel.Position = 1
	}
	if linkModel.CreatedAt.IsZero() {
		linkModel.CreatedAt = model.CreatedAt
	} else {
		linkModel.CreatedAt = linkModel.CreatedAt.UTC()
	}
	if linkModel.UpdatedAt.IsZero() {
		linkModel.UpdatedAt = model.UpdatedAt
	} else {
		linkModel.UpdatedAt = linkModel.UpdatedAt.UTC()
	}

	if err := tx.Create(&linkModel).Error; err != nil {
		return rollback(fmt.Errorf("postgres.area.Repository.Create: create link: %w", err))
	}

	reactionModels := make([]areaLinkModel, 0, len(reactions))
	for idx := range reactions {
		reaction := reactions[idx]
		configModel, err := configFromDomain(reaction.Config)
		if err != nil {
			return rollback(fmt.Errorf("postgres.area.Repository.Create: encode reaction config: %w", err))
		}
		if configModel.UserID == uuid.Nil {
			configModel.UserID = model.UserID
		}
		if configModel.ID == uuid.Nil {
			configModel.ID = uuid.New()
		}
		if configModel.CreatedAt.IsZero() {
			configModel.CreatedAt = model.CreatedAt
		} else {
			configModel.CreatedAt = configModel.CreatedAt.UTC()
		}
		if configModel.UpdatedAt.IsZero() {
			configModel.UpdatedAt = model.UpdatedAt
		} else {
			configModel.UpdatedAt = configModel.UpdatedAt.UTC()
		}

		if err := tx.Create(&configModel).Error; err != nil {
			return rollback(fmt.Errorf("postgres.area.Repository.Create: create reaction config: %w", err))
		}

		linkModel := linkFromDomain(reaction)
		if linkModel.ID == uuid.Nil {
			linkModel.ID = uuid.New()
		}
		linkModel.AreaID = model.ID
		linkModel.ComponentConfigID = configModel.ID
		if linkModel.Position == 0 {
			linkModel.Position = idx + 1
		}
		if linkModel.CreatedAt.IsZero() {
			linkModel.CreatedAt = model.CreatedAt
		} else {
			linkModel.CreatedAt = linkModel.CreatedAt.UTC()
		}
		if linkModel.UpdatedAt.IsZero() {
			linkModel.UpdatedAt = model.UpdatedAt
		} else {
			linkModel.UpdatedAt = linkModel.UpdatedAt.UTC()
		}
		linkModel.ComponentConfig = configModel

		if err := tx.Create(&linkModel).Error; err != nil {
			return rollback(fmt.Errorf("postgres.area.Repository.Create: create reaction link: %w", err))
		}
		reactionModels = append(reactionModels, linkModel)
	}

	if err := tx.Commit().Error; err != nil {
		return areadomain.Area{}, fmt.Errorf("postgres.area.Repository.Create: commit: %w", err)
	}

	// hydrate response
	linkModel.ComponentConfig = configModel
	stored := model.toDomain()
	linkModel.AreaID = stored.ID
	actionDomain, err := linkModel.toDomain()
	if err == nil {
		stored.Action = &actionDomain
	}
	for _, reactionModel := range reactionModels {
		reactionModel.AreaID = stored.ID
		reactionDomain, err := reactionModel.toDomain()
		if err != nil {
			continue
		}
		stored.Reactions = append(stored.Reactions, reactionDomain)
	}
	return stored, nil
}

// FindByID retrieves an area by its identifier
func (r Repository) FindByID(ctx context.Context, id uuid.UUID) (areadomain.Area, error) {
	if r.db == nil {
		return areadomain.Area{}, fmt.Errorf("postgres.area.Repository.FindByID: nil db handle")
	}
	var model areaModel
	if err := r.db.WithContext(ctx).
		Preload("Links", func(db *gorm.DB) *gorm.DB {
			return db.Order("position ASC")
		}).
		Preload("Links.ComponentConfig").
		First(&model, "id = ?", id).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return areadomain.Area{}, outbound.ErrNotFound
		}
		return areadomain.Area{}, fmt.Errorf("postgres.area.Repository.FindByID: %w", err)
	}
	return model.toDomain(), nil
}

// ListByUser returns all areas for the specified user ordered by creation date descending
func (r Repository) ListByUser(ctx context.Context, userID uuid.UUID) ([]areadomain.Area, error) {
	if r.db == nil {
		return nil, fmt.Errorf("postgres.area.Repository.ListByUser: nil db handle")
	}
	var models []areaModel
	if err := r.db.WithContext(ctx).
		Preload("Links", func(db *gorm.DB) *gorm.DB {
			return db.Order("position ASC")
		}).
		Preload("Links.ComponentConfig").
		Where("user_id = ?", userID).
		Order("created_at DESC").
		Find(&models).Error; err != nil {
		return nil, fmt.Errorf("postgres.area.Repository.ListByUser: %w", err)
	}
	areas := make([]areadomain.Area, 0, len(models))
	for _, model := range models {
		areas = append(areas, model.toDomain())
	}
	return areas, nil
}

func isUniqueViolation(err error) bool {
	return err != nil && strings.Contains(strings.ToLower(err.Error()), "duplicate")
}

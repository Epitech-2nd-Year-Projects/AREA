package service

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	servicedomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/service"
	subscriptiondomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/subscription"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Repository groups Postgres-backed persistence adapters for service catalog concerns.
type Repository struct {
	db *gorm.DB
}

// NewRepository constructs a Repository tied to the provided gorm handle.
func NewRepository(db *gorm.DB) Repository {
	return Repository{db: db}
}

// Providers exposes a repository for service provider lookups.
func (r Repository) Providers() outbound.ServiceProviderRepository {
	return providerRepo{db: r.db}
}

// Subscriptions exposes a repository for user service subscriptions.
func (r Repository) Subscriptions() outbound.SubscriptionRepository {
	return subscriptionRepo{db: r.db}
}

type providerRepo struct {
	db *gorm.DB
}

func (r providerRepo) FindByName(ctx context.Context, name string) (servicedomain.Provider, error) {
	if r.db == nil {
		return servicedomain.Provider{}, fmt.Errorf("postgres.service.providerRepo.FindByName: nil db handle")
	}
	trimmed := strings.TrimSpace(strings.ToLower(name))
	if trimmed == "" {
		return servicedomain.Provider{}, outbound.ErrNotFound
	}

	var model providerModel
	if err := r.db.WithContext(ctx).
		Where("lower(name) = ?", trimmed).
		Take(&model).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return servicedomain.Provider{}, outbound.ErrNotFound
		}
		return servicedomain.Provider{}, fmt.Errorf("postgres.service.providerRepo.FindByName: %w", err)
	}

	return model.toDomain(), nil
}

type subscriptionRepo struct {
	db *gorm.DB
}

func (r subscriptionRepo) Create(ctx context.Context, subscription subscriptiondomain.Subscription) (subscriptiondomain.Subscription, error) {
	if r.db == nil {
		return subscriptiondomain.Subscription{}, fmt.Errorf("postgres.service.subscriptionRepo.Create: nil db handle")
	}

	model := subscriptionFromDomain(subscription)
	if model.ID == uuid.Nil {
		model.ID = uuid.New()
	}
	if model.CreatedAt.IsZero() {
		model.CreatedAt = time.Now().UTC()
	}
	if model.UpdatedAt.IsZero() {
		model.UpdatedAt = model.CreatedAt
	}

	if err := r.db.WithContext(ctx).Create(&model).Error; err != nil {
		if isUniqueViolation(err) {
			return subscriptiondomain.Subscription{}, outbound.ErrConflict
		}
		return subscriptiondomain.Subscription{}, fmt.Errorf("postgres.service.subscriptionRepo.Create: %w", err)
	}

	return model.toDomain(), nil
}

func (r subscriptionRepo) Update(ctx context.Context, subscription subscriptiondomain.Subscription) error {
	if r.db == nil {
		return fmt.Errorf("postgres.service.subscriptionRepo.Update: nil db handle")
	}

	model := subscriptionFromDomain(subscription)
	if model.ID == uuid.Nil {
		return fmt.Errorf("postgres.service.subscriptionRepo.Update: missing id")
	}
	if model.UpdatedAt.IsZero() {
		model.UpdatedAt = time.Now().UTC()
	}

	updates := map[string]any{
		"identity_id":  model.IdentityID,
		"status":       model.Status,
		"scope_grants": model.ScopeGrants,
		"updated_at":   model.UpdatedAt,
	}

	if err := r.db.WithContext(ctx).
		Model(&subscriptionModel{}).
		Where("id = ?", model.ID).
		Updates(updates).Error; err != nil {
		return fmt.Errorf("postgres.service.subscriptionRepo.Update: %w", err)
	}
	return nil
}

func (r subscriptionRepo) FindByUserAndProvider(ctx context.Context, userID uuid.UUID, providerID uuid.UUID) (subscriptiondomain.Subscription, error) {
	if r.db == nil {
		return subscriptiondomain.Subscription{}, fmt.Errorf("postgres.service.subscriptionRepo.FindByUserAndProvider: nil db handle")
	}

	var model subscriptionModel
	if err := r.db.WithContext(ctx).
		Where("user_id = ? AND provider_id = ?", userID, providerID).
		Take(&model).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return subscriptiondomain.Subscription{}, outbound.ErrNotFound
		}
		return subscriptiondomain.Subscription{}, fmt.Errorf("postgres.service.subscriptionRepo.FindByUserAndProvider: %w", err)
	}

	return model.toDomain(), nil
}

func (r subscriptionRepo) ListByUser(ctx context.Context, userID uuid.UUID) ([]subscriptiondomain.Subscription, error) {
	if r.db == nil {
		return nil, fmt.Errorf("postgres.service.subscriptionRepo.ListByUser: nil db handle")
	}

	var models []subscriptionModel
	if err := r.db.WithContext(ctx).
		Where("user_id = ?", userID).
		Order("created_at ASC").
		Find(&models).Error; err != nil {
		return nil, fmt.Errorf("postgres.service.subscriptionRepo.ListByUser: %w", err)
	}

	subscriptions := make([]subscriptiondomain.Subscription, 0, len(models))
	for _, model := range models {
		subscriptions = append(subscriptions, model.toDomain())
	}
	return subscriptions, nil
}

func isUniqueViolation(err error) bool {
	return err != nil && strings.Contains(strings.ToLower(err.Error()), "duplicate")
}

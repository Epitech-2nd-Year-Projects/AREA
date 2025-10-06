package service

import (
	"time"

	servicedomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/service"
	subscriptiondomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/subscription"
	"github.com/google/uuid"
	"github.com/lib/pq"
)

type providerModel struct {
	ID          uuid.UUID `gorm:"column:id;primaryKey"`
	Name        string    `gorm:"column:name"`
	DisplayName string    `gorm:"column:display_name"`
	Category    string    `gorm:"column:category"`
	OAuthType   string    `gorm:"column:oauth_type"`
	IsEnabled   bool      `gorm:"column:is_enabled"`
	CreatedAt   time.Time `gorm:"column:created_at"`
	UpdatedAt   time.Time `gorm:"column:updated_at"`
}

func (providerModel) TableName() string { return "service_providers" }

func (m providerModel) toDomain() servicedomain.Provider {
	return servicedomain.Provider{
		ID:          m.ID,
		Name:        m.Name,
		DisplayName: m.DisplayName,
		Category:    m.Category,
		OAuthType:   servicedomain.OAuthType(m.OAuthType),
		Enabled:     m.IsEnabled,
		CreatedAt:   m.CreatedAt,
		UpdatedAt:   m.UpdatedAt,
	}
}

type subscriptionModel struct {
	ID          uuid.UUID      `gorm:"column:id;primaryKey"`
	UserID      uuid.UUID      `gorm:"column:user_id"`
	ProviderID  uuid.UUID      `gorm:"column:provider_id"`
	IdentityID  *uuid.UUID     `gorm:"column:identity_id"`
	Status      string         `gorm:"column:status"`
	ScopeGrants pq.StringArray `gorm:"column:scope_grants;type:text[]"`
	CreatedAt   time.Time      `gorm:"column:created_at"`
	UpdatedAt   time.Time      `gorm:"column:updated_at"`
}

func (subscriptionModel) TableName() string { return "user_service_subscriptions" }

func (m subscriptionModel) toDomain() subscriptiondomain.Subscription {
	var identityID *uuid.UUID
	if m.IdentityID != nil {
		copyID := *m.IdentityID
		identityID = &copyID
	}
	scopeCopy := make([]string, len(m.ScopeGrants))
	copy(scopeCopy, m.ScopeGrants)

	return subscriptiondomain.Subscription{
		ID:          m.ID,
		UserID:      m.UserID,
		ProviderID:  m.ProviderID,
		IdentityID:  identityID,
		Status:      subscriptiondomain.Status(m.Status),
		ScopeGrants: scopeCopy,
		CreatedAt:   m.CreatedAt,
		UpdatedAt:   m.UpdatedAt,
	}
}

func subscriptionFromDomain(item subscriptiondomain.Subscription) subscriptionModel {
	scopes := make(pq.StringArray, len(item.ScopeGrants))
	copy(scopes, item.ScopeGrants)

	var identityID *uuid.UUID
	if item.IdentityID != nil {
		copyID := *item.IdentityID
		identityID = &copyID
	}

	status := item.Status
	if status == "" {
		status = subscriptiondomain.StatusActive
	}

	return subscriptionModel{
		ID:          item.ID,
		UserID:      item.UserID,
		ProviderID:  item.ProviderID,
		IdentityID:  identityID,
		Status:      string(status),
		ScopeGrants: scopes,
		CreatedAt:   item.CreatedAt,
		UpdatedAt:   item.UpdatedAt,
	}
}

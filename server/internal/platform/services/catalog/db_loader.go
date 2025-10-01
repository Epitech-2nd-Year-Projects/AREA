package catalog

import (
	"context"
	"fmt"

	"gorm.io/gorm"
)

// DBLoader hydrates the service catalog from the primary database
type DBLoader struct {
	DB *gorm.DB
}

// Load queries the database for enabled service providers and their components
func (l DBLoader) Load(ctx context.Context) (Catalog, error) {
	if err := ctx.Err(); err != nil {
		return Catalog{}, err
	}
	if l.DB == nil {
		return Catalog{}, fmt.Errorf("catalog.DBLoader.Load: nil gorm db")
	}

	providers, err := l.loadProviders(ctx)
	if err != nil {
		return Catalog{}, err
	}
	if len(providers) == 0 {
		return Catalog{}, nil
	}

	actionsByProvider, reactionsByProvider, err := l.loadComponents(ctx)
	if err != nil {
		return Catalog{}, err
	}

	services := make([]Service, 0, len(providers))
	for _, p := range providers {
		service := Service{
			Name:      p.Name,
			Actions:   normalizeComponents(actionsByProvider[p.ID]),
			Reactions: normalizeComponents(reactionsByProvider[p.ID]),
		}
		services = append(services, service)
	}

	return Catalog{Services: services}, nil
}

type providerRow struct {
	ID      string `gorm:"column:id;primaryKey"`
	Name    string `gorm:"column:name"`
	Enabled bool   `gorm:"column:is_enabled"`
}

func (providerRow) TableName() string { return "service_providers" }

type componentRow struct {
	ProviderID  string `gorm:"column:provider_id"`
	Kind        string `gorm:"column:kind"`
	Name        string `gorm:"column:name"`
	Description string `gorm:"column:description"`
	Enabled     bool   `gorm:"column:is_enabled"`
}

func (componentRow) TableName() string { return "service_components" }

func (l DBLoader) loadProviders(ctx context.Context) ([]providerRow, error) {
	var providers []providerRow
	if err := l.DB.WithContext(ctx).
		Where("is_enabled = ?", true).
		Order("name ASC").
		Find(&providers).Error; err != nil {
		return nil, fmt.Errorf("catalog.DBLoader.loadProviders: %w", err)
	}
	return providers, nil
}

func (l DBLoader) loadComponents(ctx context.Context) (map[string][]Component, map[string][]Component, error) {
	var rows []componentRow
	if err := l.DB.WithContext(ctx).
		Where("is_enabled = ?", true).
		Order("provider_id, kind, name").
		Find(&rows).Error; err != nil {
		return nil, nil, fmt.Errorf("catalog.DBLoader.loadComponents: %w", err)
	}

	actions := make(map[string][]Component)
	reactions := make(map[string][]Component)

	for _, row := range rows {
		component := Component{Name: row.Name, Description: row.Description}
		switch row.Kind {
		case "action":
			actions[row.ProviderID] = append(actions[row.ProviderID], component)
		case "reaction":
			reactions[row.ProviderID] = append(reactions[row.ProviderID], component)
		default:
			// ignore unsupported kinds
		}
	}

	return actions, reactions, nil
}

func normalizeComponents(components []Component) []Component {
	if len(components) == 0 {
		return make([]Component, 0)
	}
	return components
}

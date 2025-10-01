package catalog

import (
	"context"
	"fmt"
	"testing"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func TestDBLoaderLoad(t *testing.T) {
	db := newTestDB(t)

	if err := db.Create(&providerRow{ID: "provider-1", Name: "timer", Enabled: true}).Error; err != nil {
		t.Fatalf("create provider: %v", err)
	}
	rows := []componentRow{
		{ProviderID: "provider-1", Kind: "action", Name: "hourly", Description: "Hourly tick", Enabled: true},
		{ProviderID: "provider-1", Kind: "reaction", Name: "ping", Description: "Ping reaction", Enabled: true},
	}
	for _, r := range rows {
		row := r
		if err := db.Create(&row).Error; err != nil {
			t.Fatalf("create component: %v", err)
		}
	}

	loader := DBLoader{DB: db}
	catalog, err := loader.Load(context.Background())
	if err != nil {
		t.Fatalf("DBLoader.Load: %v", err)
	}

	if len(catalog.Services) != 1 {
		t.Fatalf("expected 1 service got %d", len(catalog.Services))
	}
	svc := catalog.Services[0]
	if svc.Name != "timer" {
		t.Fatalf("unexpected service name %q", svc.Name)
	}
	if len(svc.Actions) != 1 || svc.Actions[0].Name != "hourly" {
		t.Fatalf("unexpected actions %+v", svc.Actions)
	}
	if len(svc.Reactions) != 1 || svc.Reactions[0].Name != "ping" {
		t.Fatalf("unexpected reactions %+v", svc.Reactions)
	}
}

func TestDBLoaderHandlesEmpty(t *testing.T) {
	db := newTestDB(t)
	loader := DBLoader{DB: db}
	cat, err := loader.Load(context.Background())
	if err != nil {
		t.Fatalf("DBLoader.Load: %v", err)
	}
	if !cat.Empty() {
		t.Fatalf("expected empty catalog got %+v", cat)
	}
}

func TestDBLoaderNilDB(t *testing.T) {
	if _, err := (DBLoader{}).Load(context.Background()); err == nil {
		t.Fatal("expected error for nil gorm db")
	}
}

func newTestDB(t *testing.T) *gorm.DB {
	t.Helper()
	dsn := fmt.Sprintf("file:%s?mode=memory&cache=shared", t.Name())
	db, err := gorm.Open(sqlite.Open(dsn), &gorm.Config{})
	if err != nil {
		t.Fatalf("gorm.Open: %v", err)
	}

	if err := db.AutoMigrate(&providerRow{}, &componentRow{}); err != nil {
		t.Fatalf("auto migrate: %v", err)
	}

	return db
}

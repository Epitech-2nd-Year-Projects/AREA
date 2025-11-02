package execution_test

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/adapters/outbound/postgres/execution"
	jobdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/job"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
	"github.com/google/uuid"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

type jobFixture struct {
	userID        uuid.UUID
	areaID        uuid.UUID
	areaName      string
	componentName string
	providerName  string
	areaLinkID    uuid.UUID
	triggerID     uuid.UUID
	jobID         uuid.UUID
	runAt         time.Time
	createdAt     time.Time
	updatedAt     time.Time
}

func TestJobRepository_ListWithDetailsPopulatesJobMetadata(t *testing.T) {
	db, fx := prepareJobFixture(t)

	repo := execution.NewJobRepository(db)
	opts := outbound.JobListOptions{
		UserID: fx.userID,
		AreaID: fx.areaID,
		Limit:  5,
	}

	details, err := repo.ListWithDetails(context.Background(), opts)
	if err != nil {
		t.Fatalf("ListWithDetails returned error: %v", err)
	}
	if len(details) != 1 {
		t.Fatalf("expected 1 job detail, got %d", len(details))
	}

	assertJobMatchesFixture(t, details[0].Job, fx)

	if details[0].AreaID != fx.areaID {
		t.Fatalf("unexpected area id, want %s got %s", fx.areaID, details[0].AreaID)
	}
	if details[0].AreaName != fx.areaName {
		t.Fatalf("unexpected area name, got %s", details[0].AreaName)
	}
	if details[0].ComponentName != fx.componentName {
		t.Fatalf("unexpected component name, got %s", details[0].ComponentName)
	}
	if details[0].ProviderName != fx.providerName {
		t.Fatalf("unexpected provider name, got %s", details[0].ProviderName)
	}
}

func TestJobRepository_FindDetailsPopulatesJobMetadata(t *testing.T) {
	db, fx := prepareJobFixture(t)

	repo := execution.NewJobRepository(db)
	detail, err := repo.FindDetails(context.Background(), fx.userID, fx.jobID)
	if err != nil {
		t.Fatalf("FindDetails returned error: %v", err)
	}

	assertJobMatchesFixture(t, detail.Job, fx)

	if detail.AreaID != fx.areaID {
		t.Fatalf("unexpected area id, want %s got %s", fx.areaID, detail.AreaID)
	}
	if detail.AreaName != fx.areaName {
		t.Fatalf("unexpected area name, got %s", detail.AreaName)
	}
	if detail.ComponentName != fx.componentName {
		t.Fatalf("unexpected component name, got %s", detail.ComponentName)
	}
	if detail.ProviderName != fx.providerName {
		t.Fatalf("unexpected provider name, got %s", detail.ProviderName)
	}
}

func assertJobMatchesFixture(t *testing.T, job jobdomain.Job, fx jobFixture) {
	t.Helper()

	if job.ID != fx.jobID {
		t.Fatalf("unexpected job id, want %s got %s", fx.jobID, job.ID)
	}
	if job.TriggerID != fx.triggerID {
		t.Fatalf("unexpected trigger id, want %s got %s", fx.triggerID, job.TriggerID)
	}
	if job.AreaLinkID != fx.areaLinkID {
		t.Fatalf("unexpected area link id, want %s got %s", fx.areaLinkID, job.AreaLinkID)
	}
	if string(job.Status) != "queued" {
		t.Fatalf("unexpected status, got %s", job.Status)
	}
	if job.Attempt != 1 {
		t.Fatalf("unexpected attempt, want 1 got %d", job.Attempt)
	}
	if !job.RunAt.Equal(fx.runAt) {
		t.Fatalf("unexpected runAt, want %s got %s", fx.runAt.Format(time.RFC3339Nano), job.RunAt.Format(time.RFC3339Nano))
	}
	if !job.CreatedAt.Equal(fx.createdAt) {
		t.Fatalf("unexpected createdAt, want %s got %s", fx.createdAt.Format(time.RFC3339Nano), job.CreatedAt.Format(time.RFC3339Nano))
	}
	if !job.UpdatedAt.Equal(fx.updatedAt) {
		t.Fatalf("unexpected updatedAt, want %s got %s", fx.updatedAt.Format(time.RFC3339Nano), job.UpdatedAt.Format(time.RFC3339Nano))
	}
	if got := fmt.Sprint(job.ResultPayload); got != "map[result:payload]" {
		t.Fatalf("unexpected result payload, got %v", job.ResultPayload)
	}
	if job.Error != nil {
		t.Fatalf("unexpected error value, got %v", *job.Error)
	}
}

func prepareJobFixture(t *testing.T) (*gorm.DB, jobFixture) {
	t.Helper()

	db := openTestDB(t)
	schema := []string{
		`CREATE TABLE areas (
			id TEXT PRIMARY KEY,
			user_id TEXT NOT NULL,
			name TEXT NOT NULL
		);`,
		`CREATE TABLE area_links (
			id TEXT PRIMARY KEY,
			area_id TEXT NOT NULL,
			component_config_id TEXT NOT NULL
		);`,
		`CREATE TABLE user_component_configs (
			id TEXT PRIMARY KEY,
			component_id TEXT NOT NULL
		);`,
		`CREATE TABLE service_components (
			id TEXT PRIMARY KEY,
			provider_id TEXT NOT NULL,
			display_name TEXT NOT NULL
		);`,
		`CREATE TABLE service_providers (
			id TEXT PRIMARY KEY,
			display_name TEXT NOT NULL
		);`,
		`CREATE TABLE jobs (
			id TEXT PRIMARY KEY,
			trigger_id TEXT NOT NULL,
			area_link_id TEXT NOT NULL,
			status TEXT NOT NULL,
			attempt INTEGER NOT NULL,
			run_at DATETIME NOT NULL,
			locked_by TEXT,
			locked_at DATETIME,
			input_payload TEXT,
			result_payload TEXT,
			error TEXT,
			created_at DATETIME NOT NULL,
			updated_at DATETIME NOT NULL
		);`,
	}

	for _, stmt := range schema {
		if err := db.Exec(stmt).Error; err != nil {
			t.Fatalf("failed to apply schema: %v", err)
		}
	}

	fixture := jobFixture{
		userID:        uuid.New(),
		areaID:        uuid.New(),
		areaName:      "Test AREA",
		componentName: "Component",
		providerName:  "Provider",
		areaLinkID:    uuid.New(),
		triggerID:     uuid.New(),
		jobID:         uuid.New(),
		runAt:         time.Date(2024, 6, 1, 12, 0, 30, 0, time.UTC),
		createdAt:     time.Date(2024, 6, 1, 12, 0, 0, 0, time.UTC),
		updatedAt:     time.Date(2024, 6, 1, 12, 1, 0, 0, time.UTC),
	}

	componentID := uuid.New()
	providerID := uuid.New()
	configID := uuid.New()

	inserts := []struct {
		query string
		args  []any
	}{
		{
			query: `INSERT INTO areas (id, user_id, name) VALUES (?, ?, ?)`,
			args:  []any{fixture.areaID.String(), fixture.userID.String(), fixture.areaName},
		},
		{
			query: `INSERT INTO service_providers (id, display_name) VALUES (?, ?)`,
			args:  []any{providerID.String(), fixture.providerName},
		},
		{
			query: `INSERT INTO service_components (id, provider_id, display_name) VALUES (?, ?, ?)`,
			args:  []any{componentID.String(), providerID.String(), fixture.componentName},
		},
		{
			query: `INSERT INTO user_component_configs (id, component_id) VALUES (?, ?)`,
			args:  []any{configID.String(), componentID.String()},
		},
		{
			query: `INSERT INTO area_links (id, area_id, component_config_id) VALUES (?, ?, ?)`,
			args:  []any{fixture.areaLinkID.String(), fixture.areaID.String(), configID.String()},
		},
		{
			query: `INSERT INTO jobs (
				id, trigger_id, area_link_id, status, attempt, run_at,
				locked_by, locked_at, input_payload, result_payload, error,
				created_at, updated_at
			) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
			args: []any{
				fixture.jobID.String(),
				fixture.triggerID.String(),
				fixture.areaLinkID.String(),
				"queued",
				1,
				fixture.runAt,
				nil,
				nil,
				`{"input":"payload"}`,
				`{"result":"payload"}`,
				nil,
				fixture.createdAt,
				fixture.updatedAt,
			},
		},
	}

	for _, insert := range inserts {
		if err := db.Exec(insert.query, insert.args...).Error; err != nil {
			t.Fatalf("failed to insert fixture data: %v", err)
		}
	}

	return db, fixture
}

func openTestDB(t *testing.T) *gorm.DB {
	t.Helper()

	dsn := fmt.Sprintf("file:%s?mode=memory&cache=shared&_loc=UTC", uuid.NewString())
	db, err := gorm.Open(sqlite.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Silent),
	})
	if err != nil {
		t.Fatalf("failed to open sqlite db: %v", err)
	}

	return db
}

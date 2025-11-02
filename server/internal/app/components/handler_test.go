package components

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/adapters/inbound/http/openapi"
	componentdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/component"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type handlerStubComponentRepo struct {
	items []componentdomain.Component
}

func (s *handlerStubComponentRepo) FindByID(_ context.Context, _ uuid.UUID) (componentdomain.Component, error) {
	return componentdomain.Component{}, outbound.ErrNotFound
}

func (s *handlerStubComponentRepo) FindByIDs(_ context.Context, _ []uuid.UUID) (map[uuid.UUID]componentdomain.Component, error) {
	return map[uuid.UUID]componentdomain.Component{}, nil
}

func (s *handlerStubComponentRepo) List(_ context.Context, _ outbound.ComponentListOptions) ([]componentdomain.Component, error) {
	return append([]componentdomain.Component(nil), s.items...), nil
}

func TestListComponentsWithoutSession(t *testing.T) {
	gin.SetMode(gin.TestMode)

	repo := &handlerStubComponentRepo{items: []componentdomain.Component{
		{
			ID:          uuid.New(),
			Name:        "timer_interval",
			DisplayName: "Recurring timer",
			Kind:        componentdomain.KindAction,
			Provider: componentdomain.Provider{
				ID:          uuid.New(),
				Name:        "scheduler",
				DisplayName: "Scheduler",
			},
			Enabled: true,
		},
	}}
	service := NewService(repo, nil)
	handler := NewHandler(service, nil, CookieConfig{})

	rec := httptest.NewRecorder()
	ctx, _ := gin.CreateTestContext(rec)
	ctx.Request = httptest.NewRequest(http.MethodGet, "/v1/components", nil)

	handler.ListComponents(ctx, openapi.ListComponentsParams{})

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status %d got %d", http.StatusOK, rec.Code)
	}

	var resp openapi.ComponentListResponse
	if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
		t.Fatalf("json.Unmarshal: %v", err)
	}

	if len(resp.Components) != 1 {
		t.Fatalf("expected 1 component got %d", len(resp.Components))
	}
	if resp.Components[0].Name != "timer_interval" {
		t.Fatalf("unexpected component name %s", resp.Components[0].Name)
	}
}

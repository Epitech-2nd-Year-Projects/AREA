package about

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	openapi "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/adapters/inbound/http/openapi"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/platform/services/catalog"
	"github.com/gin-gonic/gin"
)

type fixedClock struct {
	t time.Time
}

func (c fixedClock) Now() time.Time { return c.t }

type stubLoader struct {
	cat catalog.Catalog
	err error
}

func (s stubLoader) Load(ctx context.Context) (catalog.Catalog, error) {
	return s.cat, s.err
}

func TestHandler(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := gin.New()

	handler := New(stubLoader{cat: catalog.Catalog{
		Services: []catalog.Service{
			{
				Name: "timer",
				Actions: []catalog.Component{
					{Name: "hourly", Description: "Fires every hour"},
				},
				Reactions: []catalog.Component{
					{Name: "ping", Description: "Sends ping"},
				},
			},
		},
	}}, fixedClock{t: time.Unix(1700000000, 0)})

	handler.Register(router)

	req := httptest.NewRequest(http.MethodGet, "/about.json", nil)
	req.RemoteAddr = "10.0.0.1:1234"
	rec := httptest.NewRecorder()

	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status %d got %d", http.StatusOK, rec.Code)
	}

	var resp openapi.AboutResponse
	if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
		t.Fatalf("json.Unmarshal: %v", err)
	}

	if resp.Client.Host == nil || *resp.Client.Host != "10.0.0.1" {
		t.Fatalf("expected client host 10.0.0.1 got %v", resp.Client.Host)
	}
	if resp.Server.CurrentTime != 1700000000 {
		t.Fatalf("unexpected current time %d", resp.Server.CurrentTime)
	}
	if len(resp.Server.Services) != 1 {
		t.Fatalf("expected 1 service got %d", len(resp.Server.Services))
	}
	if resp.Server.Services[0].Name != "timer" {
		t.Fatalf("unexpected service %s", resp.Server.Services[0].Name)
	}
}

func TestHandlerDatabaseError(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := gin.New()

	handler := New(stubLoader{err: assertiveError{}}, fixedClock{t: time.Unix(1700000000, 0)})
	handler.Register(router)

	req := httptest.NewRequest(http.MethodGet, "/about.json", nil)
	rec := httptest.NewRecorder()

	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Fatalf("expected status %d got %d", http.StatusInternalServerError, rec.Code)
	}
}

type assertiveError struct{}

func (assertiveError) Error() string { return "boom" }

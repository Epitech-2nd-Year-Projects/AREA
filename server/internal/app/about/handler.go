package about

import (
	"net/http"
	"time"

	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/adapters/inbound/http/openapi"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/platform/services/catalog"
	"github.com/gin-gonic/gin"
)

// Clock abstracts time retrieval for testability
type Clock interface {
	Now() time.Time
}

// SystemClock implements Clock using the standard library
type SystemClock struct{}

// Now returns the current time
func (SystemClock) Now() time.Time {
	return time.Now()
}

// Handler serves the about.json payload
type Handler struct {
	loader catalog.Loader
	clock  Clock
}

// New constructs a Handler from the provided loader and clock
func New(loader catalog.Loader, clock Clock) *Handler {
	if loader == nil {
		loader = catalog.EmptyLoader{}
	}
	if clock == nil {
		clock = SystemClock{}
	}
	return &Handler{loader: loader, clock: clock}
}

// Register installs the about route on the provided Gin router
func (h *Handler) Register(r gin.IRouter) {
	r.GET("/about.json", h.GetAbout)
}

// GetAbout handles the OpenAPI getAbout operation
func (h *Handler) GetAbout(c *gin.Context) {
	cat, err := h.loader.Load(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to load service catalog"})
		return
	}

	response := openapi.AboutResponse{
		Client: openapi.AboutClient{Host: c.ClientIP()},
		Server: openapi.AboutServer{
			CurrentTime: h.now().Unix(),
			Services:    mapServices(cat.Services),
		},
	}

	c.JSON(http.StatusOK, response)
}

func (h *Handler) now() time.Time {
	if h.clock == nil {
		return time.Now()
	}
	return h.clock.Now()
}

func mapServices(services []catalog.Service) []openapi.AboutService {
	if len(services) == 0 {
		return make([]openapi.AboutService, 0)
	}

	result := make([]openapi.AboutService, 0, len(services))
	for _, svc := range services {
		result = append(result, openapi.AboutService{
			Name:      svc.Name,
			Actions:   mapComponents(svc.Actions),
			Reactions: mapComponents(svc.Reactions),
		})
	}
	return result
}

func mapComponents(components []catalog.Component) []openapi.AboutComponent {
	if len(components) == 0 {
		return make([]openapi.AboutComponent, 0)
	}
	mapped := make([]openapi.AboutComponent, 0, len(components))
	for _, cmp := range components {
		mapped = append(mapped, openapi.AboutComponent{
			Name:        cmp.Name,
			Description: cmp.Description,
		})
	}
	return mapped
}

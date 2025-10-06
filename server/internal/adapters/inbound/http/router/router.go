package router

import (
	"net/http"

	openapi "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/adapters/inbound/http/openapi"
	aboutapp "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/app/about"
	areaapp "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/app/area"
	authapp "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/app/auth"
	componentapp "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/app/components"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/platform/services/catalog"
	"github.com/gin-gonic/gin"
	openapi_types "github.com/oapi-codegen/runtime/types"
)

// Dependencies aggregates inbound HTTP dependencies
type Dependencies struct {
	AboutLoader      catalog.Loader
	Clock            aboutapp.Clock
	AuthHandler      *authapp.Handler
	AreaHandler      *areaapp.Handler
	ComponentHandler *componentapp.Handler
}

// Register mounts all HTTP endpoints on the provided router
func Register(r gin.IRouter, deps Dependencies) error {
	if deps.AboutLoader == nil {
		deps.AboutLoader = catalog.EmptyLoader{}
	}
	if deps.Clock == nil {
		deps.Clock = aboutapp.SystemClock{}
	}

	handler := compositeHandler{
		about:      aboutapp.New(deps.AboutLoader, deps.Clock),
		auth:       deps.AuthHandler,
		area:       deps.AreaHandler,
		components: deps.ComponentHandler,
	}

	openapi.RegisterHandlers(r, handler)
	if deps.AuthHandler != nil {
		r.GET("/v1/auth/verify", deps.AuthHandler.VerifyEmail)
	}

	return nil
}

type compositeHandler struct {
	about      *aboutapp.Handler
	auth       *authapp.Handler
	area       *areaapp.Handler
	components *componentapp.Handler
}

func (h compositeHandler) GetAbout(c *gin.Context) {
	if h.about == nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "about handler missing"})
		return
	}
	h.about.GetAbout(c)
}

func (h compositeHandler) RegisterUser(c *gin.Context) {
	if h.auth == nil {
		c.JSON(http.StatusNotImplemented, gin.H{"error": "auth handler missing"})
		return
	}
	h.auth.RegisterUser(c)
}

func (h compositeHandler) ListAreas(c *gin.Context) {
	if h.area == nil {
		c.JSON(http.StatusNotImplemented, gin.H{"error": "area handler missing"})
		return
	}
	h.area.ListAreas(c)
}

func (h compositeHandler) ListComponents(c *gin.Context, params openapi.ListComponentsParams) {
	if h.components == nil {
		c.JSON(http.StatusNotImplemented, gin.H{"error": "component handler missing"})
		return
	}
	h.components.ListComponents(c, params)
}

func (h compositeHandler) CreateArea(c *gin.Context) {
	if h.area == nil {
		c.JSON(http.StatusNotImplemented, gin.H{"error": "area handler missing"})
		return
	}
	h.area.CreateArea(c)
}

func (h compositeHandler) VerifyEmail(c *gin.Context) {
	if h.auth == nil {
		c.JSON(http.StatusNotImplemented, gin.H{"error": "auth handler missing"})
		return
	}
	h.auth.VerifyEmail(c)
}

func (h compositeHandler) Login(c *gin.Context) {
	if h.auth == nil {
		c.JSON(http.StatusNotImplemented, gin.H{"error": "auth handler missing"})
		return
	}
	h.auth.Login(c)
}

func (h compositeHandler) Logout(c *gin.Context) {
	if h.auth == nil {
		c.Status(http.StatusNoContent)
		return
	}
	h.auth.Logout(c)
}

func (h compositeHandler) GetCurrentUser(c *gin.Context) {
	if h.auth == nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "auth handler missing"})
		return
	}
	h.auth.GetCurrentUser(c)
}

func (h compositeHandler) ListIdentities(c *gin.Context) {
	if h.auth == nil {
		c.JSON(http.StatusNotImplemented, gin.H{"error": "auth handler missing"})
		return
	}
	h.auth.ListIdentities(c)
}

func (h compositeHandler) AuthorizeOAuth(c *gin.Context, provider string) {
	if h.auth == nil {
		c.JSON(http.StatusNotImplemented, gin.H{"error": "auth handler missing"})
		return
	}
	h.auth.AuthorizeOAuth(c, provider)
}

func (h compositeHandler) ExchangeOAuth(c *gin.Context, provider string) {
	if h.auth == nil {
		c.JSON(http.StatusNotImplemented, gin.H{"error": "auth handler missing"})
		return
	}
	h.auth.ExchangeOAuth(c, provider)
}

func (h compositeHandler) ExecuteArea(c *gin.Context, areaId openapi_types.UUID) {
	if h.area == nil {
		c.JSON(http.StatusNotImplemented, gin.H{"error": "area handler missing"})
		return
	}
	h.area.ExecuteArea(c, areaId)
}

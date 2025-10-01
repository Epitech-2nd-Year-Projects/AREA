package router

import (
	"net/http"

	openapi "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/adapters/inbound/http/openapi"
	aboutapp "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/app/about"
	authapp "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/app/auth"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/platform/services/catalog"
	"github.com/gin-gonic/gin"
)

// Dependencies aggregates inbound HTTP dependencies
type Dependencies struct {
	AboutLoader catalog.Loader
	Clock       aboutapp.Clock
	AuthHandler *authapp.Handler
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
		about: aboutapp.New(deps.AboutLoader, deps.Clock),
		auth:  deps.AuthHandler,
	}

	openapi.RegisterHandlers(r, handler)
	if deps.AuthHandler != nil {
		r.GET("/v1/auth/verify", deps.AuthHandler.VerifyEmail)
	}

	return nil
}

type compositeHandler struct {
	about *aboutapp.Handler
	auth  *authapp.Handler
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

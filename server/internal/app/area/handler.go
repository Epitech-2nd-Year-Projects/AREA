package area

import (
	"context"
	"errors"
	"net/http"
	"strings"
	"time"

	openapi "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/adapters/inbound/http/openapi"
	areaauth "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/app/auth"
	areadomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/area"
	sessiondomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/session"
	userdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/user"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	openapi_types "github.com/oapi-codegen/runtime/types"
)

// CookieConfig replicates the session cookie directives enforced at the edge
type CookieConfig struct {
	Name     string
	Domain   string
	Path     string
	Secure   bool
	HTTPOnly bool
	SameSite http.SameSite
}

// SessionResolver resolves a session identifier into the authenticated user
type SessionResolver interface {
	ResolveSession(ctx context.Context, sessionID uuid.UUID) (userdomain.User, sessiondomain.Session, error)
}

// Handler exposes HTTP endpoints matching the area OpenAPI contract
type Handler struct {
	service  *Service
	sessions SessionResolver
	cookies  CookieConfig
}

// NewHandler assembles an area HTTP handler
func NewHandler(service *Service, sessions SessionResolver, cookies CookieConfig) *Handler {
	if cookies.Path == "" {
		cookies.Path = "/"
	}
	if cookies.Name == "" {
		cookies.Name = "area_session"
	}
	return &Handler{service: service, sessions: sessions, cookies: cookies}
}

// ListAreas handles GET /v1/areas
func (h *Handler) ListAreas(c *gin.Context) {
	usr, _, ok := h.authorize(c)
	if !ok {
		return
	}

	items, err := h.service.List(c.Request.Context(), usr.ID)
	if err != nil {
		h.handleServiceError(c, err)
		return
	}

	response := openapi.ListAreasResponse{Areas: mapAreas(items)}
	c.JSON(http.StatusOK, response)
}

// CreateArea handles POST /v1/areas
func (h *Handler) CreateArea(c *gin.Context) {
	usr, _, ok := h.authorize(c)
	if !ok {
		return
	}

	var payload openapi.CreateAreaRequest
	if err := c.ShouldBindJSON(&payload); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request payload"})
		return
	}
	name := strings.TrimSpace(payload.Name)
	if name == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "name is required"})
		return
	}

	desc := ""
	if payload.Description != nil {
		desc = strings.TrimSpace(*payload.Description)
	}

	created, err := h.service.Create(c.Request.Context(), usr.ID, name, desc)
	if err != nil {
		h.handleServiceError(c, err)
		return
	}

	c.JSON(http.StatusCreated, toOpenAPIArea(created))
}

func (h *Handler) authorize(c *gin.Context) (userdomain.User, sessiondomain.Session, bool) {
	value, err := c.Cookie(h.cookies.Name)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "session missing"})
		return userdomain.User{}, sessiondomain.Session{}, false
	}
	value = strings.TrimSpace(value)
	sessionID, err := uuid.Parse(value)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "session invalid"})
		return userdomain.User{}, sessiondomain.Session{}, false
	}

	usr, sess, err := h.sessions.ResolveSession(c.Request.Context(), sessionID)
	if err != nil {
		h.handleSessionError(c, err)
		return userdomain.User{}, sessiondomain.Session{}, false
	}
	h.refreshSessionCookie(c, sess)
	return usr, sess, true
}

func (h *Handler) refreshSessionCookie(c *gin.Context, sess sessiondomain.Session) {
	maxAge := int(time.Until(sess.ExpiresAt).Seconds())
	if maxAge <= 0 {
		maxAge = 0
	}
	c.SetSameSite(h.cookies.SameSite)
	c.SetCookie(h.cookies.Name, sess.ID.String(), maxAge, h.cookies.Path, h.cookies.Domain, h.cookies.Secure, h.cookies.HTTPOnly)
}

func (h *Handler) handleServiceError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, ErrNameRequired), errors.Is(err, ErrNameTooLong), errors.Is(err, ErrDescriptionTooLong):
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid area payload"})
	case errors.Is(err, outbound.ErrConflict):
		c.JSON(http.StatusConflict, gin.H{"error": "area conflict"})
	case errors.Is(err, outbound.ErrNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": "area not found"})
	default:
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal error"})
	}
}

func (h *Handler) handleSessionError(c *gin.Context, err error) {
	switch {
	case err == nil:
		c.JSON(http.StatusUnauthorized, gin.H{"error": "session invalid"})
	case errors.Is(err, areaauth.ErrSessionNotFound):
		c.JSON(http.StatusUnauthorized, gin.H{"error": "session invalid"})
	case errors.Is(err, areaauth.ErrAccountNotVerified):
		c.JSON(http.StatusForbidden, gin.H{"error": "account not verified"})
	default:
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to resolve session"})
	}
}

func mapAreas(items []areadomain.Area) []openapi.Area {
	if len(items) == 0 {
		return make([]openapi.Area, 0)
	}
	result := make([]openapi.Area, 0, len(items))
	for _, item := range items {
		result = append(result, toOpenAPIArea(item))
	}
	return result
}

func toOpenAPIArea(area areadomain.Area) openapi.Area {
	return openapi.Area{
		Id:          openapi_types.UUID(area.ID),
		Name:        area.Name,
		Description: area.Description,
		Status:      string(area.Status),
		CreatedAt:   area.CreatedAt,
		UpdatedAt:   area.UpdatedAt,
	}
}

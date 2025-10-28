package components

import (
	"context"
	"errors"
	"net/http"
	"strings"
	"time"

	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/adapters/inbound/http/openapi"
	areaauth "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/app/auth"
	sessiondomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/session"
	userdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/user"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// CookieConfig mirrors the session cookie settings enforced by the authentication layer
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

// Handler exposes component catalog endpoints generated from the OpenAPI contract
type Handler struct {
	service  *Service
	sessions SessionResolver
	cookies  CookieConfig
}

// NewHandler constructs a component handler instance
func NewHandler(service *Service, sessions SessionResolver, cookies CookieConfig) *Handler {
	if cookies.Path == "" {
		cookies.Path = "/"
	}
	if cookies.Name == "" {
		cookies.Name = "area_session"
	}
	return &Handler{service: service, sessions: sessions, cookies: cookies}
}

// ListComponents handles GET /v1/components
func (h *Handler) ListComponents(c *gin.Context, params openapi.ListComponentsParams) {
	if h.service == nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "catalog unavailable"})
		return
	}

	_, _, ok := h.authorize(c)
	if !ok {
		return
	}

	opts := ListOptions{}
	if params.Kind != nil {
		kind := string(*params.Kind)
		opts.Kind = kind
	}
	if params.Provider != nil {
		opts.Provider = *params.Provider
	}

	items, err := h.service.List(c.Request.Context(), opts)
	if err != nil {
		switch {
		case errors.Is(err, ErrInvalidKind):
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid component kind"})
		default:
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to list components"})
		}
		return
	}

	response := openapi.ComponentListResponse{Components: MapComponents(items)}
	c.JSON(http.StatusOK, response)
}

// ListAvailableComponents handles GET /v1/components/available
func (h *Handler) ListAvailableComponents(c *gin.Context, params openapi.ListAvailableComponentsParams) {
	if h.service == nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "catalog unavailable"})
		return
	}

	usr, _, ok := h.authorize(c)
	if !ok {
		return
	}

	opts := ListOptions{}
	if params.Kind != nil {
		opts.Kind = string(*params.Kind)
	}
	if params.Provider != nil {
		opts.Provider = *params.Provider
	}

	items, err := h.service.ListAvailable(c.Request.Context(), usr.ID, opts)
	if err != nil {
		switch {
		case errors.Is(err, ErrInvalidKind):
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid component kind"})
		default:
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to list components"})
		}
		return
	}

	response := openapi.ComponentListResponse{Components: MapComponents(items)}
	c.JSON(http.StatusOK, response)
}

func (h *Handler) authorize(c *gin.Context) (userdomain.User, sessiondomain.Session, bool) {
	if h.sessions == nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "session resolver unavailable"})
		return userdomain.User{}, sessiondomain.Session{}, false
	}

	value, err := c.Cookie(h.cookies.Name)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "session missing"})
		return userdomain.User{}, sessiondomain.Session{}, false
	}
	sessionID, err := uuid.Parse(strings.TrimSpace(value))
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

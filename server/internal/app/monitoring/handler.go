package monitoring

import (
	"context"
	"errors"
	"net/http"
	"strconv"
	"strings"
	"time"

	areaauth "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/app/auth"
	sessiondomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/session"
	userdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/user"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// SessionResolver resolves session identifiers into authenticated users
type SessionResolver interface {
	ResolveSession(ctx context.Context, sessionID uuid.UUID) (userdomain.User, sessiondomain.Session, error)
}

// CookieConfig mirrors the session cookie settings enforced by authentication
type CookieConfig struct {
	Name     string
	Domain   string
	Path     string
	Secure   bool
	HTTPOnly bool
	SameSite http.SameSite
}

// Handler exposes monitoring endpoints over HTTP
type Handler struct {
	service  *Service
	sessions SessionResolver
	cookies  CookieConfig
}

// NewHandler constructs a monitoring handler
func NewHandler(service *Service, sessions SessionResolver, cookies CookieConfig) *Handler {
	if cookies.Path == "" {
		cookies.Path = "/"
	}
	if cookies.Name == "" {
		cookies.Name = "area_session"
	}
	return &Handler{service: service, sessions: sessions, cookies: cookies}
}

// ListJobs handles GET /v1/monitoring/jobs
func (h *Handler) ListJobs(c *gin.Context) {
	user, _, ok := h.authorize(c)
	if !ok {
		return
	}

	opts := ListJobsOptions{UserID: user.ID}

	if areaIDQuery := strings.TrimSpace(c.Query("area_id")); areaIDQuery != "" {
		areaID, err := uuid.Parse(areaIDQuery)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid area_id"})
			return
		}
		opts.AreaID = &areaID
	}

	if status := strings.TrimSpace(c.Query("status")); status != "" {
		opts.Status = status
	}

	if limitQuery := strings.TrimSpace(c.Query("limit")); limitQuery != "" {
		limit, err := strconv.Atoi(limitQuery)
		if err != nil || limit <= 0 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid limit"})
			return
		}
		opts.Limit = limit
	}

	jobs, err := h.service.ListJobs(c.Request.Context(), opts)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"jobs": jobs})
}

// ListJobLogs handles GET /v1/monitoring/jobs/:jobId/logs
func (h *Handler) ListJobLogs(c *gin.Context) {
	user, _, ok := h.authorize(c)
	if !ok {
		return
	}

	jobID, err := uuid.Parse(c.Param("jobId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid job id"})
		return
	}

	limit := 50
	if limitQuery := strings.TrimSpace(c.Query("limit")); limitQuery != "" {
		value, convErr := strconv.Atoi(limitQuery)
		if convErr != nil || value <= 0 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid limit"})
			return
		}
		limit = value
	}

	logs, err := h.service.ListJobLogs(c.Request.Context(), user.ID, jobID, limit)
	if err != nil {
		if errors.Is(err, outbound.ErrNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "job not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"logs": logs})
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

	user, session, err := h.sessions.ResolveSession(c.Request.Context(), sessionID)
	if err != nil {
		switch {
		case errors.Is(err, areaauth.ErrSessionNotFound):
			c.JSON(http.StatusUnauthorized, gin.H{"error": "session invalid"})
		case errors.Is(err, areaauth.ErrAccountNotVerified):
			c.JSON(http.StatusForbidden, gin.H{"error": "account not verified"})
		default:
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to resolve session"})
		}
		return userdomain.User{}, sessiondomain.Session{}, false
	}
	h.refreshSessionCookie(c, session)
	return user, session, true
}

func (h *Handler) refreshSessionCookie(c *gin.Context, sess sessiondomain.Session) {
	maxAge := int(time.Until(sess.ExpiresAt).Seconds())
	if maxAge <= 0 {
		maxAge = 0
	}
	c.SetSameSite(h.cookies.SameSite)
	c.SetCookie(h.cookies.Name, sess.ID.String(), maxAge, h.cookies.Path, h.cookies.Domain, h.cookies.Secure, h.cookies.HTTPOnly)
}

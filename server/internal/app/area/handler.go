package area

import (
	"context"
	"errors"
	"net/http"
	"strings"
	"time"

	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/adapters/inbound/http/openapi"
	areaauth "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/app/auth"
	componentview "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/app/components"
	areadomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/area"
	sessiondomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/session"
	userdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/user"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	openapitypes "github.com/oapi-codegen/runtime/types"
	"go.uber.org/zap"
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

	if len(payload.Reactions) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "at least one reaction is required"})
		return
	}

	actionInput := fromCreateAction(payload.Action)
	reactionInputs := fromCreateReactions(payload.Reactions)

	created, err := h.service.Create(c.Request.Context(), usr.ID, name, desc, actionInput, reactionInputs)
	if err != nil {
		h.handleServiceError(c, err)
		return
	}

	c.JSON(http.StatusCreated, toOpenAPIArea(created))
}

// ExecuteArea handles POST /v1/areas/{areaId}/execute
func (h *Handler) ExecuteArea(c *gin.Context, areaID openapitypes.UUID) {
	usr, _, ok := h.authorize(c)
	if !ok {
		return
	}

	if err := h.service.Execute(c.Request.Context(), usr.ID, areaID); err != nil {
		h.handleExecuteError(c, err)
		return
	}

	c.Status(http.StatusAccepted)
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
	case errors.Is(err, ErrActionComponentRequired), errors.Is(err, ErrActionComponentInvalid), errors.Is(err, ErrActionComponentDisabled), errors.Is(err, ErrReactionsRequired), errors.Is(err, ErrReactionComponentInvalid), errors.Is(err, ErrReactionComponentDisabled):
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid component payload"})
	case errors.Is(err, ErrComponentParamsInvalid):
		zap.L().Warn("invalid component params", zap.Error(err))
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid component params"})
	case errors.Is(err, ErrProviderSubscriptionMissing):
		c.JSON(http.StatusForbidden, gin.H{"error": "provider subscription required"})
	case errors.Is(err, outbound.ErrConflict):
		c.JSON(http.StatusConflict, gin.H{"error": "area conflict"})
	case errors.Is(err, outbound.ErrNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": "area not found"})
	default:
		zap.L().Error("area service error", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal error"})
	}
}

func (h *Handler) handleExecuteError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, outbound.ErrNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": "area not found"})
	case errors.Is(err, ErrAreaNotOwned):
		c.JSON(http.StatusForbidden, gin.H{"error": "not owner"})
	case errors.Is(err, ErrAreaMisconfigured):
		c.JSON(http.StatusBadRequest, gin.H{"error": "area misconfigured"})
	default:
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to execute area"})
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
		Id:          area.ID,
		Name:        area.Name,
		Description: area.Description,
		Status:      string(area.Status),
		CreatedAt:   area.CreatedAt,
		UpdatedAt:   area.UpdatedAt,
		Action:      toOpenAPIAreaAction(area.Action),
		Reactions:   toOpenAPIAreaReactions(area.Reactions),
	}
}

func toOpenAPIAreaAction(action *areadomain.Link) *openapi.AreaAction {
	if action == nil {
		return nil
	}
	params := map[string]interface{}{}
	if action.Config.Params != nil {
		params = cloneMap(action.Config.Params)
	}
	var paramsPtr *map[string]interface{}
	if len(params) > 0 {
		paramsPtr = &params
	}
	var namePtr *string
	if trimmed := strings.TrimSpace(action.Config.Name); trimmed != "" {
		name := trimmed
		namePtr = &name
	}
	summary := componentview.ToSummary(action.Config.Component, action.Config.ComponentID)
	result := openapi.AreaAction{
		ConfigId:    action.Config.ID,
		ComponentId: action.Config.ComponentID,
		Component:   summary,
		Name:        namePtr,
		Params:      paramsPtr,
	}
	return &result
}

func toOpenAPIAreaReactions(reactions []areadomain.Link) []openapi.AreaReaction {
	if len(reactions) == 0 {
		return make([]openapi.AreaReaction, 0)
	}
	result := make([]openapi.AreaReaction, 0, len(reactions))
	for _, reaction := range reactions {
		params := map[string]interface{}{}
		if reaction.Config.Params != nil {
			params = cloneMap(reaction.Config.Params)
		}
		var paramsPtr *map[string]interface{}
		if len(params) > 0 {
			paramsPtr = &params
		}
		var namePtr *string
		if trimmed := strings.TrimSpace(reaction.Config.Name); trimmed != "" {
			name := trimmed
			namePtr = &name
		}
		summary := componentview.ToSummary(reaction.Config.Component, reaction.Config.ComponentID)
		result = append(result, openapi.AreaReaction{
			ConfigId:    reaction.Config.ID,
			ComponentId: reaction.Config.ComponentID,
			Component:   summary,
			Name:        namePtr,
			Params:      paramsPtr,
		})
	}
	return result
}

func fromCreateAction(action openapi.CreateAreaAction) ActionInput {
	params := map[string]any{}
	if action.Params != nil {
		params = cloneMap(*action.Params)
	}
	input := ActionInput{
		ComponentID: action.ComponentId,
		Params:      params,
	}
	if action.Name != nil {
		input.Name = strings.TrimSpace(*action.Name)
	}
	return input
}

func fromCreateReactions(reactions []openapi.CreateAreaReaction) []ReactionInput {
	inputs := make([]ReactionInput, 0, len(reactions))
	for _, reaction := range reactions {
		params := map[string]any{}
		if reaction.Params != nil {
			params = cloneMap(*reaction.Params)
		}
		input := ReactionInput{
			ComponentID: reaction.ComponentId,
			Params:      params,
		}
		if reaction.Name != nil {
			input.Name = strings.TrimSpace(*reaction.Name)
		}
		inputs = append(inputs, input)
	}
	return inputs
}

func cloneMap(source map[string]any) map[string]interface{} {
	if len(source) == 0 {
		return map[string]interface{}{}
	}
	result := make(map[string]interface{}, len(source))
	for key, value := range source {
		result[key] = value
	}
	return result
}

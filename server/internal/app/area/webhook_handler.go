package area

import (
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

const (
	webhookSecretHeader    = "X-Area-Webhook-Secret"
	webhookEventIDHeader   = "X-Area-Event-Id"
	webhookEventTimeHeader = "X-Area-Event-Time"
)

// WebhookHandler ingests webhook HTTP requests and delegates them to the area service
type WebhookHandler struct {
	service *Service
	logger  *zap.Logger
}

// NewWebhookHandler constructs a webhook handler backed by the provided service
func NewWebhookHandler(service *Service, logger *zap.Logger) *WebhookHandler {
	if logger == nil {
		logger = zap.NewNop()
	}
	return &WebhookHandler{service: service, logger: logger}
}

// Handle processes POST /hooks/*path requests
func (h *WebhookHandler) Handle(c *gin.Context) {
	if h == nil || h.service == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "webhook handler unavailable"})
		return
	}

	fullPath := strings.Trim(strings.TrimSpace(c.Request.URL.Path), "/")
	if fullPath == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "missing webhook path"})
		return
	}

	secret := c.GetHeader(webhookSecretHeader)
	fingerprint := strings.TrimSpace(c.GetHeader(webhookEventIDHeader))
	occurredAt := parseEventTime(c.GetHeader(webhookEventTimeHeader))

	payload, err := decodeWebhookPayload(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request payload"})
		return
	}
	if len(c.Request.URL.Query()) > 0 {
		payload["query"] = queryParamsToMap(c.Request.URL.Query())
	}
	if len(c.Request.Header) > 0 {
		payload["headers"] = headersToMap(c.Request.Header)
	}

	if err := h.service.ProcessWebhook(c.Request.Context(), fullPath, secret, payload, fingerprint, occurredAt); err != nil {
		h.handleError(c, err)
		return
	}

	c.Status(http.StatusAccepted)
}

func (h *WebhookHandler) handleError(c *gin.Context, err error) {
	switch {
	case err == nil:
		c.Status(http.StatusAccepted)
	case errors.Is(err, ErrWebhookNotFound), errors.Is(err, outbound.ErrNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": "webhook not found"})
	case errors.Is(err, ErrWebhookSecretMissing):
		c.JSON(http.StatusUnauthorized, gin.H{"error": "webhook secret missing"})
	case errors.Is(err, ErrWebhookSecretInvalid):
		c.JSON(http.StatusForbidden, gin.H{"error": "webhook secret invalid"})
	case errors.Is(err, ErrAreaNotOwned):
		c.JSON(http.StatusForbidden, gin.H{"error": "not owner"})
	default:
		h.log().Error("webhook processing failed", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "webhook processing failed"})
	}
}

func decodeWebhookPayload(c *gin.Context) (map[string]any, error) {
	payload := make(map[string]any)
	body := c.Request.Body
	if body == nil {
		return payload, nil
	}
	defer func() { _ = body.Close() }()

	contentType := strings.ToLower(strings.TrimSpace(c.GetHeader("Content-Type")))
	if strings.Contains(contentType, "application/json") {
		decoder := json.NewDecoder(body)
		decoder.UseNumber()
		if err := decoder.Decode(&payload); err != nil && err != io.EOF {
			return nil, err
		}
		if len(payload) == 0 {
			payload = make(map[string]any)
		}
		return payload, nil
	}

	bytes, err := io.ReadAll(body)
	if err != nil {
		return nil, err
	}
	if len(bytes) > 0 {
		payload["body"] = string(bytes)
	}
	return payload, nil
}

func parseEventTime(value string) time.Time {
	trimmed := strings.TrimSpace(value)
	if trimmed == "" {
		return time.Time{}
	}
	if ts, err := time.Parse(time.RFC3339, trimmed); err == nil {
		return ts.UTC()
	}
	return time.Time{}
}

func queryParamsToMap(values map[string][]string) map[string]any {
	result := make(map[string]any, len(values))
	for key, vals := range values {
		if len(vals) == 1 {
			result[key] = vals[0]
			continue
		}
		result[key] = append([]string(nil), vals...)
	}
	return result
}

func headersToMap(values http.Header) map[string]any {
	result := make(map[string]any, len(values))
	for key, vals := range values {
		if strings.EqualFold(key, webhookSecretHeader) {
			continue
		}
		if len(vals) == 1 {
			result[key] = vals[0]
			continue
		}
		result[key] = append([]string(nil), vals...)
	}
	return result
}

func (h *WebhookHandler) log() *zap.Logger {
	if h != nil && h.logger != nil {
		return h.logger
	}
	return zap.NewNop()
}

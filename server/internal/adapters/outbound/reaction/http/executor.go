package http

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	areadomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/area"
	componentdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/component"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
	"go.uber.org/zap"
)

// Executor delivers reaction payloads over HTTP according to reaction configuration
type Executor struct {
	Client *http.Client
	Logger *zap.Logger
}

// Supports reports whether the executor can handle the provided component
func (e Executor) Supports(component *componentdomain.Component) bool {
	if component == nil {
		return false
	}
	name := strings.ToLower(component.Name)
	return name == "http_webhook" || name == "http_request"
}

// Execute dispatches the reaction for supported components
func (e Executor) Execute(ctx context.Context, area areadomain.Area, link areadomain.Link) (outbound.ReactionResult, error) {
	return e.ExecuteReaction(ctx, area, link)
}

// ExecuteReaction sends an HTTP request when the reaction component is supported
func (e Executor) ExecuteReaction(ctx context.Context, area areadomain.Area, link areadomain.Link) (outbound.ReactionResult, error) {
	component := link.Config.Component
	if component == nil {
		return outbound.ReactionResult{}, fmt.Errorf("reaction.http: component metadata missing")
	}
	name := strings.ToLower(component.Name)
	switch name {
	case "http_webhook", "http_request":
		return e.execHTTPRequest(ctx, area, link)
	default:
		logger := e.logger()
		logger.Warn("unsupported reaction component", zap.String("component", component.Name))
		return outbound.ReactionResult{}, fmt.Errorf("reaction.http: component %s unsupported", component.Name)
	}
}

func (e Executor) execHTTPRequest(ctx context.Context, area areadomain.Area, link areadomain.Link) (outbound.ReactionResult, error) {
	params := link.Config.Params
	url := stringParam(params, "url", "endpoint")
	if url == "" {
		return outbound.ReactionResult{}, fmt.Errorf("reaction.http: params.url required")
	}
	method := strings.ToUpper(stringParam(params, "method"))
	if method == "" {
		method = http.MethodPost
	}

	bodyBytes, contentType, err := e.buildBody(area, link, params)
	if err != nil {
		return outbound.ReactionResult{}, err
	}

	req, err := http.NewRequestWithContext(ctx, method, url, bytes.NewReader(bodyBytes))
	if err != nil {
		return outbound.ReactionResult{}, fmt.Errorf("reaction.http: new request: %w", err)
	}
	if contentType != "" {
		req.Header.Set("Content-Type", contentType)
	}
	for key, value := range headerMap(params) {
		req.Header.Set(key, value)
	}

	start := time.Now()
	resp, err := e.client().Do(req)
	if err != nil {
		return outbound.ReactionResult{}, fmt.Errorf("reaction.http: request failed: %w", err)
	}
	defer resp.Body.Close()

	respBody, readErr := io.ReadAll(resp.Body)
	if readErr != nil {
		return outbound.ReactionResult{}, fmt.Errorf("reaction.http: read response: %w", readErr)
	}
	duration := time.Since(start)

	requestHeaders := map[string][]string{}
	for key, values := range req.Header {
		requestHeaders[key] = append([]string(nil), values...)
	}
	responseHeaders := map[string][]string{}
	for key, values := range resp.Header {
		responseHeaders[key] = append([]string(nil), values...)
	}

	if resp.StatusCode >= 400 {
		return outbound.ReactionResult{
			Endpoint: url,
			Request: map[string]any{
				"method":  method,
				"url":     url,
				"headers": requestHeaders,
				"body":    string(bodyBytes),
			},
			Response: map[string]any{
				"body":    string(respBody),
				"headers": responseHeaders,
			},
			StatusCode: &resp.StatusCode,
			Duration:   duration,
		}, fmt.Errorf("reaction.http: received status %d", resp.StatusCode)
	}

	e.logger().Info("reaction delivered",
		zap.String("area_id", area.ID.String()),
		zap.String("area_name", area.Name),
		zap.String("reaction_id", link.ID.String()),
		zap.String("endpoint", url),
		zap.Int("status", resp.StatusCode),
	)
	return outbound.ReactionResult{
		Endpoint: url,
		Request: map[string]any{
			"method":  method,
			"url":     url,
			"headers": requestHeaders,
			"body":    string(bodyBytes),
		},
		Response: map[string]any{
			"body":    string(respBody),
			"headers": responseHeaders,
		},
		StatusCode: &resp.StatusCode,
		Duration:   duration,
	}, nil
}

func (e Executor) client() *http.Client {
	if e.Client != nil {
		return e.Client
	}
	return &http.Client{Timeout: 10 * time.Second}
}

func (e Executor) logger() *zap.Logger {
	if e.Logger != nil {
		return e.Logger
	}
	return zap.NewNop()
}

func (e Executor) buildBody(area areadomain.Area, link areadomain.Link, params map[string]any) ([]byte, string, error) {
	if raw, ok := params["body"]; ok {
		switch v := raw.(type) {
		case string:
			return []byte(v), "", nil
		default:
			payload, err := json.Marshal(v)
			if err != nil {
				return nil, "", fmt.Errorf("reaction.http: marshal params.body: %w", err)
			}
			return payload, "application/json", nil
		}
	}
	defaultBody := map[string]any{
		"area": map[string]any{
			"id":   area.ID.String(),
			"name": area.Name,
		},
		"reaction": map[string]any{
			"id":   link.ID.String(),
			"name": link.Config.Name,
		},
		"triggered_at": time.Now().UTC().Format(time.RFC3339Nano),
	}
	body, err := json.Marshal(defaultBody)
	if err != nil {
		return nil, "", fmt.Errorf("reaction.http: marshal default body: %w", err)
	}
	return body, "application/json", nil
}

func stringParam(params map[string]any, keys ...string) string {
	for _, key := range keys {
		if value, ok := params[key]; ok {
			switch v := value.(type) {
			case string:
				if trimmed := strings.TrimSpace(v); trimmed != "" {
					return trimmed
				}
			}
		}
	}
	return ""
}

func headerMap(params map[string]any) map[string]string {
	raw, ok := params["headers"]
	if !ok {
		return map[string]string{}
	}
	result := make(map[string]string)
	switch v := raw.(type) {
	case map[string]any:
		for key, value := range v {
			if str, ok := value.(string); ok {
				result[key] = str
			}
		}
	case map[string]string:
		for key, value := range v {
			result[key] = value
		}
	}
	return result
}

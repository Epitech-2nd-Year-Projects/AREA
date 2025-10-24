package area

import (
	"context"
	"encoding/json"
	"fmt"
	"hash/fnv"
	"io"
	"net/http"
	"net/url"
	"regexp"
	"strconv"
	"strings"
	"time"

	componentdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/component"
	"go.uber.org/zap"
)

const (
	httpPollingCursorSourceItem        = "item"
	httpPollingCursorSourceResponse    = "response"
	httpPollingCursorSourceFingerprint = "fingerprint"
)

var placeholderPattern = regexp.MustCompile(`\{\{\s*(params|cursor)\.([a-zA-Z0-9_\-]+)\s*\}\}`)

// HTTPPollingHandler polls HTTP endpoints defined in component metadata to produce action events
type HTTPPollingHandler struct {
	client *http.Client
	logger *zap.Logger
}

// NewHTTPPollingHandler assembles an HTTP polling handler
func NewHTTPPollingHandler(client *http.Client, logger *zap.Logger) *HTTPPollingHandler {
	if client == nil {
		client = &http.Client{Timeout: 15 * time.Second}
	}
	if logger == nil {
		logger = zap.NewNop()
	}
	return &HTTPPollingHandler{client: client, logger: logger}
}

// Supports reports whether the component declares a compatible HTTP polling ingestion
func (h *HTTPPollingHandler) Supports(component *componentdomain.Component) bool {
	_, ok, err := parseHTTPPollingConfig(component)
	return err == nil && ok
}

// Poll executes the HTTP polling flow for supported components
func (h *HTTPPollingHandler) Poll(ctx context.Context, req PollingRequest) (PollingResult, error) {
	config, ok, err := parseHTTPPollingConfig(&req.Component)
	if err != nil {
		return PollingResult{}, fmt.Errorf("area.HTTPPollingHandler.Poll: parse config: %w", err)
	}
	if !ok {
		return PollingResult{}, fmt.Errorf("area.HTTPPollingHandler.Poll: component %q not supported", req.Component.Name)
	}

	endpoint, err := renderTemplate(config.EndpointTemplate, req)
	if err != nil {
		return PollingResult{}, fmt.Errorf("area.HTTPPollingHandler.Poll: render endpoint: %w", err)
	}
	if strings.TrimSpace(endpoint) == "" {
		return PollingResult{}, fmt.Errorf("area.HTTPPollingHandler.Poll: endpoint empty after rendering")
	}

	u, err := url.Parse(endpoint)
	if err != nil {
		return PollingResult{}, fmt.Errorf("area.HTTPPollingHandler.Poll: parse endpoint: %w", err)
	}

	query := u.Query()
	for _, spec := range config.Query {
		value, renderErr := renderTemplate(spec.Template, req)
		if renderErr != nil {
			return PollingResult{}, fmt.Errorf("area.HTTPPollingHandler.Poll: render query %q: %w", spec.Name, renderErr)
		}
		if strings.TrimSpace(value) == "" && spec.Default != "" {
			defaultValue, defaultErr := renderTemplate(spec.Default, req)
			if defaultErr != nil {
				return PollingResult{}, fmt.Errorf("area.HTTPPollingHandler.Poll: render default for %q: %w", spec.Name, defaultErr)
			}
			value = defaultValue
		}
		if strings.TrimSpace(value) == "" && spec.SkipIfEmpty {
			continue
		}
		query.Set(spec.Name, value)
	}
	u.RawQuery = query.Encode()

	method := config.Method
	if method == "" {
		method = http.MethodGet
	}

	var body io.Reader
	if config.BodyTemplate != "" {
		payload, renderErr := renderTemplate(config.BodyTemplate, req)
		if renderErr != nil {
			return PollingResult{}, fmt.Errorf("area.HTTPPollingHandler.Poll: render body: %w", renderErr)
		}
		body = strings.NewReader(payload)
	}

	request, err := http.NewRequestWithContext(ctx, method, u.String(), body)
	if err != nil {
		return PollingResult{}, fmt.Errorf("area.HTTPPollingHandler.Poll: build request: %w", err)
	}
	for _, header := range config.Headers {
		value, renderErr := renderTemplate(header.Template, req)
		if renderErr != nil {
			return PollingResult{}, fmt.Errorf("area.HTTPPollingHandler.Poll: render header %q: %w", header.Name, renderErr)
		}
		if strings.TrimSpace(value) == "" && header.Default != "" {
			defaultValue, defaultErr := renderTemplate(header.Default, req)
			if defaultErr != nil {
				return PollingResult{}, fmt.Errorf("area.HTTPPollingHandler.Poll: render default header %q: %w", header.Name, defaultErr)
			}
			value = defaultValue
		}
		if strings.TrimSpace(value) == "" && header.SkipIfEmpty {
			continue
		}
		request.Header.Set(header.Name, value)
	}
	if request.Header.Get("Accept") == "" {
		request.Header.Set("Accept", "application/json")
	}

	response, err := h.client.Do(request)
	if err != nil {
		return PollingResult{}, fmt.Errorf("area.HTTPPollingHandler.Poll: request failed: %w", err)
	}
	defer func() {
		_ = response.Body.Close()
	}()
	if response.StatusCode >= 300 {
		bodyBytes, _ := io.ReadAll(io.LimitReader(response.Body, 4096))
		return PollingResult{}, fmt.Errorf("area.HTTPPollingHandler.Poll: status %d: %s", response.StatusCode, strings.TrimSpace(string(bodyBytes)))
	}

	var payload any
	decoder := json.NewDecoder(response.Body)
	decoder.UseNumber()
	if err := decoder.Decode(&payload); err != nil {
		return PollingResult{}, fmt.Errorf("area.HTTPPollingHandler.Poll: decode response: %w", err)
	}

	itemsValue, err := resolvePath(payload, config.ItemsPath)
	if err != nil {
		return PollingResult{}, fmt.Errorf("area.HTTPPollingHandler.Poll: items path: %w", err)
	}

	items, ok := itemsValue.([]any)
	if !ok {
		return PollingResult{}, fmt.Errorf("area.HTTPPollingHandler.Poll: items not an array")
	}

	result := PollingResult{
		Cursor: cloneMapAny(req.Cursor),
		Events: make([]PollingEvent, 0, len(items)),
	}
	if result.Cursor == nil {
		result.Cursor = map[string]any{}
	}

	var lastCursorValue string
	for _, rawItem := range items {
		itemMap, itemErr := toMapStringAny(rawItem)
		if itemErr != nil {
			h.logger.Warn("http polling skipped non-map item",
				zap.String("component", req.Component.Name),
				zap.String("provider", req.Component.Provider.Name),
			)
			continue
		}

		fingerprint := ""
		if len(config.FingerprintPath) > 0 {
			if rawValue, valueErr := resolvePath(itemMap, config.FingerprintPath); valueErr == nil {
				fingerprint = stringify(rawValue)
			}
		}
		if fingerprint == "" {
			hashValue, hashErr := hashItem(itemMap)
			if hashErr == nil {
				fingerprint = hashValue
			}
		}

		occurredAt := time.Time{}
		if len(config.OccurredAtPath) > 0 {
			if rawValue, valueErr := resolvePath(itemMap, config.OccurredAtPath); valueErr == nil {
				if parsed, parseErr := parseTime(rawValue); parseErr == nil {
					occurredAt = parsed
				}
			}
		}

		event := PollingEvent{
			Payload:     cloneMapAny(itemMap),
			Fingerprint: fingerprint,
			OccurredAt:  occurredAt,
		}
		result.Events = append(result.Events, event)

		switch config.CursorSource {
		case httpPollingCursorSourceItem:
			if rawValue, valueErr := resolvePath(itemMap, config.CursorItemPath); valueErr == nil {
				lastCursorValue = stringify(rawValue)
			}
		case httpPollingCursorSourceFingerprint:
			if fingerprint != "" {
				lastCursorValue = fingerprint
			}
		}
	}

	if config.CursorSource == httpPollingCursorSourceResponse {
		if rawValue, valueErr := resolvePath(payload, config.CursorResponsePath); valueErr == nil {
			lastCursorValue = stringify(rawValue)
		}
	}

	if lastCursorValue != "" {
		result.Cursor[config.CursorKey] = lastCursorValue
	} else if _, exists := result.Cursor[config.CursorKey]; !exists && config.CursorInitial != "" {
		result.Cursor[config.CursorKey] = config.CursorInitial
	}
	result.Cursor["last_polled_at"] = req.Now.UTC().Format(time.RFC3339Nano)

	return result, nil
}

type httpPollingConfig struct {
	EndpointTemplate   string
	Method             string
	ItemsPath          []string
	FingerprintPath    []string
	OccurredAtPath     []string
	CursorKey          string
	CursorSource       string
	CursorItemPath     []string
	CursorResponsePath []string
	CursorInitial      string
	Query              []httpQuerySpec
	Headers            []httpHeaderSpec
	BodyTemplate       string
}

type httpQuerySpec struct {
	Name        string
	Template    string
	Default     string
	SkipIfEmpty bool
}

type httpHeaderSpec struct {
	Name        string
	Template    string
	Default     string
	SkipIfEmpty bool
}

func parseHTTPPollingConfig(component *componentdomain.Component) (httpPollingConfig, bool, error) {
	if component == nil {
		return httpPollingConfig{}, false, nil
	}
	metadata := component.Metadata
	if len(metadata) == 0 {
		return httpPollingConfig{}, false, nil
	}
	ingestionRaw, ok := metadata["ingestion"]
	if !ok {
		return httpPollingConfig{}, false, nil
	}
	ingestion, err := toMapStringAny(ingestionRaw)
	if err != nil {
		return httpPollingConfig{}, false, fmt.Errorf("ingestion metadata invalid: %w", err)
	}
	mode, err := toString(ingestion["mode"])
	if err != nil || strings.ToLower(strings.TrimSpace(mode)) != "polling" {
		return httpPollingConfig{}, false, nil
	}

	handlerName := ""
	if name, err := toString(ingestion["handler"]); err == nil {
		handlerName = strings.ToLower(strings.TrimSpace(name))
	}
	if handlerName != "" && handlerName != "http" {
		return httpPollingConfig{}, false, nil
	}

	configMap := ingestion
	if httpRaw, ok := ingestion["http"]; ok {
		if httpMap, mapErr := toMapStringAny(httpRaw); mapErr == nil {
			configMap = httpMap
		}
	}

	endpoint, err := toString(configMap["endpoint"])
	if err != nil || strings.TrimSpace(endpoint) == "" {
		return httpPollingConfig{}, false, fmt.Errorf("ingestion.endpoint missing")
	}

	method := strings.ToUpper(strings.TrimSpace(stringOrDefault(configMap, "method", http.MethodGet)))

	itemsPath := splitPath(stringOrDefault(configMap, "itemsPath", ""))
	fingerprintPath := splitPath(stringOrDefault(configMap, "fingerprintField", ""))
	occurredAtPath := splitPath(stringOrDefault(configMap, "occurredAtField", ""))

	cursorConfig := httpPollingCursor{
		Key:      sanitizeCursorKey(component),
		Initial:  stringOrDefault(configMap, "initialCursor", ""),
		Source:   httpPollingCursorSourceItem,
		ItemPath: splitPath(stringOrDefault(configMap, "cursorField", "")),
	}
	if cursorRaw, ok := ingestion["cursor"]; ok {
		if cursorMap, cursorErr := toMapStringAny(cursorRaw); cursorErr == nil {
			cursorConfig = mergeCursorConfig(cursorConfig, cursorMap)
		} else {
			return httpPollingConfig{}, false, fmt.Errorf("cursor metadata invalid: %w", cursorErr)
		}
	}
	if cursorRaw, ok := configMap["cursor"]; ok {
		if cursorMap, cursorErr := toMapStringAny(cursorRaw); cursorErr == nil {
			cursorConfig = mergeCursorConfig(cursorConfig, cursorMap)
		} else {
			return httpPollingConfig{}, false, fmt.Errorf("cursor metadata invalid: %w", cursorErr)
		}
	}

	if cursorConfig.Source == httpPollingCursorSourceItem && len(cursorConfig.ItemPath) == 0 && len(fingerprintPath) == 0 {
		return httpPollingConfig{}, false, fmt.Errorf("cursor.item.path missing and no fingerprintField provided")
	}
	if cursorConfig.Source == httpPollingCursorSourceResponse && len(cursorConfig.ResponsePath) == 0 {
		return httpPollingConfig{}, false, fmt.Errorf("cursor.response.path missing")
	}

	querySpecs, err := parseHTTPQuerySpecs(configMap["query"])
	if err != nil {
		return httpPollingConfig{}, false, fmt.Errorf("query metadata invalid: %w", err)
	}

	headerSpecs, err := parseHTTPHeaderSpecs(configMap["headers"])
	if err != nil {
		return httpPollingConfig{}, false, fmt.Errorf("headers metadata invalid: %w", err)
	}

	bodyTemplate := stringOrDefault(configMap, "bodyTemplate", "")

	config := httpPollingConfig{
		EndpointTemplate:   endpoint,
		Method:             method,
		ItemsPath:          itemsPath,
		FingerprintPath:    fingerprintPath,
		OccurredAtPath:     occurredAtPath,
		CursorKey:          cursorConfig.Key,
		CursorSource:       cursorConfig.Source,
		CursorItemPath:     cursorConfig.ItemPath,
		CursorResponsePath: cursorConfig.ResponsePath,
		CursorInitial:      cursorConfig.Initial,
		Query:              querySpecs,
		Headers:            headerSpecs,
		BodyTemplate:       bodyTemplate,
	}
	return config, true, nil
}

type httpPollingCursor struct {
	Key          string
	Initial      string
	Source       string
	ItemPath     []string
	ResponsePath []string
}

func mergeCursorConfig(base httpPollingCursor, overrides map[string]any) httpPollingCursor {
	if value, err := toString(overrides["key"]); err == nil && strings.TrimSpace(value) != "" {
		base.Key = strings.TrimSpace(value)
	}
	if value, err := toString(overrides["initial"]); err == nil {
		base.Initial = strings.TrimSpace(value)
	}
	if value, err := toString(overrides["source"]); err == nil && strings.TrimSpace(value) != "" {
		base.Source = strings.ToLower(strings.TrimSpace(value))
	}
	if value, err := toString(overrides["path"]); err == nil {
		base.ItemPath = splitPath(value)
	}
	if value, err := toString(overrides["itemPath"]); err == nil {
		base.ItemPath = splitPath(value)
	}
	if value, err := toString(overrides["responsePath"]); err == nil {
		base.ResponsePath = splitPath(value)
	}
	return base
}

func parseHTTPQuerySpecs(raw any) ([]httpQuerySpec, error) {
	if raw == nil {
		return nil, nil
	}
	items, ok := raw.([]any)
	if !ok {
		return nil, fmt.Errorf(" not an array")
	}
	result := make([]httpQuerySpec, 0, len(items))
	for _, item := range items {
		entry, err := toMapStringAny(item)
		if err != nil {
			return nil, err
		}
		name, err := toString(entry["name"])
		if err != nil || strings.TrimSpace(name) == "" {
			return nil, fmt.Errorf("query name missing")
		}
		spec := httpQuerySpec{
			Name:        strings.TrimSpace(name),
			Template:    selectTemplate(entry),
			Default:     strings.TrimSpace(stringOrDefault(entry, "default", "")),
			SkipIfEmpty: boolOrDefault(entry, "skipIfEmpty"),
		}
		if spec.Template == "" {
			spec.Template = stringOrDefault(entry, "value", "")
		}
		if spec.Template == "" {
			if paramName := stringOrDefault(entry, "param", ""); paramName != "" {
				spec.Template = "{{params." + paramName + "}}"
			}
		}
		if spec.Template == "" {
			if cursorName := stringOrDefault(entry, "cursor", ""); cursorName != "" {
				spec.Template = "{{cursor." + cursorName + "}}"
			}
		}
		result = append(result, spec)
	}
	return result, nil
}

func parseHTTPHeaderSpecs(raw any) ([]httpHeaderSpec, error) {
	if raw == nil {
		return nil, nil
	}
	items, ok := raw.([]any)
	if !ok {
		return nil, fmt.Errorf(" not an array")
	}
	result := make([]httpHeaderSpec, 0, len(items))
	for _, item := range items {
		entry, err := toMapStringAny(item)
		if err != nil {
			return nil, err
		}
		name, err := toString(entry["name"])
		if err != nil || strings.TrimSpace(name) == "" {
			return nil, fmt.Errorf("header name missing")
		}
		spec := httpHeaderSpec{
			Name:        strings.TrimSpace(name),
			Template:    selectTemplate(entry),
			Default:     strings.TrimSpace(stringOrDefault(entry, "default", "")),
			SkipIfEmpty: boolOrDefault(entry, "skipIfEmpty"),
		}
		if spec.Template == "" {
			spec.Template = stringOrDefault(entry, "value", "")
		}
		if spec.Template == "" {
			if paramName := stringOrDefault(entry, "param", ""); paramName != "" {
				spec.Template = "{{params." + paramName + "}}"
			}
		}
		if spec.Template == "" {
			if cursorName := stringOrDefault(entry, "cursor", ""); cursorName != "" {
				spec.Template = "{{cursor." + cursorName + "}}"
			}
		}
		result = append(result, spec)
	}
	return result, nil
}

func selectTemplate(values map[string]any) string {
	if value, err := toString(values["template"]); err == nil {
		return value
	}
	return ""
}

func stringOrDefault(values map[string]any, key string, fallback string) string {
	if values == nil {
		return fallback
	}
	if value, ok := values[key]; ok {
		if str, err := toString(value); err == nil {
			return str
		}
	}
	return fallback
}

func boolOrDefault(values map[string]any, key string) bool {
	if values == nil {
		return false
	}
	if raw, ok := values[key]; ok {
		switch v := raw.(type) {
		case bool:
			return v
		}
	}
	return false
}

func sanitizeCursorKey(component *componentdomain.Component) string {
	if component == nil {
		return "cursor"
	}
	parts := []string{component.Provider.Name, component.Name, "cursor"}
	joined := strings.ToLower(strings.Join(parts, "_"))
	joined = regexp.MustCompile(`[^a-z0-9]+`).ReplaceAllString(joined, "_")
	joined = strings.Trim(joined, "_")
	if joined == "" {
		return "cursor"
	}
	return joined
}

func renderTemplate(template string, req PollingRequest) (string, error) {
	if template == "" {
		return "", nil
	}
	result := placeholderPattern.ReplaceAllStringFunc(template, func(match string) string {
		submatches := placeholderPattern.FindStringSubmatch(match)
		if len(submatches) != 3 {
			return ""
		}
		switch submatches[1] {
		case "params":
			return stringify(req.Binding.Config.Params[submatches[2]])
		case "cursor":
			return stringify(req.Cursor[submatches[2]])
		default:
			return ""
		}
	})
	result = strings.ReplaceAll(result, "{{now_rfc3339}}", req.Now.UTC().Format(time.RFC3339))
	result = strings.ReplaceAll(result, "{{now_unix}}", strconv.FormatInt(req.Now.UTC().Unix(), 10))
	return result, nil
}

func resolvePath(value any, path []string) (any, error) {
	if len(path) == 0 {
		return value, nil
	}
	current := value
	for _, segment := range path {
		switch typed := current.(type) {
		case map[string]any:
			next, ok := typed[segment]
			if !ok {
				return nil, fmt.Errorf("segment %q missing", segment)
			}
			current = next
		default:
			return nil, fmt.Errorf("segment %q not found", segment)
		}
	}
	return current, nil
}

func splitPath(value string) []string {
	trimmed := strings.TrimSpace(value)
	if trimmed == "" {
		return nil
	}
	parts := strings.Split(trimmed, ".")
	result := make([]string, 0, len(parts))
	for _, part := range parts {
		if trimmedPart := strings.TrimSpace(part); trimmedPart != "" {
			result = append(result, trimmedPart)
		}
	}
	return result
}

func stringify(value any) string {
	switch v := value.(type) {
	case nil:
		return ""
	case string:
		return v
	case fmt.Stringer:
		return v.String()
	case json.Number:
		return v.String()
	case int:
		return strconv.Itoa(v)
	case int32:
		return strconv.FormatInt(int64(v), 10)
	case int64:
		return strconv.FormatInt(v, 10)
	case float64:
		return strconv.FormatFloat(v, 'f', -1, 64)
	case bool:
		if v {
			return "true"
		}
		return "false"
	default:
		bytes, err := json.Marshal(v)
		if err != nil {
			return ""
		}
		return string(bytes)
	}
}

func hashItem(value map[string]any) (string, error) {
	bytes, err := json.Marshal(value)
	if err != nil {
		return "", err
	}
	hasher := fnv.New64a()
	if _, err := hasher.Write(bytes); err != nil {
		return "", err
	}
	return strconv.FormatUint(hasher.Sum64(), 16), nil
}

func parseTime(value any) (time.Time, error) {
	switch v := value.(type) {
	case string:
		candidates := []string{
			time.RFC3339Nano,
			time.RFC3339,
			time.RFC1123,
			"2006-01-02 15:04:05",
			time.RFC822,
		}
		for _, layout := range candidates {
			if parsed, err := time.Parse(layout, strings.TrimSpace(v)); err == nil {
				return parsed.UTC(), nil
			}
		}
	case json.Number:
		if i64, err := v.Int64(); err == nil {
			return time.Unix(i64, 0).UTC(), nil
		}
		if f64, err := v.Float64(); err == nil {
			seconds := int64(f64)
			return time.Unix(seconds, 0).UTC(), nil
		}
	case float64:
		return time.Unix(int64(v), 0).UTC(), nil
	case int64:
		return time.Unix(v, 0).UTC(), nil
	case int:
		return time.Unix(int64(v), 0).UTC(), nil
	}
	return time.Time{}, fmt.Errorf("unhandled time representation")
}

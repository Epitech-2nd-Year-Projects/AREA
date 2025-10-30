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
	identitydomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/identity"
	identityport "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound/identity"
	"github.com/google/uuid"
	"go.uber.org/zap"
)

const (
	httpPollingCursorSourceItem        = "item"
	httpPollingCursorSourceResponse    = "response"
	httpPollingCursorSourceFingerprint = "fingerprint"
)

var placeholderPattern = regexp.MustCompile(`\{\{\s*(params|cursor|identity)\.([a-zA-Z0-9_\-]+)\s*\}\}`)

// HTTPPollingHandler polls HTTP endpoints defined in component metadata to produce action events
type HTTPPollingHandler struct {
	client     *http.Client
	logger     *zap.Logger
	identities identityport.Repository
	providers  oauthProviderResolver
}

type oauthProviderResolver interface {
	Provider(name string) (identityport.Provider, bool)
}

// NewHTTPPollingHandler assembles an HTTP polling handler
func NewHTTPPollingHandler(client *http.Client, logger *zap.Logger, identities identityport.Repository, providers oauthProviderResolver) *HTTPPollingHandler {
	if client == nil {
		client = &http.Client{Timeout: 15 * time.Second}
	}
	if logger == nil {
		logger = zap.NewNop()
	}
	return &HTTPPollingHandler{
		client:     client,
		logger:     logger,
		identities: identities,
		providers:  providers,
	}
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

	if config.Auth != nil && strings.EqualFold(config.Auth.Kind, "oauth") {
		if err := h.injectIdentity(ctx, &req, config); err != nil {
			return PollingResult{}, err
		}
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
		if shouldTreatAsEmpty(value, spec.templateHasPlaceholder, spec.baseTemplate) {
			if spec.Default != "" {
				defaultValue, defaultErr := renderTemplate(spec.Default, req)
				if defaultErr != nil {
					return PollingResult{}, fmt.Errorf("area.HTTPPollingHandler.Poll: render default for %q: %w", spec.Name, defaultErr)
				}
				value = defaultValue
				if spec.SkipIfEmpty && shouldTreatAsEmpty(value, spec.defaultHasPlaceholder, spec.baseDefault) {
					continue
				}
			} else if spec.SkipIfEmpty {
				continue
			}
		} else if spec.SkipIfEmpty && strings.TrimSpace(value) == "" {
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
		if shouldTreatAsEmpty(value, header.templateHasPlaceholder, header.baseTemplate) {
			if header.Default != "" {
				defaultValue, defaultErr := renderTemplate(header.Default, req)
				if defaultErr != nil {
					return PollingResult{}, fmt.Errorf("area.HTTPPollingHandler.Poll: render default header %q: %w", header.Name, defaultErr)
				}
				value = defaultValue
				if header.SkipIfEmpty && shouldTreatAsEmpty(value, header.defaultHasPlaceholder, header.baseDefault) {
					continue
				}
			} else if header.SkipIfEmpty {
				continue
			}
		} else if header.SkipIfEmpty && strings.TrimSpace(value) == "" {
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

	cursorView := flattenCursorState(req.Cursor)

	result := PollingResult{
		Cursor: cloneMapAny(req.Cursor),
		Events: make([]PollingEvent, 0, len(items)),
	}
	if result.Cursor == nil {
		result.Cursor = map[string]any{}
	}
	cursorState := ensureCursorState(result.Cursor)

	prevCutoffRaw := strings.TrimSpace(stringify(cursorView["last_seen_ts"]))
	if prevCutoffRaw == "" {
		prevCutoffRaw = strings.TrimSpace(stringify(cursorView[config.CursorKey]))
	}
	if prevCutoffRaw == "" {
		prevCutoffRaw = strings.TrimSpace(stringify(cursorView["last_seen_name"]))
	}
	var prevCutoffValue float64
	hasPrevCutoff := false
	var prevCutoffTime time.Time
	hasPrevCutoffTime := false
	if prevCutoffRaw != "" {
		if parsed, err := strconv.ParseFloat(prevCutoffRaw, 64); err == nil {
			prevCutoffValue = parsed
			hasPrevCutoff = true
		}
		if parsedTime, err := parseTime(prevCutoffRaw); err == nil && !parsedTime.IsZero() {
			prevCutoffTime = parsedTime.UTC()
			hasPrevCutoffTime = true
		}
	}
	prevFingerprint := ""
	if config.CursorSource == httpPollingCursorSourceFingerprint {
		prevFingerprint = strings.TrimSpace(stringify(cursorView[config.CursorKey]))
	}

	var latestCursorValue string
	var latestCursorFloat float64
	hasLatestCursor := false
	var hasLatestCursorFloat bool
	var latestCursorTime time.Time
	var hasLatestCursorTime bool
	var latestOccurredAt time.Time
	var hasLatestOccurredAt bool

	seenFingerprints := make(map[string]struct{})

	for _, rawItem := range items {
		itemMap, itemErr := toMapStringAny(rawItem)
		if itemErr != nil {
			h.logger.Warn("http polling skipped non-map item",
				zap.String("component", req.Component.Name),
				zap.String("provider", req.Component.Provider.Name),
			)
			continue
		}

		if shouldSkipItem(itemMap, config.SkipRules) {
			h.logger.Debug("polling item skipped via rule",
				zap.String("component", req.Component.Name),
				zap.String("provider", req.Component.Provider.Name),
				zap.Any("skip_rules", config.SkipRules))
			continue
		}

		candidateTS := strings.TrimSpace(stringify(itemMap["ts"]))
		if strings.EqualFold(req.Component.Provider.Name, "slack") {
			if botID := strings.TrimSpace(stringify(itemMap["bot_id"])); botID != "" {
				continue
			}
			if subtype := strings.TrimSpace(strings.ToLower(stringify(itemMap["subtype"]))); subtype != "" && subtype != "message" {
				continue
			}
			if hasPrevCutoff && candidateTS != "" {
				if currValue, err := strconv.ParseFloat(candidateTS, 64); err == nil && currValue <= prevCutoffValue {
					continue
				}
			}
		}

		var cursorCandidate string
		var hasCursorCandidate bool
		var cursorCandidateFloat float64
		var hasCursorCandidateFloat bool
		var cursorCandidateTime time.Time
		var hasCursorCandidateTime bool

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

		switch config.CursorSource {
		case httpPollingCursorSourceItem:
			if rawValue, valueErr := resolvePath(itemMap, config.CursorItemPath); valueErr == nil {
				candidate := strings.TrimSpace(stringify(rawValue))
				if candidate != "" {
					cursorCandidate = candidate
					hasCursorCandidate = true
					cursorCandidateFloat, hasCursorCandidateFloat = tryParseFloat(candidate)
					cursorCandidateTime, hasCursorCandidateTime = tryParseTime(candidate)
				}
			}
		case httpPollingCursorSourceFingerprint:
			if fingerprint != "" {
				cursorCandidate = fingerprint
				hasCursorCandidate = true
			}
		}

		if config.CursorSource == httpPollingCursorSourceFingerprint {
			if fingerprint == "" {
				continue
			}
			if fingerprint == prevFingerprint && prevFingerprint != "" {
				if !hasPrevCutoff && !hasPrevCutoffTime {
					break
				}
				continue
			}
			if hasPrevCutoffTime && !occurredAt.IsZero() && !occurredAt.After(prevCutoffTime) {
				continue
			}
			if _, exists := seenFingerprints[fingerprint]; exists {
				continue
			}
			seenFingerprints[fingerprint] = struct{}{}
		}

		if hasPrevCutoffTime && !occurredAt.IsZero() && !occurredAt.After(prevCutoffTime) {
			continue
		}

		if config.CursorSource == httpPollingCursorSourceItem {
			if hasPrevCutoff && hasCursorCandidateFloat && cursorCandidateFloat <= prevCutoffValue {
				h.logger.Debug("polling item skipped via numeric cursor cutoff",
					zap.String("component", req.Component.Name),
					zap.String("provider", req.Component.Provider.Name),
					zap.Float64("candidate", cursorCandidateFloat),
					zap.Float64("previous", prevCutoffValue))
				continue
			}
			if hasPrevCutoffTime && hasCursorCandidateTime && !cursorCandidateTime.After(prevCutoffTime) {
				h.logger.Debug("polling item skipped via time cursor cutoff",
					zap.String("component", req.Component.Name),
					zap.String("provider", req.Component.Provider.Name),
					zap.Time("candidate", cursorCandidateTime),
					zap.Time("previous", prevCutoffTime))
				continue
			}
		}

		event := PollingEvent{
			Payload:     cloneMapAny(itemMap),
			Fingerprint: fingerprint,
			OccurredAt:  occurredAt,
		}
		result.Events = append(result.Events, event)
		if !occurredAt.IsZero() && (!hasLatestOccurredAt || occurredAt.After(latestOccurredAt)) {
			latestOccurredAt = occurredAt
			hasLatestOccurredAt = true
			if config.CursorSource == httpPollingCursorSourceFingerprint {
				latestCursorValue = fingerprint
				hasLatestCursor = true
			}
		}

		if hasCursorCandidate {
			if hasCursorCandidateFloat {
				if !hasLatestCursorFloat || cursorCandidateFloat > latestCursorFloat {
					latestCursorFloat = cursorCandidateFloat
					latestCursorValue = cursorCandidate
					hasLatestCursorFloat = true
					hasLatestCursor = true
				}
			}
			if hasCursorCandidateTime {
				if !hasLatestCursorTime || cursorCandidateTime.After(latestCursorTime) {
					latestCursorTime = cursorCandidateTime
					latestCursorValue = cursorCandidateTime.UTC().Format(time.RFC3339Nano)
					hasLatestCursorTime = true
					hasLatestCursor = true
				}
			}
			if !hasCursorCandidateFloat && !hasCursorCandidateTime && !hasLatestCursor {
				latestCursorValue = cursorCandidate
				hasLatestCursor = true
			}
		}

		if config.CursorSource == httpPollingCursorSourceFingerprint && !hasLatestCursor {
			latestCursorValue = fingerprint
			hasLatestCursor = true
		}
	}

	if config.CursorSource == httpPollingCursorSourceResponse {
		if rawValue, valueErr := resolvePath(payload, config.CursorResponsePath); valueErr == nil {
			cursorCandidate := stringify(rawValue)
			if cursorCandidate != "" {
				cursorCandidate = strings.TrimSpace(cursorCandidate)
				if cursorCandidate != "" {
					if numericCandidate, ok := tryParseFloat(cursorCandidate); ok {
						if !hasLatestCursorFloat || numericCandidate > latestCursorFloat {
							latestCursorFloat = numericCandidate
							latestCursorValue = cursorCandidate
							hasLatestCursorFloat = true
							hasLatestCursor = true
						}
					}
					if timeCandidate, ok := tryParseTime(cursorCandidate); ok {
						if !hasLatestCursorTime || timeCandidate.After(latestCursorTime) {
							latestCursorTime = timeCandidate
							latestCursorValue = timeCandidate.UTC().Format(time.RFC3339Nano)
							hasLatestCursorTime = true
							hasLatestCursor = true
						}
					}
					if !hasLatestCursor && !hasLatestCursorFloat && !hasLatestCursorTime {
						latestCursorValue = cursorCandidate
						hasLatestCursor = true
					}
				}
			}
		}
	}

	if hasLatestCursor && strings.TrimSpace(latestCursorValue) != "" {
		assignCursorValue(result.Cursor, cursorState, config.CursorKey, latestCursorValue)
		assignCursorValue(result.Cursor, cursorState, "last_seen_name", latestCursorValue)
		h.logger.Debug("polling cursor updated",
			zap.String("component", req.Component.Name),
			zap.String("provider", req.Component.Provider.Name),
			zap.String("cursor_key", config.CursorKey),
			zap.String("cursor_value", latestCursorValue))
	}

	if hasLatestOccurredAt {
		assignCursorValue(result.Cursor, cursorState, "last_seen_ts", latestOccurredAt.UTC().Format(time.RFC3339Nano))
	} else if strings.EqualFold(req.Component.Provider.Name, "slack") && hasLatestCursor && latestCursorValue != "" {
		slackNow := formatSlackTimestamp(req.Now)
		assignCursorValue(result.Cursor, cursorState, config.CursorKey, slackNow)
		assignCursorValue(result.Cursor, cursorState, "last_seen_ts", slackNow)
	} else if strings.TrimSpace(stringify(cursorView[config.CursorKey])) == "" && config.CursorInitial != "" {
		assignCursorValue(result.Cursor, cursorState, config.CursorKey, config.CursorInitial)
	}
	assignCursorValue(result.Cursor, cursorState, "last_polled_at", req.Now.UTC().Format(time.RFC3339Nano))

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
	Auth               *httpPollingAuthConfig
	SkipRules          []httpSkipRule
}

type httpPollingAuthConfig struct {
	Kind          string
	IdentityParam string
	Provider      string
	Scopes        []string
}

type httpSkipRule struct {
	Path     []string
	Contains string
	Equals   string
}

type httpQuerySpec struct {
	Name                   string
	Template               string
	Default                string
	SkipIfEmpty            bool
	baseTemplate           string
	baseDefault            string
	templateHasPlaceholder bool
	defaultHasPlaceholder  bool
}

type httpHeaderSpec struct {
	Name                   string
	Template               string
	Default                string
	SkipIfEmpty            bool
	baseTemplate           string
	baseDefault            string
	templateHasPlaceholder bool
	defaultHasPlaceholder  bool
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

	skipRules, err := parseHTTPSkipRules(ingestion["skipItems"])
	if err != nil {
		return httpPollingConfig{}, false, fmt.Errorf("skipItems metadata invalid: %w", err)
	}
	if extra, err := parseHTTPSkipRules(configMap["skipItems"]); err != nil {
		return httpPollingConfig{}, false, fmt.Errorf("skipItems metadata invalid: %w", err)
	} else if len(extra) > 0 {
		skipRules = append(skipRules, extra...)
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
		SkipRules:          skipRules,
	}
	authRaw, hasAuth := configMap["auth"]
	if !hasAuth {
		authRaw, hasAuth = ingestion["auth"]
	}
	if hasAuth {
		authMap, err := toMapStringAny(authRaw)
		if err != nil {
			return httpPollingConfig{}, false, fmt.Errorf("auth metadata invalid: %w", err)
		}
		kind := strings.TrimSpace(strings.ToLower(stringOrDefault(authMap, "type", "")))
		if kind != "" {
			identityParam := strings.TrimSpace(stringOrDefault(authMap, "identityParam", "identityId"))
			providerName := strings.TrimSpace(stringOrDefault(authMap, "provider", component.Provider.Name))
			scopes, err := toStringSlice(authMap["scopes"])
			if err != nil {
				return httpPollingConfig{}, false, fmt.Errorf("auth metadata invalid: %w", err)
			}
			config.Auth = &httpPollingAuthConfig{
				Kind:          kind,
				IdentityParam: identityParam,
				Provider:      providerName,
				Scopes:        scopes,
			}
		}
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
		spec.baseTemplate, spec.templateHasPlaceholder = computeTemplateInfo(spec.Template)
		spec.baseDefault, spec.defaultHasPlaceholder = computeTemplateInfo(spec.Default)
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
		spec.baseTemplate, spec.templateHasPlaceholder = computeTemplateInfo(spec.Template)
		spec.baseDefault, spec.defaultHasPlaceholder = computeTemplateInfo(spec.Default)
		result = append(result, spec)
	}
	return result, nil
}

func parseHTTPSkipRules(raw any) ([]httpSkipRule, error) {
	if raw == nil {
		return nil, nil
	}
	items, ok := raw.([]any)
	if !ok {
		return nil, fmt.Errorf("skipItems not an array")
	}
	result := make([]httpSkipRule, 0, len(items))
	for index, item := range items {
		entry, err := toMapStringAny(item)
		if err != nil {
			return nil, fmt.Errorf("skipItems[%d] invalid: %w", index, err)
		}
		pathValue, err := toString(entry["path"])
		if err != nil || strings.TrimSpace(pathValue) == "" {
			return nil, fmt.Errorf("skipItems[%d] path missing", index)
		}
		contains := strings.TrimSpace(stringOrDefault(entry, "contains", ""))
		equals := strings.TrimSpace(stringOrDefault(entry, "equals", ""))
		if contains == "" && equals == "" {
			return nil, fmt.Errorf("skipItems[%d] requires contains or equals", index)
		}
		rule := httpSkipRule{
			Path:     splitPath(pathValue),
			Contains: contains,
			Equals:   equals,
		}
		result = append(result, rule)
	}
	return result, nil
}

func toStringSlice(raw any) ([]string, error) {
	if raw == nil {
		return nil, nil
	}
	switch values := raw.(type) {
	case []string:
		out := make([]string, 0, len(values))
		for _, item := range values {
			if trimmed := strings.TrimSpace(item); trimmed != "" {
				out = append(out, trimmed)
			}
		}
		return out, nil
	case []any:
		out := make([]string, 0, len(values))
		for _, item := range values {
			str, err := toString(item)
			if err != nil {
				return nil, err
			}
			if trimmed := strings.TrimSpace(str); trimmed != "" {
				out = append(out, trimmed)
			}
		}
		return out, nil
	case string:
		trimmed := strings.TrimSpace(values)
		if trimmed == "" {
			return nil, nil
		}
		parts := strings.Split(trimmed, ",")
		out := make([]string, 0, len(parts))
		for _, part := range parts {
			if candidate := strings.TrimSpace(part); candidate != "" {
				out = append(out, candidate)
			}
		}
		return out, nil
	default:
		return nil, fmt.Errorf("unexpected type %T for string slice", raw)
	}
}

func selectTemplate(values map[string]any) string {
	if value, err := toString(values["template"]); err == nil {
		return value
	}
	return ""
}

func computeTemplateInfo(template string) (string, bool) {
	if strings.TrimSpace(template) == "" {
		return "", false
	}
	hasPlaceholder := placeholderPattern.MatchString(template)
	base := strings.TrimSpace(placeholderPattern.ReplaceAllString(template, ""))
	return base, hasPlaceholder
}

func shouldTreatAsEmpty(value string, hasPlaceholder bool, base string) bool {
	trimmed := strings.TrimSpace(value)
	if trimmed == "" {
		return true
	}
	if hasPlaceholder && trimmed == base {
		return true
	}
	return false
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

func (h *HTTPPollingHandler) injectIdentity(ctx context.Context, req *PollingRequest, config httpPollingConfig) error {
	if config.Auth == nil || !strings.EqualFold(config.Auth.Kind, "oauth") {
		return nil
	}
	if h.identities == nil {
		return fmt.Errorf("identity repository unavailable")
	}
	identityParam := strings.TrimSpace(config.Auth.IdentityParam)
	if identityParam == "" {
		identityParam = "identityId"
	}
	rawValue, ok := req.Binding.Config.Params[identityParam]
	if !ok {
		return fmt.Errorf("identity param %q missing", identityParam)
	}
	identityStr, err := toString(rawValue)
	if err != nil {
		return fmt.Errorf("identity param %q invalid: %w", identityParam, err)
	}
	identityStr = strings.TrimSpace(identityStr)
	if identityStr == "" {
		return fmt.Errorf("identity param %q empty", identityParam)
	}
	identityID, err := uuid.Parse(identityStr)
	if err != nil {
		return fmt.Errorf("identity param %q parse: %w", identityParam, err)
	}
	identity, err := h.identities.FindByID(ctx, identityID)
	if err != nil {
		return fmt.Errorf("identity lookup: %w", err)
	}
	if identity.UserID != req.Binding.UserID {
		return fmt.Errorf("identity not owned by user")
	}
	providerName := strings.TrimSpace(config.Auth.Provider)
	if providerName == "" {
		providerName = identity.Provider
	}
	updatedIdentity, token, err := h.ensureIdentityAccessToken(ctx, identity, providerName)
	if err != nil {
		return err
	}
	req.Identity = map[string]any{
		"id":          updatedIdentity.ID.String(),
		"accessToken": token,
		"provider":    updatedIdentity.Provider,
		"scopes":      cloneStrings(updatedIdentity.Scopes),
	}
	if updatedIdentity.ExpiresAt != nil {
		req.Identity["expiresAt"] = updatedIdentity.ExpiresAt.UTC().Format(time.RFC3339Nano)
	}
	req.Binding.Config.Params[identityParam] = updatedIdentity.ID.String()
	return nil
}

func (h *HTTPPollingHandler) ensureIdentityAccessToken(ctx context.Context, identity identitydomain.Identity, providerName string) (identitydomain.Identity, string, error) {
	token := strings.TrimSpace(identity.AccessToken)
	if token != "" && !identity.TokenExpired(time.Now().UTC()) {
		return identity, token, nil
	}
	if h.providers == nil {
		return identity, "", fmt.Errorf("oauth provider resolver unavailable")
	}
	providerKey := strings.TrimSpace(strings.ToLower(providerName))
	if providerKey == "" {
		providerKey = strings.TrimSpace(strings.ToLower(identity.Provider))
	}
	if providerKey == "" {
		return identity, "", fmt.Errorf("oauth provider missing")
	}
	provider, ok := h.providers.Provider(providerKey)
	if !ok {
		return identity, "", fmt.Errorf("oauth provider %s not configured", providerKey)
	}
	exchange, err := provider.Refresh(ctx, identity)
	if err != nil {
		return identity, "", fmt.Errorf("refresh token: %w", err)
	}
	refreshToken := exchange.Token.RefreshToken
	if refreshToken == "" {
		refreshToken = identity.RefreshToken
	}
	expiresAt := identity.ExpiresAt
	if !exchange.Token.ExpiresAt.IsZero() {
		expires := exchange.Token.ExpiresAt.UTC()
		expiresAt = &expires
	}
	scopes := exchange.Token.Scope
	if len(scopes) == 0 {
		scopes = identity.Scopes
	}
	updated := identity.WithTokens(exchange.Token.AccessToken, refreshToken, expiresAt, scopes)
	updated.UpdatedAt = time.Now().UTC()
	if err := h.identities.Update(ctx, updated); err != nil {
		return identity, "", fmt.Errorf("update identity: %w", err)
	}
	return updated, updated.AccessToken, nil
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
		case "identity":
			if req.Identity == nil {
				return ""
			}
			return stringify(req.Identity[submatches[2]])
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

func shouldSkipItem(item map[string]any, rules []httpSkipRule) bool {
	if len(rules) == 0 {
		return false
	}
	for _, rule := range rules {
		if len(rule.Path) == 0 {
			continue
		}
		value, err := resolvePath(item, rule.Path)
		if err != nil {
			continue
		}
		text := strings.TrimSpace(stringify(value))
		if text == "" {
			continue
		}
		if rule.Equals != "" && strings.EqualFold(text, rule.Equals) {
			return true
		}
		if rule.Contains != "" {
			lowerText := strings.ToLower(text)
			if strings.Contains(lowerText, strings.ToLower(rule.Contains)) {
				return true
			}
		}
	}
	return false
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

func flattenCursorState(cursor map[string]any) map[string]any {
	if len(cursor) == 0 {
		return nil
	}
	flattened := make(map[string]any, len(cursor))
	if rawState, ok := cursor["state"]; ok {
		switch state := rawState.(type) {
		case map[string]any:
			for key, value := range state {
				flattened[key] = value
			}
		case map[any]any:
			for key, value := range state {
				if keyStr, ok := key.(string); ok {
					flattened[keyStr] = value
				}
			}
		}
	}
	for key, value := range cursor {
		if key == "state" {
			continue
		}
		flattened[key] = value
	}
	if len(flattened) == 0 {
		return nil
	}
	return flattened
}

func ensureCursorState(cursor map[string]any) map[string]any {
	if cursor == nil {
		return nil
	}
	if rawState, ok := cursor["state"]; ok {
		switch state := rawState.(type) {
		case map[string]any:
			return state
		case map[any]any:
			converted := make(map[string]any, len(state))
			for key, value := range state {
				if keyStr, ok := key.(string); ok {
					converted[keyStr] = value
				}
			}
			cursor["state"] = converted
			return converted
		}
	}
	state := map[string]any{}
	cursor["state"] = state
	return state
}

func assignCursorValue(cursor map[string]any, state map[string]any, key string, value any) {
	if strings.TrimSpace(key) == "" {
		return
	}
	if cursor != nil {
		cursor[key] = value
	}
	if state != nil {
		state[key] = value
	}
}

func formatSlackTimestamp(t time.Time) string {
	seconds := float64(t.UTC().UnixNano()) / 1e9
	return fmt.Sprintf("%.6f", seconds)
}

func cloneStrings(values []string) []string {
	if len(values) == 0 {
		return nil
	}
	out := make([]string, len(values))
	copy(out, values)
	return out
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

func tryParseFloat(value string) (float64, bool) {
	if parsed, err := strconv.ParseFloat(value, 64); err == nil {
		return parsed, true
	}
	return 0, false
}

func tryParseTime(value string) (time.Time, bool) {
	parsed, err := parseTime(value)
	if err != nil || parsed.IsZero() {
		return time.Time{}, false
	}
	return parsed.UTC(), true
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

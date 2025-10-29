package oauth2

import (
	"bytes"
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"
)

// Config describes an OAuth2 provider endpoints and credentials
// TokenURL must accept application/x-www-form-urlencoded requests
// AuthURL is the authorization endpoint used to initiate the code flow
type Config struct {
	Name            string
	ClientID        string
	ClientSecret    string
	AuthURL         string
	TokenURL        string
	UserInfoURL     string
	Scopes          []string
	Prompt          string
	Audience        string
	TokenAuthMethod string
	TokenFormat     string
	TokenHeaders    map[string]string
}

// AuthorizationRequest configures the authorization redirect
// Extra parameters are appended to the query string as-is
type AuthorizationRequest struct {
	RedirectURI         string
	Scopes              []string
	State               string
	Prompt              string
	PKCE                bool
	CodeVerifier        string
	CodeChallengeMethod CodeChallengeMethod
	Extra               map[string]string
}

// AuthorizationResult captures the redirect data for a user agent
// CodeVerifier and CodeChallenge are empty when PKCE is disabled
type AuthorizationResult struct {
	URL                 string
	State               string
	CodeVerifier        string
	CodeChallenge       string
	CodeChallengeMethod CodeChallengeMethod
}

// ExchangeRequest wraps contextual parameters for token exchanges
type ExchangeRequest struct {
	Code         string
	RedirectURI  string
	CodeVerifier string
	Extra        map[string]string
}

// RefreshRequest carries inputs required to refresh an access token
type RefreshRequest struct {
	RefreshToken string
	Scopes       []string
	Extra        map[string]string
}

// HTTPClient is the subset of http.Client used by the OAuth client
type HTTPClient interface {
	Do(req *http.Request) (*http.Response, error)
}

// Clock provides the current time to support testing
type Clock interface {
	Now() time.Time
}

type systemClock struct{}

func (systemClock) Now() time.Time { return time.Now().UTC() }

// Client implements core OAuth2 flows without external dependencies
type Client struct {
	cfg         Config
	httpClient  HTTPClient
	clock       Clock
	stateSize   int
	verifierLen int
}

// Option customizes the OAuth client construction
// Options are applied in order
// They should be idempotent to simplify reuse
type Option func(*Client)

// WithHTTPClient overrides the default http.Client
func WithHTTPClient(client HTTPClient) Option {
	return func(c *Client) {
		if client != nil {
			c.httpClient = client
		}
	}
}

// WithClock injects a custom time source
func WithClock(clock Clock) Option {
	return func(c *Client) {
		if clock != nil {
			c.clock = clock
		}
	}
}

// WithStateSize updates the random state length used when generating new values
func WithStateSize(size int) Option {
	return func(c *Client) {
		if size > 0 {
			c.stateSize = size
		}
	}
}

// WithVerifierLength overrides the generated PKCE verifier size
func WithVerifierLength(length int) Option {
	return func(c *Client) {
		if length >= pkceMinLength && length <= pkceMaxLength {
			c.verifierLen = length
		}
	}
}

// NewClient constructs an OAuth2 client from configuration and options
func NewClient(cfg Config, opts ...Option) (*Client, error) {
	if strings.TrimSpace(cfg.ClientID) == "" {
		return nil, fmt.Errorf("oauth2.NewClient: client id is required")
	}
	if strings.TrimSpace(cfg.AuthURL) == "" {
		return nil, fmt.Errorf("oauth2.NewClient: auth url is required")
	}
	if strings.TrimSpace(cfg.TokenURL) == "" {
		return nil, fmt.Errorf("oauth2.NewClient: token url is required")
	}

	client := &Client{
		cfg:         cfg,
		httpClient:  http.DefaultClient,
		clock:       systemClock{},
		stateSize:   32,
		verifierLen: 64,
	}

	for _, opt := range opts {
		if opt != nil {
			opt(client)
		}
	}

	return client, nil
}

// AuthorizationURL builds the URL to redirect a user to the OAuth provider
func (c *Client) AuthorizationURL(ctx context.Context, req AuthorizationRequest) (AuthorizationResult, error) {
	if err := ctx.Err(); err != nil {
		return AuthorizationResult{}, fmt.Errorf("oauth2.Client.AuthorizationURL: context error: %w", err)
	}
	redirect := strings.TrimSpace(req.RedirectURI)
	if redirect == "" {
		return AuthorizationResult{}, fmt.Errorf("oauth2.Client.AuthorizationURL: redirect uri is required")
	}

	state := strings.TrimSpace(req.State)
	if state == "" {
		generated, err := GenerateState(c.stateSize)
		if err != nil {
			return AuthorizationResult{}, fmt.Errorf("oauth2.Client.AuthorizationURL: generate state: %w", err)
		}
		state = generated
	}

	scopes := req.Scopes
	if len(scopes) == 0 {
		scopes = c.cfg.Scopes
	}

	prompt := strings.TrimSpace(req.Prompt)
	if prompt == "" {
		prompt = c.cfg.Prompt
	}

	usePKCE := req.PKCE || req.CodeVerifier != ""
	method := req.CodeChallengeMethod
	if method == "" {
		method = CodeChallengeMethodS256
	}
	if usePKCE && !method.Valid() {
		return AuthorizationResult{}, fmt.Errorf("oauth2.Client.AuthorizationURL: invalid code challenge method %q", method)
	}

	verifier := strings.TrimSpace(req.CodeVerifier)
	challenge := ""
	if usePKCE {
		var err error
		if verifier == "" {
			verifier, err = GenerateCodeVerifier(c.verifierLen)
			if err != nil {
				return AuthorizationResult{}, fmt.Errorf("oauth2.Client.AuthorizationURL: generate verifier: %w", err)
			}
		}
		challenge, err = DeriveCodeChallenge(verifier, method)
		if err != nil {
			return AuthorizationResult{}, fmt.Errorf("oauth2.Client.AuthorizationURL: derive challenge: %w", err)
		}
	}

	authURL, err := url.Parse(c.cfg.AuthURL)
	if err != nil {
		return AuthorizationResult{}, fmt.Errorf("oauth2.Client.AuthorizationURL: parse auth url: %w", err)
	}

	query := authURL.Query()
	query.Set("response_type", "code")
	query.Set("client_id", c.cfg.ClientID)
	query.Set("redirect_uri", redirect)
	query.Set("state", state)
	if len(scopes) > 0 {
		query.Set("scope", strings.Join(scopes, " "))
	}
	if prompt != "" {
		query.Set("prompt", prompt)
	}
	if c.cfg.Audience != "" {
		query.Set("audience", c.cfg.Audience)
	}
	if usePKCE {
		query.Set("code_challenge", challenge)
		query.Set("code_challenge_method", string(method))
	}
	for key, value := range req.Extra {
		if strings.TrimSpace(key) == "" || value == "" {
			continue
		}
		query.Set(key, value)
	}
	authURL.RawQuery = query.Encode()

	resultMethod := CodeChallengeMethod("")
	if usePKCE {
		resultMethod = method
	}

	return AuthorizationResult{
		URL:                 authURL.String(),
		State:               state,
		CodeVerifier:        verifier,
		CodeChallenge:       challenge,
		CodeChallengeMethod: resultMethod,
	}, nil
}

// Exchange swaps an authorization code for access credentials
func (c *Client) Exchange(ctx context.Context, req ExchangeRequest) (Token, error) {
	if err := ctx.Err(); err != nil {
		return Token{}, fmt.Errorf("oauth2.Client.Exchange: context error: %w", err)
	}
	if strings.TrimSpace(req.Code) == "" {
		return Token{}, fmt.Errorf("oauth2.Client.Exchange: code is required")
	}
	redirect := strings.TrimSpace(req.RedirectURI)
	if redirect == "" {
		return Token{}, fmt.Errorf("oauth2.Client.Exchange: redirect uri is required")
	}

	values := url.Values{}
	values.Set("grant_type", "authorization_code")
	values.Set("code", req.Code)
	values.Set("redirect_uri", redirect)
	if !strings.EqualFold(c.cfg.TokenAuthMethod, "basic") {
		values.Set("client_id", c.cfg.ClientID)
		if c.cfg.ClientSecret != "" {
			values.Set("client_secret", c.cfg.ClientSecret)
		}
	}
	if req.CodeVerifier != "" {
		values.Set("code_verifier", req.CodeVerifier)
	}
	for key, value := range req.Extra {
		if strings.TrimSpace(key) == "" || value == "" {
			continue
		}
		values.Set(key, value)
	}

	return c.doTokenRequest(ctx, values)
}

// Refresh requests a new access token using a refresh token
func (c *Client) Refresh(ctx context.Context, req RefreshRequest) (Token, error) {
	if err := ctx.Err(); err != nil {
		return Token{}, fmt.Errorf("oauth2.Client.Refresh: context error: %w", err)
	}
	if strings.TrimSpace(req.RefreshToken) == "" {
		return Token{}, fmt.Errorf("oauth2.Client.Refresh: refresh token is required")
	}

	values := url.Values{}
	values.Set("grant_type", "refresh_token")
	values.Set("refresh_token", req.RefreshToken)
	if !strings.EqualFold(c.cfg.TokenAuthMethod, "basic") {
		values.Set("client_id", c.cfg.ClientID)
		if c.cfg.ClientSecret != "" {
			values.Set("client_secret", c.cfg.ClientSecret)
		}
	}
	if len(req.Scopes) > 0 {
		values.Set("scope", strings.Join(req.Scopes, " "))
	}
	for key, value := range req.Extra {
		if strings.TrimSpace(key) == "" || value == "" {
			continue
		}
		values.Set(key, value)
	}

	return c.doTokenRequest(ctx, values)
}

func (c *Client) doTokenRequest(ctx context.Context, values url.Values) (Token, error) {
	bodyReader, contentType, err := c.buildTokenRequestBody(values)
	if err != nil {
		return Token{}, err
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.cfg.TokenURL, bodyReader)
	if err != nil {
		return Token{}, fmt.Errorf("oauth2.Client.doTokenRequest: new request: %w", err)
	}
	req.Header.Set("Content-Type", contentType)
	req.Header.Set("Accept", "application/json")
	for key, value := range c.cfg.TokenHeaders {
		if strings.TrimSpace(key) == "" || strings.TrimSpace(value) == "" {
			continue
		}
		req.Header.Set(key, value)
	}
	if strings.EqualFold(c.cfg.TokenAuthMethod, "basic") {
		secret := fmt.Sprintf("%s:%s", c.cfg.ClientID, c.cfg.ClientSecret)
		encoded := base64.StdEncoding.EncodeToString([]byte(secret))
		req.Header.Set("Authorization", "Basic "+encoded)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return Token{}, fmt.Errorf("oauth2.Client.doTokenRequest: http do: %w", err)
	}
	defer func() {
		_ = resp.Body.Close()
	}()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return Token{}, fmt.Errorf("oauth2.Client.doTokenRequest: read body: %w", err)
	}

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return Token{}, c.parseError(body, resp.StatusCode)
	}

	return c.parseToken(body)
}

func (c *Client) parseToken(body []byte) (Token, error) {
	var payload tokenPayload
	if err := json.Unmarshal(body, &payload); err != nil {
		return Token{}, fmt.Errorf("oauth2.Client.parseToken: decode payload: %w", err)
	}

	var raw map[string]any
	if err := json.Unmarshal(body, &raw); err != nil {
		return Token{}, fmt.Errorf("oauth2.Client.parseToken: decode raw: %w", err)
	}

	expiresAt := time.Time{}
	if payload.ExpiresAt.Int64() != 0 {
		expiresAt = time.Unix(payload.ExpiresAt.Int64(), 0).UTC()
	} else if payload.ExpiresIn.Int64() != 0 {
		expiresAt = c.clock.Now().Add(time.Duration(payload.ExpiresIn.Int64()) * time.Second)
	}

	scopes := make([]string, len(payload.Scope))
	copy(scopes, payload.Scope)
	if len(scopes) == 0 {
		if rawScope, ok := raw["scope"].(string); ok && rawScope != "" {
			scopes = strings.Fields(rawScope)
		}
	}

	token := Token{
		AccessToken:  payload.AccessToken,
		RefreshToken: payload.RefreshToken,
		TokenType:    payload.TokenType,
		ExpiresAt:    expiresAt,
		Scope:        scopes,
		IDToken:      payload.IDToken,
		Raw:          raw,
	}

	if token.AccessToken == "" {
		return Token{}, fmt.Errorf("oauth2.Client.parseToken: access token missing")
	}

	return token, nil
}

func (c *Client) buildTokenRequestBody(values url.Values) (io.Reader, string, error) {
	format := strings.ToLower(strings.TrimSpace(c.cfg.TokenFormat))
	if format == "" || format == "form" {
		return strings.NewReader(values.Encode()), "application/x-www-form-urlencoded", nil
	}

	if format != "json" {
		return nil, "", fmt.Errorf("oauth2.Client.doTokenRequest: unsupported token format %q", c.cfg.TokenFormat)
	}

	payload := make(map[string]any, len(values))
	for key, vals := range values {
		if len(vals) == 0 {
			continue
		}
		if len(vals) == 1 {
			payload[key] = vals[0]
			continue
		}
		payload[key] = append([]string(nil), vals...)
	}

	bodyBytes, err := json.Marshal(payload)
	if err != nil {
		return nil, "", fmt.Errorf("oauth2.Client.doTokenRequest: marshal payload: %w", err)
	}
	return bytes.NewReader(bodyBytes), "application/json", nil
}

func (c *Client) parseError(body []byte, status int) error {
	var payload errorPayload
	if err := json.Unmarshal(body, &payload); err == nil && payload.Error != "" {
		return fmt.Errorf("oauth2: token endpoint error %d: %s: %s", status, payload.Error, payload.ErrorDescription)
	}

	trimmed := strings.TrimSpace(string(body))
	if trimmed == "" {
		trimmed = http.StatusText(status)
	}
	return fmt.Errorf("oauth2: token endpoint error %d: %s", status, trimmed)
}

type tokenPayload struct {
	AccessToken  string       `json:"access_token"`
	TokenType    string       `json:"token_type"`
	RefreshToken string       `json:"refresh_token"`
	ExpiresIn    numericValue `json:"expires_in"`
	ExpiresAt    numericValue `json:"expires_at"`
	Scope        scopeValue   `json:"scope"`
	IDToken      string       `json:"id_token"`
}

type errorPayload struct {
	Error            string `json:"error"`
	ErrorDescription string `json:"error_description"`
}

type numericValue struct {
	value int64
}

func (n *numericValue) UnmarshalJSON(data []byte) error {
	data = bytes.TrimSpace(data)
	if len(data) == 0 || bytes.Equal(data, []byte("null")) {
		n.value = 0
		return nil
	}

	if data[0] == '"' {
		var str string
		if err := json.Unmarshal(data, &str); err != nil {
			return err
		}
		str = strings.TrimSpace(str)
		if str == "" {
			n.value = 0
			return nil
		}
		parsed, err := strconv.ParseFloat(str, 64)
		if err != nil {
			return err
		}
		n.value = int64(parsed)
		return nil
	}

	var num json.Number
	if err := json.Unmarshal(data, &num); err != nil {
		return err
	}
	parsed, err := num.Int64()
	if err != nil {
		floatVal, ferr := num.Float64()
		if ferr != nil {
			return ferr
		}
		n.value = int64(floatVal)
		return nil
	}
	n.value = parsed
	return nil
}

func (n numericValue) Int64() int64 {
	return n.value
}

type scopeValue []string

func (s *scopeValue) UnmarshalJSON(data []byte) error {
	data = bytes.TrimSpace(data)
	if len(data) == 0 || bytes.Equal(data, []byte("null")) {
		return nil
	}
	if len(data) > 0 && data[0] == '[' {
		var arr []string
		if err := json.Unmarshal(data, &arr); err != nil {
			return err
		}
		*s = arr
		return nil
	}
	var str string
	if err := json.Unmarshal(data, &str); err != nil {
		return err
	}
	str = strings.TrimSpace(str)
	if str == "" {
		*s = nil
		return nil
	}
	*s = strings.Fields(str)
	return nil
}

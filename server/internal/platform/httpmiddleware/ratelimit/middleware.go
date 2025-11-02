package ratelimit

import (
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

// Config defines rate limiting thresholds applied by the middleware
type Config struct {
	Enabled                bool
	BaseRequestsPerMinute  int
	BurstRequestsPerMinute int
	BurstWindow            time.Duration
	SessionCookieName      string
	IdleTTL                time.Duration
	ApplyToAnonymous       bool
}

// Clock abstracts time retrieval for deterministic testing
type Clock interface {
	Now() time.Time
}

// Option configures middleware construction
type Option func(*Middleware)

// WithLogger overrides the zap logger used for diagnostics
func WithLogger(logger *zap.Logger) Option {
	return func(m *Middleware) {
		if logger != nil {
			m.logger = logger
		}
	}
}

// WithClock injects a custom clock implementation
func WithClock(clock Clock) Option {
	return func(m *Middleware) {
		if clock != nil {
			m.clock = clock
		}
	}
}

// Middleware enforces per-identifier rate limits with burst tolerance
type Middleware struct {
	cfg    Config
	logger *zap.Logger
	clock  Clock
	store  *limiterStore
}

// New constructs a Middleware based on the provided configuration
func New(cfg Config, opts ...Option) (*Middleware, error) {
	if !cfg.Enabled {
		cfg.Enabled = false
	}
	if cfg.BaseRequestsPerMinute < 0 {
		return nil, fmt.Errorf("ratelimit: base requests per minute cannot be negative")
	}
	if cfg.Enabled && cfg.BaseRequestsPerMinute == 0 {
		return nil, fmt.Errorf("ratelimit: base requests per minute must be positive")
	}
	if cfg.BurstRequestsPerMinute < 0 {
		return nil, fmt.Errorf("ratelimit: burst requests per minute cannot be negative")
	}
	if cfg.Enabled && cfg.BurstRequestsPerMinute == 0 {
		cfg.BurstRequestsPerMinute = cfg.BaseRequestsPerMinute
	}
	if cfg.Enabled && cfg.BurstRequestsPerMinute < cfg.BaseRequestsPerMinute {
		cfg.BurstRequestsPerMinute = cfg.BaseRequestsPerMinute
	}
	if cfg.BurstWindow < 0 {
		return nil, fmt.Errorf("ratelimit: burst window cannot be negative")
	}
	if cfg.SessionCookieName == "" {
		return nil, fmt.Errorf("ratelimit: session cookie name is required")
	}
	if cfg.IdleTTL < 0 {
		return nil, fmt.Errorf("ratelimit: idle TTL cannot be negative")
	}
	if cfg.IdleTTL == 0 {
		cfg.IdleTTL = 15 * time.Minute
	}

	m := &Middleware{
		cfg:    cfg,
		logger: zap.L(),
		clock:  systemClock{},
	}

	for _, opt := range opts {
		opt(m)
	}
	if m.logger == nil {
		m.logger = zap.NewNop()
	}
	if m.clock == nil {
		m.clock = systemClock{}
	}

	m.store = newLimiterStore(cfg.IdleTTL, func(now time.Time) *sessionLimiter {
		return newSessionLimiter(cfg, now)
	})

	return m, nil
}

// Handler returns the gin middleware enforcing the configured limits
func (m *Middleware) Handler() gin.HandlerFunc {
	if !m.cfg.Enabled {
		return func(c *gin.Context) {
			c.Next()
		}
	}

	return func(c *gin.Context) {
		now := m.clock.Now()
		key := m.identifier(c)
		if key == "" {
			c.Next()
			return
		}

		limiter := m.store.get(key, now)
		allowed, retryAfter := limiter.allow(now)
		if allowed {
			c.Next()
			return
		}

		if retryAfter <= 0 {
			retryAfter = time.Second
		}
		seconds := int((retryAfter + time.Second - 1) / time.Second)
		if seconds < 1 {
			seconds = 1
		}
		c.Header("Retry-After", strconv.Itoa(seconds))
		c.AbortWithStatusJSON(http.StatusTooManyRequests, gin.H{
			"error": "rate limit exceeded",
		})

		m.logger.Warn("rate limit exceeded",
			zap.String("key", key),
			zap.Int("retry_after_seconds", seconds),
			zap.String("path", c.FullPath()),
			zap.String("method", c.Request.Method),
		)
	}
}

func (m *Middleware) identifier(c *gin.Context) string {
	value, err := c.Cookie(m.cfg.SessionCookieName)
	if err == nil {
		value = strings.TrimSpace(value)
		if value != "" {
			return "session:" + value
		}
	}

	if !m.cfg.ApplyToAnonymous {
		return ""
	}

	ip := strings.TrimSpace(c.ClientIP())
	if ip == "" {
		return ""
	}
	return "anon:" + ip
}

type systemClock struct{}

func (systemClock) Now() time.Time {
	return time.Now()
}

package ratelimit

import (
	"net/http"
	"net/http/httptest"
	"sync"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

func TestSessionLimiter_AllowsBurstWithinWindow(t *testing.T) {
	cfg := Config{
		Enabled:                true,
		BaseRequestsPerMinute:  120,
		BurstRequestsPerMinute: 300,
		BurstWindow:            30 * time.Second,
	}
	now := time.Unix(0, 0).UTC()
	limiter := newSessionLimiter(cfg, now)

	current := now
	for sec := 0; sec < 30; sec++ {
		for i := 0; i < 5; i++ {
			allowed, _ := limiter.allow(current)
			if !allowed {
				t.Fatalf("expected burst allowance at second %d request %d", sec, i)
			}
		}
		current = current.Add(time.Second)
	}

	if allowed, _ := limiter.allow(current); allowed {
		t.Fatalf("expected limiter to reject once burst window elapsed")
	}
}

func TestSessionLimiter_RecoversAfterCooldown(t *testing.T) {
	cfg := Config{
		Enabled:                true,
		BaseRequestsPerMinute:  120,
		BurstRequestsPerMinute: 300,
		BurstWindow:            30 * time.Second,
	}
	start := time.Unix(0, 0).UTC()
	limiter := newSessionLimiter(cfg, start)

	current := start
	for sec := 0; sec < 30; sec++ {
		for i := 0; i < 5; i++ {
			if allowed, _ := limiter.allow(current); !allowed {
				t.Fatalf("expected request %d at second %d to be allowed", i, sec)
			}
		}
		current = current.Add(time.Second)
	}

	if allowed, _ := limiter.allow(current); allowed {
		t.Fatalf("expected limiter to reject after sustained burst")
	}

	cooldown := current.Add(40 * time.Second)
	if allowed, _ := limiter.allow(cooldown); !allowed {
		t.Fatalf("expected limiter to recover after cooldown")
	}

	if allowed, _ := limiter.allow(cooldown); !allowed {
		t.Fatalf("expected base rate to allow second request post-cooldown")
	}

	if allowed, _ := limiter.allow(cooldown); !allowed {
		t.Fatalf("expected burst to reactivate after cooldown")
	}
}

func TestMiddleware_ThrottleAuthenticatedSession(t *testing.T) {
	gin.SetMode(gin.TestMode)

	cfg := Config{
		Enabled:                true,
		BaseRequestsPerMinute:  120,
		BurstRequestsPerMinute: 300,
		BurstWindow:            30 * time.Second,
		SessionCookieName:      "area_session",
		IdleTTL:                time.Minute,
	}
	start := time.Unix(0, 0).UTC()
	clock := newStubClock(start)

	mw, err := New(cfg, WithClock(clock), WithLogger(zap.NewNop()))
	if err != nil {
		t.Fatalf("expected middleware construction to succeed: %v", err)
	}

	router := gin.New()
	router.Use(mw.Handler())
	router.GET("/", func(c *gin.Context) {
		c.Status(http.StatusOK)
	})

	current := start
	for sec := 0; sec < 30; sec++ {
		clock.Set(current)
		for i := 0; i < 5; i++ {
			req := httptest.NewRequest(http.MethodGet, "/", nil)
			req.AddCookie(&http.Cookie{Name: "area_session", Value: "session-1"})
			resp := httptest.NewRecorder()
			router.ServeHTTP(resp, req)
			if resp.Code != http.StatusOK {
				t.Fatalf("expected status 200 during burst, got %d", resp.Code)
			}
		}
		current = current.Add(time.Second)
	}

	clock.Set(current)
	req := httptest.NewRequest(http.MethodGet, "/", nil)
	req.AddCookie(&http.Cookie{Name: "area_session", Value: "session-1"})
	resp := httptest.NewRecorder()
	router.ServeHTTP(resp, req)
	if resp.Code != http.StatusTooManyRequests {
		t.Fatalf("expected 429 after burst window, got %d", resp.Code)
	}
	if header := resp.Header().Get("Retry-After"); header == "" {
		t.Fatalf("expected Retry-After header to be set")
	}
}

func TestMiddleware_SkipsWithoutSession(t *testing.T) {
	gin.SetMode(gin.TestMode)

	cfg := Config{
		Enabled:                true,
		BaseRequestsPerMinute:  120,
		BurstRequestsPerMinute: 300,
		BurstWindow:            30 * time.Second,
		SessionCookieName:      "area_session",
		IdleTTL:                time.Minute,
	}

	mw, err := New(cfg, WithClock(newStubClock(time.Unix(0, 0).UTC())), WithLogger(zap.NewNop()))
	if err != nil {
		t.Fatalf("expected middleware construction to succeed: %v", err)
	}

	router := gin.New()
	router.Use(mw.Handler())
	router.GET("/", func(c *gin.Context) {
		c.Status(http.StatusOK)
	})

	req := httptest.NewRequest(http.MethodGet, "/", nil)
	resp := httptest.NewRecorder()
	router.ServeHTTP(resp, req)

	if resp.Code != http.StatusOK {
		t.Fatalf("expected anonymous request to pass, got %d", resp.Code)
	}
}

type stubClock struct {
	mu  sync.Mutex
	now time.Time
}

func newStubClock(start time.Time) *stubClock {
	return &stubClock{now: start}
}

func (s *stubClock) Now() time.Time {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.now
}

func (s *stubClock) Set(t time.Time) {
	s.mu.Lock()
	s.now = t
	s.mu.Unlock()
}

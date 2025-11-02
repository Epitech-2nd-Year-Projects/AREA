package ratelimit

import (
	"math"
	"sync"
	"time"
)

type sessionLimiter struct {
	base        *tokenBucket
	burst       *tokenBucket
	burstStart  time.Time
	burstWindow time.Duration
	lastSeen    time.Time
	mu          sync.Mutex
}

func newSessionLimiter(cfg Config, now time.Time) *sessionLimiter {
	baseRate := float64(cfg.BaseRequestsPerMinute)
	if baseRate <= 0 {
		baseRate = 60
	}
	base := newTokenBucket(baseRate/60.0, math.Max(1, math.Ceil(baseRate/60.0)), now)

	var burst *tokenBucket
	if cfg.BurstWindow > 0 && cfg.BurstRequestsPerMinute > cfg.BaseRequestsPerMinute {
		burstRate := float64(cfg.BurstRequestsPerMinute)
		if burstRate <= 0 {
			burstRate = baseRate
		}
		burst = newTokenBucket(burstRate/60.0, math.Max(1, math.Ceil(burstRate/60.0)), now)
	}

	return &sessionLimiter{
		base:        base,
		burst:       burst,
		burstWindow: cfg.BurstWindow,
		lastSeen:    now,
	}
}

func (l *sessionLimiter) allow(now time.Time) (bool, time.Duration) {
	l.mu.Lock()
	defer l.mu.Unlock()

	l.lastSeen = now

	if l.base.allow(now) {
		l.burstStart = time.Time{}
		return true, 0
	}

	if l.burst == nil || l.burstWindow <= 0 {
		return false, l.nextRetry(now)
	}

	if !l.burstStart.IsZero() && now.Sub(l.burstStart) >= l.burstWindow {
		return false, l.nextRetry(now)
	}

	if l.burst.allow(now) {
		if l.burstStart.IsZero() {
			l.burstStart = now
		}
		return true, 0
	}

	return false, l.nextRetry(now)
}

func (l *sessionLimiter) nextRetry(now time.Time) time.Duration {
	delay := l.base.delay(now)
	if delay <= 0 {
		return time.Second
	}
	return delay
}

type tokenBucket struct {
	rate       float64
	capacity   float64
	tokens     float64
	lastRefill time.Time
}

func newTokenBucket(rate float64, capacity float64, now time.Time) *tokenBucket {
	if rate <= 0 {
		rate = 1
	}
	if capacity < 1 {
		capacity = 1
	}
	return &tokenBucket{
		rate:       rate,
		capacity:   capacity,
		tokens:     capacity,
		lastRefill: now,
	}
}

func (b *tokenBucket) allow(now time.Time) bool {
	b.refill(now)
	if b.tokens >= 1 {
		b.tokens--
		return true
	}
	return false
}

func (b *tokenBucket) delay(now time.Time) time.Duration {
	b.refill(now)
	if b.tokens >= 1 {
		return 0
	}
	needed := 1 - b.tokens
	if needed <= 0 {
		return 0
	}
	seconds := needed / b.rate
	if seconds <= 0 {
		return 0
	}
	return time.Duration(math.Ceil(seconds * float64(time.Second)))
}

func (b *tokenBucket) refill(now time.Time) {
	if now.Before(b.lastRefill) {
		return
	}
	elapsed := now.Sub(b.lastRefill).Seconds()
	if elapsed <= 0 {
		return
	}
	b.tokens += elapsed * b.rate
	if b.tokens > b.capacity {
		b.tokens = b.capacity
	}
	b.lastRefill = now
}

type limiterStore struct {
	mu        sync.Mutex
	items     map[string]*sessionLimiter
	ttl       time.Duration
	lastSweep time.Time
	factory   func(time.Time) *sessionLimiter
}

func newLimiterStore(ttl time.Duration, factory func(time.Time) *sessionLimiter) *limiterStore {
	return &limiterStore{
		items:   make(map[string]*sessionLimiter),
		ttl:     ttl,
		factory: factory,
	}
}

func (s *limiterStore) get(key string, now time.Time) *sessionLimiter {
	s.mu.Lock()
	defer s.mu.Unlock()

	if s.ttl > 0 && (s.lastSweep.IsZero() || now.Sub(s.lastSweep) > s.ttl) {
		s.evictLocked(now)
		s.lastSweep = now
	}

	limiter, ok := s.items[key]
	if !ok {
		limiter = s.factory(now)
		s.items[key] = limiter
	}
	return limiter
}

func (s *limiterStore) evictLocked(now time.Time) {
	for key, limiter := range s.items {
		limiter.mu.Lock()
		lastSeen := limiter.lastSeen
		limiter.mu.Unlock()
		if now.Sub(lastSeen) > s.ttl {
			delete(s.items, key)
		}
	}
}

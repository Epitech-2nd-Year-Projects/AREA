package area

import (
	"strings"
	"time"

	componentdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/component"
	"github.com/google/uuid"
)

// LinkRole describes how a component participates in an AREA
type LinkRole string

const (
	// LinkRoleAction identifies the trigger component of an automation
	LinkRoleAction LinkRole = "action"
	// LinkRoleReaction identifies a downstream reaction component
	LinkRoleReaction LinkRole = "reaction"
)

// Link binds an AREA to a configured component (action or reaction)
type Link struct {
	ID          uuid.UUID
	AreaID      uuid.UUID
	Role        LinkRole
	Position    int
	Config      componentdomain.Config
	RetryPolicy *RetryPolicy
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

// IsAction reports whether the link represents the AREA trigger
func (l Link) IsAction() bool {
	return l.Role == LinkRoleAction
}

// RetryStrategy enumerates supported retry backoff strategies
type RetryStrategy string

const (
	RetryStrategyConstant    RetryStrategy = "constant"
	RetryStrategyLinear      RetryStrategy = "linear"
	RetryStrategyExponential RetryStrategy = "exponential"
)

// RetryPolicy captures retry behaviour for a reaction link
type RetryPolicy struct {
	MaxRetries int
	Strategy   RetryStrategy
	BaseDelay  time.Duration
	MaxDelay   time.Duration
}

// ShouldRetry reports whether another attempt is allowed after the specified attempt count
func (p RetryPolicy) ShouldRetry(attempt int) bool {
	if p.MaxRetries <= 0 {
		return false
	}
	return attempt <= p.MaxRetries
}

// Delay returns the backoff duration for the provided attempt number (1-indexed)
func (p RetryPolicy) Delay(attempt int) time.Duration {
	if attempt < 1 {
		attempt = 1
	}
	base := p.BaseDelay
	if base <= 0 {
		base = time.Second
	}

	var delay time.Duration
	switch strings.ToLower(string(p.Strategy)) {
	case string(RetryStrategyLinear):
		delay = base * time.Duration(attempt)
	case string(RetryStrategyExponential):
		delay = base * time.Duration(1<<uint(attempt-1))
	default:
		delay = base
	}

	if p.MaxDelay > 0 && delay > p.MaxDelay {
		return p.MaxDelay
	}
	return delay
}

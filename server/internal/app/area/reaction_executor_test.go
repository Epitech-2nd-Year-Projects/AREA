package area

import (
	"context"
	"errors"
	"testing"
	"time"

	areadomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/area"
	componentdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/component"
	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/ports/outbound"
)

type fakeHandler struct {
	match bool
	calls int
	err   error
}

func (f *fakeHandler) Supports(component *componentdomain.Component) bool { return f.match }

func (f *fakeHandler) Execute(ctx context.Context, area areadomain.Area, link areadomain.Link) (outbound.ReactionResult, error) {
	f.calls++
	return outbound.ReactionResult{Endpoint: "handler", Duration: 5 * time.Millisecond}, f.err
}

type fakeFallback struct {
	calls int
	err   error
}

func (f *fakeFallback) ExecuteReaction(ctx context.Context, area areadomain.Area, link areadomain.Link) (outbound.ReactionResult, error) {
	f.calls++
	return outbound.ReactionResult{Endpoint: "fallback", Duration: time.Millisecond}, f.err
}

func TestCompositeReactionExecutorDispatch(t *testing.T) {
	handler := &fakeHandler{match: true}
	fallback := &fakeFallback{}
	exec := NewCompositeReactionExecutor(fallback, nil, handler)

	link := areadomain.Link{Config: componentdomain.Config{Component: &componentdomain.Component{}}}
	if _, err := exec.ExecuteReaction(context.Background(), areadomain.Area{}, link); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if handler.calls != 1 {
		t.Fatalf("expected handler to execute once")
	}
	if fallback.calls != 0 {
		t.Fatalf("fallback should not execute")
	}
}

func TestCompositeReactionExecutorFallback(t *testing.T) {
	handler := &fakeHandler{match: false}
	fallback := &fakeFallback{err: errors.New("fallback")}
	exec := NewCompositeReactionExecutor(fallback, nil, handler)

	link := areadomain.Link{Config: componentdomain.Config{Component: &componentdomain.Component{}}}
	if _, err := exec.ExecuteReaction(context.Background(), areadomain.Area{}, link); !errors.Is(err, fallback.err) {
		t.Fatalf("expected fallback error, got %v", err)
	}
	if handler.calls != 0 {
		t.Fatalf("handler should not execute")
	}
	if fallback.calls != 1 {
		t.Fatalf("fallback should execute once")
	}
}

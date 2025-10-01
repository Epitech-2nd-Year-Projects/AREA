package ginhttp

import (
	"context"
	"errors"
	"net"
	"net/http"
	"net/http/httptest"
	"syscall"
	"testing"
	"time"

	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/platform/httpserver"
	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

func TestNewServer(t *testing.T) {
	srv, err := New(httpserver.Config{}, WithLogger(zap.NewNop()))
	if err != nil {
		t.Fatalf("unexpected error constructing server: %v", err)
	}

	if srv.Engine() == nil {
		t.Fatalf("expected engine to be initialised")
	}
}

func TestRequestIDMiddlewareGeneratesIdentifier(t *testing.T) {
	srv, err := New(httpserver.Config{Mode: httpserver.ModeTest}, WithLogger(zap.NewNop()))
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	srv.Engine().GET("/ping", func(c *gin.Context) {
		id := RequestID(c)
		if id == "" {
			t.Fatalf("expected request id in context")
		}
		c.Header("X-Test-Request-ID", id)
		c.Status(http.StatusNoContent)
	})

	req := httptest.NewRequest(http.MethodGet, "/ping", nil)
	rec := httptest.NewRecorder()
	srv.Engine().ServeHTTP(rec, req)

	if rec.Code != http.StatusNoContent {
		t.Fatalf("expected status %d got %d", http.StatusNoContent, rec.Code)
	}
	if rec.Header().Get("X-Request-ID") == "" {
		t.Fatalf("expected response to include X-Request-ID header")
	}
	if rec.Header().Get("X-Test-Request-ID") == "" {
		t.Fatalf("expected handler to receive generated request id")
	}
}

func TestRequestIDMiddlewareHonoursIncomingHeader(t *testing.T) {
	srv, err := New(httpserver.Config{Mode: httpserver.ModeTest}, WithLogger(zap.NewNop()))
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	srv.Engine().GET("/ping", func(c *gin.Context) {
		c.Status(http.StatusNoContent)
	})

	req := httptest.NewRequest(http.MethodGet, "/ping", nil)
	req.Header.Set("X-Request-ID", "client-id")
	rec := httptest.NewRecorder()
	srv.Engine().ServeHTTP(rec, req)

	if got := rec.Header().Get("X-Request-ID"); got != "client-id" {
		t.Fatalf("expected request id header to propagate, got %q", got)
	}
}

func TestRunRespectsContextCancellation(t *testing.T) {
	cfg := httpserver.Config{
		Host:            "127.0.0.1",
		Mode:            httpserver.ModeTest,
		ShutdownTimeout: 500 * time.Millisecond,
	}
	srv, err := New(cfg, WithLogger(zap.NewNop()))
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	done := make(chan error, 1)
	go func() {
		done <- srv.Run(ctx)
	}()

	time.Sleep(50 * time.Millisecond)
	cancel()

	select {
	case err := <-done:
		if err != nil {
			var opErr *net.OpError
			if errors.As(err, &opErr) {
				if errors.Is(opErr.Err, syscall.EACCES) || errors.Is(opErr.Err, syscall.EPERM) {
					t.Skip("binding tcp sockets is not permitted in this environment")
				}
			}
			t.Fatalf("run returned error: %v", err)
		}
	case <-time.After(2 * time.Second):
		t.Fatal("timed out waiting for server shutdown")
	}
}

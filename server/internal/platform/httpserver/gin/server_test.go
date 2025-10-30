package ginhttp

import (
	"context"
	"errors"
	"net"
	"net/http"
	"net/http/httptest"
	"reflect"
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

func TestWithMiddlewareRegistersHandlers(t *testing.T) {
	var invoked bool

	middleware := func(c *gin.Context) {
		invoked = true
		c.Next()
	}

	srv, err := New(httpserver.Config{Mode: httpserver.ModeTest}, WithLogger(zap.NewNop()), WithMiddleware(middleware))
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	srv.Engine().GET("/ping", func(c *gin.Context) {
		c.Status(http.StatusNoContent)
	})

	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/ping", nil)
	srv.Engine().ServeHTTP(rec, req)

	if !invoked {
		t.Fatal("expected custom middleware to be invoked")
	}
}

func TestWithRequestIDHeader(t *testing.T) {
	srv, err := New(
		httpserver.Config{Mode: httpserver.ModeTest},
		WithLogger(zap.NewNop()),
		WithRequestIDHeader("  X-Custom-ID  "),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	srv.Engine().GET("/ping", func(c *gin.Context) {
		c.Status(http.StatusNoContent)
	})

	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/ping", nil)
	req.Header.Set("X-Custom-ID", "incoming")
	srv.Engine().ServeHTTP(rec, req)

	if got := rec.Header().Get("X-Custom-ID"); got != "incoming" {
		t.Fatalf("expected custom request id header propagated, got %q", got)
	}
}

func TestWithTrustedProxiesOption(t *testing.T) {
	opts := options{
		trustedProxies: []string{"0.0.0.0/0"},
	}

	WithTrustedProxies()(&opts)
	if opts.trustedProxies != nil {
		t.Fatal("expected empty proxies option to reset slice")
	}

	proxies := []string{"10.0.0.0/8", "127.0.0.1"}
	WithTrustedProxies(proxies...)(&opts)
	if !reflect.DeepEqual(opts.trustedProxies, proxies) {
		t.Fatalf("expected trusted proxies to match, got %v", opts.trustedProxies)
	}

	if _, err := New(
		httpserver.Config{Mode: httpserver.ModeTest},
		WithLogger(zap.NewNop()),
		WithTrustedProxies(proxies...),
	); err != nil {
		t.Fatalf("unexpected error constructing server with trusted proxies: %v", err)
	}
}

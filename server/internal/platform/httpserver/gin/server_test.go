package ginhttp

import (
	"context"
	"errors"
	"net"
	"net/http"
	"net/http/httptest"
	"reflect"
	"strings"
	"syscall"
	"testing"
	"time"

	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/platform/httpserver"
	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
	"go.uber.org/zap/zaptest/observer"
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

func TestRecoveryMiddlewareLogsPanic(t *testing.T) {
	core, logs := observer.New(zapcore.DebugLevel)
	logger := zap.New(core)

	srv, err := New(
		httpserver.Config{Mode: httpserver.ModeTest},
		WithLogger(logger),
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	srv.Engine().GET("/panic", func(c *gin.Context) {
		panic("kaboom")
	})

	req := httptest.NewRequest(http.MethodGet, "/panic", nil)
	req.Header.Set("X-Request-ID", "panic-req")
	rec := httptest.NewRecorder()
	srv.Engine().ServeHTTP(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Fatalf("expected status 500, got %d", rec.Code)
	}
	if got := rec.Header().Get("X-Request-ID"); got != "panic-req" {
		t.Fatalf("expected request id propagation, got %q", got)
	}

	var found bool
	for _, entry := range logs.All() {
		if entry.Message == "panic recovered" {
			found = true
			ctx := entry.ContextMap()
			if ctx["request_id"] != "panic-req" {
				t.Fatalf("expected request_id field, got %v", ctx["request_id"])
			}
			if ctx["path"] != "/panic" {
				t.Fatalf("expected path field /panic, got %v", ctx["path"])
			}
		}
	}
	if !found {
		t.Fatal("expected panic recovered log entry")
	}
}

func TestLoggingMiddlewareSeverity(t *testing.T) {
	cases := []struct {
		name        string
		status      int
		err         error
		wantLevel   zapcore.Level
		wantMessage string
	}{
		{
			name:        "info",
			status:      http.StatusAccepted,
			wantLevel:   zapcore.InfoLevel,
			wantMessage: "http request completed",
		},
		{
			name:        "warn",
			status:      http.StatusNotFound,
			wantLevel:   zapcore.WarnLevel,
			wantMessage: "http request completed",
		},
		{
			name:        "error",
			status:      http.StatusInternalServerError,
			err:         errors.New("boom"),
			wantLevel:   zapcore.ErrorLevel,
			wantMessage: "boom",
		},
	}

	for _, tc := range cases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			core, logs := observer.New(zapcore.DebugLevel)
			logger := zap.New(core)

			srv, err := New(
				httpserver.Config{Mode: httpserver.ModeTest},
				WithLogger(logger),
			)
			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}

			srv.Engine().GET("/status", func(c *gin.Context) {
				if tc.err != nil {
					c.Error(tc.err) // nolint:errcheck // gin stores error for logging
				}
				c.Status(tc.status)
			})

			req := httptest.NewRequest(http.MethodGet, "/status", nil)
			req.Header.Set("X-Request-ID", "status-"+tc.name)
			req.Header.Set("User-Agent", "test-agent")
			rec := httptest.NewRecorder()
			srv.Engine().ServeHTTP(rec, req)

			if rec.Code != tc.status {
				t.Fatalf("unexpected response code %d, want %d", rec.Code, tc.status)
			}

			entries := logs.All()
			if len(entries) == 0 {
				t.Fatalf("expected log entry for status %d", tc.status)
			}

			var (
				entry observer.LoggedEntry
				ctx   map[string]any
				found bool
			)
			for i := len(entries) - 1; i >= 0; i-- {
				m := entries[i].ContextMap()
				if m["path"] == "/status" {
					entry = entries[i]
					ctx = m
					found = true
					break
				}
			}
			if !found {
				t.Fatalf("expected log entry for /status, got %v", entries)
			}

			if entry.Level != tc.wantLevel {
				t.Fatalf("log level = %s, want %s", entry.Level, tc.wantLevel)
			}
			if !strings.Contains(entry.Message, tc.wantMessage) {
				t.Fatalf("log message = %q, want substring %q", entry.Message, tc.wantMessage)
			}

			if ctx["method"] != http.MethodGet {
				t.Fatalf("expected method GET, got %v", ctx["method"])
			}
			statusVal, ok := ctx["status"].(int64)
			if !ok {
				t.Fatalf("status field type = %T", ctx["status"])
			}
			if int(statusVal) != tc.status {
				t.Fatalf("expected status field %d, got %d", tc.status, int(statusVal))
			}
			if ctx["request_id"] != "status-"+tc.name {
				t.Fatalf("expected request_id field, got %v", ctx["request_id"])
			}
			if _, ok := ctx["latency"]; !ok {
				t.Fatal("expected latency field to be present")
			}
		})
	}
}

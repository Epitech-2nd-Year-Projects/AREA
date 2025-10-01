package ginhttp

import (
	"context"
	"errors"
	"fmt"
	"net"
	"net/http"
	"runtime/debug"
	"strings"
	"sync"
	"time"

	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/platform/httpserver"
	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"go.uber.org/zap"
)

const requestIDContextKey = "ginhttp_request_id"

// Server wraps a Gin engine with production-ready middleware and lifecycle controls
type Server struct {
	cfg    httpserver.Config
	engine *gin.Engine
	logger *zap.Logger

	mu         sync.Mutex
	httpServer *http.Server

	requestIDHeader string
}

// Option customises server construction
type Option func(*options)

type options struct {
	logger          *zap.Logger
	middleware      []gin.HandlerFunc
	requestIDHeader string
	trustedProxies  []string
}

// New constructs a Server ready to be started with Run
func New(cfg httpserver.Config, optFns ...Option) (*Server, error) {
	cfg.Normalize()

	opts := options{
		logger:          zap.L(),
		requestIDHeader: "X-Request-ID",
	}

	for _, optFn := range optFns {
		optFn(&opts)
	}

	if opts.logger == nil {
		opts.logger = zap.NewNop()
	}

	mode := string(cfg.Mode)
	switch mode {
	case gin.DebugMode, gin.ReleaseMode, gin.TestMode:
	default:
		return nil, fmt.Errorf("unsupported gin mode %q", mode)
	}

	gin.SetMode(mode)

	engine := gin.New()
	if err := engine.SetTrustedProxies(opts.trustedProxies); err != nil {
		return nil, fmt.Errorf("gin.Engine.SetTrustedProxies: %w", err)
	}

	srv := &Server{
		cfg:             cfg,
		engine:          engine,
		logger:          opts.logger,
		requestIDHeader: opts.requestIDHeader,
	}

	engine.Use(
		srv.requestIDMiddleware(),
		srv.loggingMiddleware(),
		corsMiddleware(cfg.CORS),
		srv.recoveryMiddleware(),
	)

	for _, mw := range opts.middleware {
		if mw == nil {
			continue
		}
		engine.Use(mw)
	}

	return srv, nil
}

// Engine exposes the underlying Gin engine for route registration
func (s *Server) Engine() *gin.Engine {
	return s.engine
}

// Run starts the HTTP server and blocks until the provided context is cancelled or a fatal error occurs
func (s *Server) Run(ctx context.Context) error {
	s.mu.Lock()
	if s.httpServer != nil {
		s.mu.Unlock()
		return errors.New("ginhttp: server already running")
	}

	httpSrv := &http.Server{
		Addr:         s.cfg.Address(),
		Handler:      s.engine,
		ReadTimeout:  s.cfg.ReadTimeout,
		WriteTimeout: s.cfg.WriteTimeout,
		IdleTimeout:  s.cfg.IdleTimeout,
		BaseContext: func(net.Listener) context.Context {
			return ctx
		},
	}
	s.httpServer = httpSrv
	s.mu.Unlock()

	errCh := make(chan error, 1)
	go func() {
		s.logger.Info("http server listening", zap.String("addr", httpSrv.Addr))
		if err := httpSrv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			errCh <- fmt.Errorf("http.Server.ListenAndServe: %w", err)
			return
		}
		errCh <- nil
	}()

	select {
	case <-ctx.Done():
		shutdownCtx, cancel := context.WithTimeout(context.Background(), s.cfg.ShutdownTimeout)
		defer cancel()
		if err := s.Shutdown(shutdownCtx); err != nil {
			return err
		}
		return <-errCh
	case err := <-errCh:
		return err
	}
}

// Shutdown gracefully stops the HTTP server
func (s *Server) Shutdown(ctx context.Context) error {
	s.mu.Lock()
	httpSrv := s.httpServer
	s.mu.Unlock()

	if httpSrv == nil {
		return nil
	}

	s.logger.Info("http server shutting down")
	if err := httpSrv.Shutdown(ctx); err != nil {
		if errors.Is(err, context.DeadlineExceeded) {
			s.logger.Error("http shutdown timed out", zap.Error(err))
		}
		return fmt.Errorf("http.Server.Shutdown: %w", err)
	}

	s.mu.Lock()
	s.httpServer = nil
	s.mu.Unlock()
	return nil
}

func (s *Server) requestIDMiddleware() gin.HandlerFunc {
	header := s.requestIDHeader
	if header == "" {
		header = "X-Request-ID"
	}

	return func(c *gin.Context) {
		requestID := sanitizeRequestID(c.Request.Header.Get(header))
		if requestID == "" {
			requestID = uuid.NewString()
		}
		c.Set(requestIDContextKey, requestID)
		c.Writer.Header().Set(header, requestID)
		c.Next()
	}
}

func (s *Server) loggingMiddleware() gin.HandlerFunc {
	logger := s.logger

	return func(c *gin.Context) {
		start := time.Now()
		c.Next()

		latency := time.Since(start)
		status := c.Writer.Status()
		rid, _ := c.Get(requestIDContextKey)
		requestID, _ := rid.(string)
		path := c.FullPath()
		if path == "" {
			path = c.Request.URL.Path
		}

		fields := []zap.Field{
			zap.Int("status", status),
			zap.String("method", c.Request.Method),
			zap.String("path", path),
			zap.String("ip", c.ClientIP()),
			zap.Duration("latency", latency),
			zap.String("user_agent", c.Request.UserAgent()),
		}
		if requestID != "" {
			fields = append(fields, zap.String("request_id", requestID))
		}

		msg := "http request completed"
		switch {
		case status >= http.StatusInternalServerError:
			if len(c.Errors) > 0 {
				msg = c.Errors.String()
			}
			logger.Error(msg, fields...)
		case status >= http.StatusBadRequest:
			logger.Warn(msg, fields...)
		default:
			logger.Info(msg, fields...)
		}
	}
}

func (s *Server) recoveryMiddleware() gin.HandlerFunc {
	logger := s.logger

	return gin.CustomRecovery(func(c *gin.Context, recovered interface{}) {
		var err error
		switch val := recovered.(type) {
		case error:
			err = val
		default:
			err = fmt.Errorf("panic: %v", val)
		}

		rid, _ := c.Get(requestIDContextKey)
		requestID, _ := rid.(string)
		path := c.FullPath()
		if path == "" {
			path = c.Request.URL.Path
		}

		fields := []zap.Field{
			zap.String("method", c.Request.Method),
			zap.String("path", path),
			zap.ByteString("stack", debug.Stack()),
			zap.Error(err),
		}
		if requestID != "" {
			fields = append(fields, zap.String("request_id", requestID))
		}

		logger.Error("panic recovered", fields...)
		c.AbortWithStatus(http.StatusInternalServerError)
	})
}

func corsMiddleware(cfg httpserver.CORSConfig) gin.HandlerFunc {
	corsCfg := cors.Config{
		AllowOrigins:     cfg.AllowedOrigins,
		AllowMethods:     cfg.AllowedMethods,
		AllowHeaders:     cfg.AllowedHeaders,
		AllowCredentials: cfg.AllowCredentials,
		MaxAge:           12 * time.Hour,
	}

	if len(corsCfg.AllowOrigins) == 0 {
		corsCfg.AllowAllOrigins = true
	}

	return cors.New(corsCfg)
}

func sanitizeRequestID(value string) string {
	trimmed := strings.TrimSpace(value)
	if trimmed == "" {
		return ""
	}
	if len(trimmed) > 128 {
		return trimmed[:128]
	}
	return trimmed
}

// RequestID extracts the request identifier associated with the current Gin context
func RequestID(c *gin.Context) string {
	if c == nil {
		return ""
	}
	v, ok := c.Get(requestIDContextKey)
	if !ok {
		return ""
	}
	id, _ := v.(string)
	return id
}

// WithLogger overrides the default zap logger used by the server
func WithLogger(logger *zap.Logger) Option {
	return func(o *options) {
		if logger != nil {
			o.logger = logger
		}
	}
}

// WithMiddleware registers additional Gin middleware executed after the built-in stack
func WithMiddleware(mw ...gin.HandlerFunc) Option {
	return func(o *options) {
		for _, fn := range mw {
			if fn == nil {
				continue
			}
			o.middleware = append(o.middleware, fn)
		}
	}
}

// WithRequestIDHeader customises the header used to propagate request identifiers
func WithRequestIDHeader(header string) Option {
	return func(o *options) {
		header = strings.TrimSpace(header)
		if header != "" {
			o.requestIDHeader = header
		}
	}
}

// WithTrustedProxies configures the CIDR blocks trusted for proxy headers
func WithTrustedProxies(proxies ...string) Option {
	return func(o *options) {
		if len(proxies) == 0 {
			o.trustedProxies = nil
			return
		}
		o.trustedProxies = append([]string(nil), proxies...)
	}
}

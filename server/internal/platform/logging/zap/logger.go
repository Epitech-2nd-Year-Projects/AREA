package zaplogger

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"sort"
	"sync"

	"github.com/Epitech-2nd-Year-Projects/AREA/server/internal/platform/logging"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

// Option customises logger construction beyond Config values
type Option func(*builderOptions)

type builderOptions struct {
	writer     io.Writer
	zapOptions []zap.Option
}

// WithWriter overrides the destination for log output
func WithWriter(w io.Writer) Option {
	return func(o *builderOptions) {
		o.writer = w
	}
}

// WithZapOptions appends arbitrary zap options to the constructed logger
func WithZapOptions(opts ...zap.Option) Option {
	return func(o *builderOptions) {
		if len(opts) == 0 {
			return
		}
		o.zapOptions = append(o.zapOptions, opts...)
	}
}

// New constructs a zap.Logger using the provided configuration
func New(cfg logging.Config, optFns ...Option) (*zap.Logger, error) {
	cfg.Normalize()

	buildOpts := builderOptions{}
	for _, optFn := range optFns {
		if optFn == nil {
			continue
		}
		optFn(&buildOpts)
	}

	level := zap.NewAtomicLevelAt(zap.InfoLevel)
	if err := level.UnmarshalText([]byte(cfg.Level)); err != nil {
		return nil, fmt.Errorf("zap.AtomicLevel.UnmarshalText(%q): %w", cfg.Level, err)
	}

	encoderCfg := zap.NewProductionEncoderConfig()
	encoderCfg.TimeKey = "time"
	encoderCfg.EncodeTime = zapcore.RFC3339TimeEncoder
	encoderCfg.EncodeDuration = zapcore.StringDurationEncoder

	var encoder zapcore.Encoder
	switch cfg.Format {
	case "json":
		encoder = zapcore.NewJSONEncoder(encoderCfg)
	case "text":
		encoderCfg.EncodeLevel = zapcore.CapitalLevelEncoder
		encoder = zapcore.NewConsoleEncoder(encoderCfg)
	default:
		return nil, fmt.Errorf("unsupported format %q", cfg.Format)
	}

	writer := buildWriter(buildOpts.writer)
	if cfg.Format == "json" && cfg.Pretty {
		writer = newPrettyJSONWriter(writer)
	}

	core := zapcore.NewCore(encoder, writer, level)

	opts := append([]zap.Option(nil), buildOpts.zapOptions...)
	if cfg.IncludeCaller {
		opts = append(opts, zap.AddCaller())
	}
	if len(cfg.DefaultFields) > 0 {
		opts = append(opts, zap.Fields(defaultFields(cfg.DefaultFields)...))
	}

	return zap.New(core, opts...), nil
}

func buildWriter(w io.Writer) zapcore.WriteSyncer {
	if w == nil {
		return zapcore.AddSync(os.Stdout)
	}
	if ws, ok := w.(zapcore.WriteSyncer); ok {
		return ws
	}
	return zapcore.AddSync(w)
}

func defaultFields(fields map[string]string) []zap.Field {
	keys := make([]string, 0, len(fields))
	for key := range fields {
		keys = append(keys, key)
	}
	sort.Strings(keys)

	result := make([]zap.Field, 0, len(keys))
	for _, key := range keys {
		result = append(result, zap.String(key, fields[key]))
	}
	return result
}

type prettyJSONWriter struct {
	dest zapcore.WriteSyncer
	mu   sync.Mutex
}

func newPrettyJSONWriter(dest zapcore.WriteSyncer) zapcore.WriteSyncer {
	return &prettyJSONWriter{dest: dest}
}

func (w *prettyJSONWriter) Write(p []byte) (int, error) {
	w.mu.Lock()
	defer w.mu.Unlock()

	trimmed := bytes.TrimSpace(p)
	if len(trimmed) == 0 {
		return len(p), nil
	}

	var formatted bytes.Buffer
	if err := json.Indent(&formatted, trimmed, "", "  "); err != nil {
		if _, writeErr := w.dest.Write(p); writeErr != nil {
			return 0, fmt.Errorf("write raw json log: %w", writeErr)
		}
		return len(p), nil
	}

	formatted.WriteByte('\n')
	if _, err := w.dest.Write(formatted.Bytes()); err != nil {
		return 0, fmt.Errorf("write pretty json log: %w", err)
	}

	return len(p), nil
}

func (w *prettyJSONWriter) Sync() error {
	w.mu.Lock()
	defer w.mu.Unlock()

	return w.dest.Sync()
}

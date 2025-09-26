package zaplogger

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"strings"
	"sync"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

// Config controls zap logger construction
type Config struct {
	Level  string
	Format string
	Pretty bool
	Writer io.Writer
}

// New constructs a zap.Logger based on Config
func New(cfg Config) (*zap.Logger, error) {
	level := zap.NewAtomicLevelAt(zap.InfoLevel)
	rawLevel := strings.TrimSpace(cfg.Level)
	if rawLevel != "" {
		normalized := strings.ToLower(rawLevel)
		if err := level.UnmarshalText([]byte(normalized)); err != nil {
			return nil, fmt.Errorf("zap.AtomicLevel.UnmarshalText(%q): %w", cfg.Level, err)
		}
	}

	encoderCfg := zap.NewProductionEncoderConfig()
	encoderCfg.TimeKey = "time"
	encoderCfg.EncodeTime = zapcore.RFC3339TimeEncoder
	encoderCfg.EncodeDuration = zapcore.StringDurationEncoder

	format := strings.ToLower(strings.TrimSpace(cfg.Format))
	var encoder zapcore.Encoder
	switch format {
	case "", "json":
		encoder = zapcore.NewJSONEncoder(encoderCfg)
	case "text":
		encoderCfg.EncodeLevel = zapcore.CapitalLevelEncoder
		encoder = zapcore.NewConsoleEncoder(encoderCfg)
	default:
		return nil, fmt.Errorf("unsupported format %q", cfg.Format)
	}

	writer := buildWriter(cfg.Writer)
	if format == "" || format == "json" {
		if cfg.Pretty {
			writer = newPrettyJSONWriter(writer)
		}
	}

	core := zapcore.NewCore(encoder, writer, level)
	return zap.New(core, zap.AddCaller()), nil
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

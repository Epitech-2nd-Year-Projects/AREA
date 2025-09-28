package logging_test

import (
	"bytes"
	"strings"
	"testing"

	projectlogging "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/platform/logging"
	zaplogger "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/platform/logging/zap"
)

func TestConfigNormalize(t *testing.T) {
	cfg := projectlogging.Config{
		Level:  "  WARN  ",
		Format: "  Text ",
	}
	cfg.Normalize()

	if cfg.Level != "warn" {
		t.Fatalf("expected level warn got %q", cfg.Level)
	}
	if cfg.Format != "text" {
		t.Fatalf("expected format text got %q", cfg.Format)
	}
	if cfg.DefaultFields == nil {
		t.Fatalf("expected default fields map to be initialised")
	}
}

func TestNewUsesOptions(t *testing.T) {
	var buf bytes.Buffer
	cfg := projectlogging.Config{
		DefaultFields: map[string]string{"service": "area"},
	}

	logger, err := zaplogger.New(cfg, zaplogger.WithWriter(&buf))
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	logger.Info("normalised logger")
	_ = logger.Sync()

	output := buf.String()
	if !strings.Contains(output, "\"service\":\"area\"") {
		t.Fatalf("expected default field in logs, got %q", output)
	}
}

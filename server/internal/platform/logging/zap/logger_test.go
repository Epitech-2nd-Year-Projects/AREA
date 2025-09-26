package zaplogger

import (
	"bytes"
	"strings"
	"testing"

	"go.uber.org/zap"
)

func TestNewWithDefaultJSON(t *testing.T) {
	var buf bytes.Buffer

	logger, err := New(Config{Writer: &buf})
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}

	logger.Info("hello", zap.String("component", "test"))
	_ = logger.Sync()

	output := buf.String()
	if !strings.Contains(output, "\"msg\":\"hello\"") {
		t.Fatalf("expected message in output, got %q", output)
	}
	if !strings.Contains(output, "\"component\":\"test\"") {
		t.Fatalf("expected attribute in output, got %q", output)
	}
}

func TestNewWithTextFormat(t *testing.T) {
	var buf bytes.Buffer

	logger, err := New(Config{Format: "text", Writer: &buf})
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}

	logger.Warn("warning message")
	_ = logger.Sync()

	output := buf.String()
	if !strings.Contains(output, "\tWARN\t") {
		t.Fatalf("expected WARN level in output, got %q", output)
	}
	if !strings.Contains(output, "warning message") {
		t.Fatalf("expected message in output, got %q", output)
	}
}

func TestNewInvalidFormat(t *testing.T) {
	if _, err := New(Config{Format: "xml"}); err == nil {
		t.Fatal("expected error for unsupported format")
	}
}

func TestNewInvalidLevel(t *testing.T) {
	if _, err := New(Config{Level: "verbose"}); err == nil {
		t.Fatal("expected error for unsupported level")
	}
}

func TestNewPrettyJSON(t *testing.T) {
	var buf bytes.Buffer

	logger, err := New(Config{Pretty: true, Writer: &buf})
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}

	logger.Info("pretty", zap.String("key", "value"))
	_ = logger.Sync()

	output := buf.String()
	if !strings.Contains(output, "\n  \"level\":") {
		t.Fatalf("expected pretty printed output, got %q", output)
	}
}

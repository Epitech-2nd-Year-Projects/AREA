package catalog

import (
	"bytes"
	"context"
	"os"
	"path/filepath"
	"testing"
)

func TestFileLoaderLoad(t *testing.T) {
	dir := t.TempDir()
	filePath := filepath.Join(dir, "services.yaml")
	payload := []byte(`services:
  - name: demo
    actions:
      - name: ping
        description: Returns pong
    reactions:
      - name: pong
        description: Returns ping
`)
	if err := os.WriteFile(filePath, payload, 0600); err != nil {
		t.Fatalf("os.WriteFile: %v", err)
	}

	catalog, err := FileLoader{Path: filePath}.Load(context.Background())
	if err != nil {
		t.Fatalf("FileLoader.Load: %v", err)
	}

	if len(catalog.Services) != 1 {
		t.Fatalf("expected 1 service got %d", len(catalog.Services))
	}
	if catalog.Services[0].Name != "demo" {
		t.Fatalf("unexpected service name: %q", catalog.Services[0].Name)
	}
}

func TestFileLoaderMissingPath(t *testing.T) {
	if _, err := (FileLoader{}).Load(context.Background()); err == nil {
		t.Fatal("expected error for empty path")
	}
}

func TestDecodeYAMLFailures(t *testing.T) {
	if _, err := decodeYAML(context.Background(), bytes.NewBufferString("invalid:")); err == nil {
		t.Fatal("expected decode error for malformed YAML")
	}
}

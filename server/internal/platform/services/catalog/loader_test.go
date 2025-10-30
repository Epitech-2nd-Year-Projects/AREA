package catalog

import (
	"bytes"
	"context"
	"fmt"
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

type stubLoader struct {
	catalog Catalog
	err     error
}

func (s stubLoader) Load(ctx context.Context) (Catalog, error) {
	return s.catalog, s.err
}

func TestChainLoaderEmpty(t *testing.T) {
	loader := NewChainLoader()
	catalog, err := loader.Load(context.Background())
	if err != nil {
		t.Fatalf("ChainLoader.Load() error = %v", err)
	}
	if !catalog.Empty() {
		t.Fatalf("ChainLoader.Load() expected empty catalog, got %#v", catalog)
	}
}

func TestChainLoaderSkipsNilAndEmpty(t *testing.T) {
	expected := Catalog{
		Services: []Service{
			{Name: "svc"},
		},
	}

	loader := NewChainLoader(
		nil,
		stubLoader{}, // empty
		stubLoader{catalog: expected},
	)

	catalog, err := loader.Load(context.Background())
	if err != nil {
		t.Fatalf("ChainLoader.Load() error = %v", err)
	}
	if catalog.Empty() {
		t.Fatalf("ChainLoader.Load() expected non-empty catalog")
	}
	if catalog.Services[0].Actions == nil {
		t.Fatal("normalizeCatalog() expected non-nil actions slice")
	}
	if catalog.Services[0].Reactions == nil {
		t.Fatal("normalizeCatalog() expected non-nil reactions slice")
	}
}

func TestChainLoaderReturnsFirstError(t *testing.T) {
	errBoom := fmt.Errorf("loader failed")

	loader := NewChainLoader(
		stubLoader{err: errBoom},
		stubLoader{catalog: Catalog{}},
	)

	_, err := loader.Load(context.Background())
	if err == nil {
		t.Fatal("ChainLoader.Load() expected error")
	}
	if err.Error() != errBoom.Error() {
		t.Fatalf("ChainLoader.Load() error = %v, want %v", err, errBoom)
	}
}

func TestChainLoaderIgnoresContextCancellationErrors(t *testing.T) {
	errBoom := fmt.Errorf("second failure")

	loader := NewChainLoader(
		stubLoader{err: context.Canceled},
		stubLoader{err: errBoom},
	)

	_, err := loader.Load(context.Background())
	if err == nil {
		t.Fatal("ChainLoader.Load() expected error")
	}
	if err.Error() != errBoom.Error() {
		t.Fatalf("ChainLoader.Load() error = %v, want %v", err, errBoom)
	}
}

func TestEmptyLoaderRespectsContext(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	cancel()

	if _, err := (EmptyLoader{}).Load(ctx); err == nil {
		t.Fatal("EmptyLoader.Load() expected context error")
	}
}

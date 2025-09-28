package catalog

import (
	"context"
	"errors"
	"fmt"
	"io"
	"os"

	"gopkg.in/yaml.v3"
)

// Loader reads service catalogs from a backing source
type Loader interface {
	Load(ctx context.Context) (Catalog, error)
}

// FileLoader loads catalog definitions from a YAML file on disk
type FileLoader struct {
	Path string
}

// Load reads and decodes the on-disk catalog definition
func (l FileLoader) Load(ctx context.Context) (Catalog, error) {
	if err := ctx.Err(); err != nil {
		return Catalog{}, err
	}
	if l.Path == "" {
		return Catalog{}, fmt.Errorf("catalog.FileLoader.Load: path is empty")
	}

	file, err := os.Open(l.Path)
	if err != nil {
		return Catalog{}, fmt.Errorf("catalog.FileLoader.Load: open %q: %w", l.Path, err)
	}
	defer func() {
		_ = file.Close()
	}()

	return decodeYAML(ctx, file)
}

// decodeYAML converts the provided reader into a catalog representation
func decodeYAML(ctx context.Context, r io.Reader) (Catalog, error) {
	if err := ctx.Err(); err != nil {
		return Catalog{}, err
	}
	var payload Catalog
	decoder := yaml.NewDecoder(r)
	decoder.KnownFields(true)
	if err := decoder.Decode(&payload); err != nil {
		return Catalog{}, fmt.Errorf("catalog.decodeYAML: decode: %w", err)
	}
	if payload.Services == nil {
		payload.Services = make([]Service, 0)
	}
	return payload, nil
}

// ChainLoader iterates through the provided loaders until one returns a non-empty catalog
type ChainLoader struct {
	loaders []Loader
}

// NewChainLoader builds a ChainLoader from the provided loaders
func NewChainLoader(loaders ...Loader) Loader {
	return &ChainLoader{loaders: append([]Loader(nil), loaders...)}
}

// Load returns the first non-empty catalog produced by the configured loaders
func (c *ChainLoader) Load(ctx context.Context) (Catalog, error) {
	if len(c.loaders) == 0 {
		return Catalog{}, nil
	}
	var firstErr error
	for _, loader := range c.loaders {
		if loader == nil {
			continue
		}
		catalog, err := loader.Load(ctx)
		if err != nil {
			if !errors.Is(err, context.Canceled) && !errors.Is(err, context.DeadlineExceeded) && firstErr == nil {
				firstErr = err
			}
			continue
		}
		if catalog.Empty() {
			continue
		}
		return normalizeCatalog(catalog), nil
	}
	if firstErr != nil {
		return Catalog{}, firstErr
	}
	return Catalog{}, nil
}

// EmptyLoader always returns an empty catalog
type EmptyLoader struct{}

// Load implements Loader
func (EmptyLoader) Load(ctx context.Context) (Catalog, error) {
	if err := ctx.Err(); err != nil {
		return Catalog{}, err
	}
	return Catalog{}, nil
}

func normalizeCatalog(cat Catalog) Catalog {
	if cat.Services == nil {
		cat.Services = make([]Service, 0)
		return cat
	}
	for i := range cat.Services {
		if cat.Services[i].Actions == nil {
			cat.Services[i].Actions = make([]Component, 0)
		}
		if cat.Services[i].Reactions == nil {
			cat.Services[i].Reactions = make([]Component, 0)
		}
	}
	return cat
}

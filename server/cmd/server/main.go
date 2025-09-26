package main

import (
	"fmt"
	"os"

	configviper "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/platform/config/viper"
	projectlogger "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/platform/logging/zap"
	"go.uber.org/zap"
)

func main() {
	if err := run(); err != nil {
		fmt.Fprintf(os.Stderr, "cmd/server: %v\n", err)
		os.Exit(1)
	}
}

func run() error {
	cfg, err := configviper.Load()
	if err != nil {
		return fmt.Errorf("configviper.Load: %w", err)
	}

	logger, err := projectlogger.New(projectlogger.Config{
		Level:  cfg.Logging.Level,
		Format: cfg.Logging.Format,
		Pretty: cfg.Logging.Pretty,
	})
	if err != nil {
		return fmt.Errorf("projectlogger.New: %w", err)
	}

	zap.ReplaceGlobals(logger)
	defer func() {
		_ = logger.Sync()
	}()

	logger.Info("configuration loaded",
		zap.String("environment", cfg.App.Environment),
		zap.String("http_host", cfg.HTTP.Host),
		zap.Int("http_port", cfg.HTTP.Port),
	)

	return nil
}

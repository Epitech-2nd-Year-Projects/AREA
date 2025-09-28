package postgres

import (
	"context"
	"fmt"
	"net/url"
	"time"

	configviper "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/platform/config/viper"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

// Open establishes a PostgreSQL connection using GORM and returns the configured handle
func Open(ctx context.Context, cfg configviper.DatabaseConfig) (*gorm.DB, error) {
	dsn := buildDSN(cfg)
	if dsn == "" {
		return nil, fmt.Errorf("postgres.Open: database configuration incomplete")
	}

	db, err := gorm.Open(postgres.New(postgres.Config{
		DSN:                  dsn,
		PreferSimpleProtocol: true,
	}), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Silent),
	})
	if err != nil {
		return nil, fmt.Errorf("postgres.Open: gorm.Open: %w", err)
	}

	sqlDB, err := db.DB()
	if err != nil {
		return nil, fmt.Errorf("postgres.Open: db.DB(): %w", err)
	}

	if cfg.MaxOpenConns > 0 {
		sqlDB.SetMaxOpenConns(cfg.MaxOpenConns)
	}
	if cfg.MaxIdleConns > 0 {
		sqlDB.SetMaxIdleConns(cfg.MaxIdleConns)
	}
	if cfg.ConnMaxLifetime > 0 {
		sqlDB.SetConnMaxLifetime(cfg.ConnMaxLifetime)
	}
	if cfg.ConnMaxIdleTime > 0 {
		sqlDB.SetConnMaxIdleTime(cfg.ConnMaxIdleTime)
	}

	pingCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()
	if err := sqlDB.PingContext(pingCtx); err != nil {
		_ = sqlDB.Close()
		return nil, fmt.Errorf("postgres.Open: ping: %w", err)
	}

	return db, nil
}

func buildDSN(cfg configviper.DatabaseConfig) string {
	if cfg.DSN != "" {
		return cfg.DSN
	}
	if cfg.Host == "" || cfg.Name == "" {
		return ""
	}

	u := url.URL{
		Scheme: "postgres",
		Host:   fmt.Sprintf("%s:%d", cfg.Host, cfg.Port),
		Path:   cfg.Name,
	}

	if cfg.User != "" {
		if cfg.Password != "" {
			u.User = url.UserPassword(cfg.User, cfg.Password)
		} else {
			u.User = url.User(cfg.User)
		}
	}

	query := url.Values{}
	if cfg.SSLMode != "" {
		query.Set("sslmode", cfg.SSLMode)
	}
	if len(query) > 0 {
		u.RawQuery = query.Encode()
	}
	return u.String()
}

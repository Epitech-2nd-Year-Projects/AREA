package config

import (
	"os"
)

type Config struct {
    Port           string
    MongoURI       string
    MongoDB        string
    JWTSecret      string
    CookieDomain   string
    CookieSecure   bool
    CookieSameSite string
}

func getenv(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}

func Load() Config {
    secure := getenv("COOKIE_SECURE", "false") == "true"
    return Config{
        Port:           getenv("PORT", "8080"),
        MongoURI:       getenv("MONGO_URI", ""),
        MongoDB:        getenv("MONGO_DB", "app"),
        JWTSecret:      getenv("JWT_SECRET", "change-me"),
        CookieDomain:   getenv("COOKIE_DOMAIN", ""),
        CookieSecure:   secure,
        CookieSameSite: getenv("COOKIE_SAMESITE", "Lax"),
    }
}

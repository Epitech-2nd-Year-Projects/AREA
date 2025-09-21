package handlers

import (
    "encoding/json"
    "log"
    "net/http"
    "strings"
    "time"

    "github.com/epitech/area-poc/backend/go/internal/auth"
    "github.com/epitech/area-poc/backend/go/internal/config"
    "go.mongodb.org/mongo-driver/bson"
    "go.mongodb.org/mongo-driver/bson/primitive"
    "go.mongodb.org/mongo-driver/mongo"
    "golang.org/x/crypto/bcrypt"
)

type Handler struct {
    db  *mongo.Database
    cfg config.Config
}

func New(db *mongo.Database, cfg config.Config) *Handler {
    return &Handler{db: db, cfg: cfg}
}

func (h *Handler) Routes() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("/register", h.handleRegister)
	mux.HandleFunc("/auth", h.handleAuth)
	mux.HandleFunc("/refresh", h.handleRefresh)
	mux.HandleFunc("/logout", h.handleLogout)
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) { w.WriteHeader(http.StatusOK) })
	return h.withJSON(h.withCORS(mux))
}

func (h *Handler) withCORS(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", r.Header.Get("Origin"))
		w.Header().Set("Vary", "Origin")
		w.Header().Set("Access-Control-Allow-Credentials", "true")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		w.Header().Set("Access-Control-Allow-Methods", "GET,POST,OPTIONS")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(w, r)
	})
}

func (h *Handler) withJSON(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		next.ServeHTTP(w, r)
	})
}

type credentials struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

func (h *Handler) handleRegister(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}

	var c credentials
	if err := json.NewDecoder(r.Body).Decode(&c); err != nil {
		h.writeErr(w, http.StatusBadRequest, "invalid json")
		return
	}

	c.Email = strings.TrimSpace(strings.ToLower(c.Email))
	if c.Email == "" || len(c.Password) < 8 {
		h.writeErr(w, http.StatusBadRequest, "email and password required (min 8)")
		return
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(c.Password), bcrypt.DefaultCost)
	if err != nil {
		h.writeErr(w, http.StatusInternalServerError, "hash error")
		return
	}

    ctx := r.Context()
    users := h.db.Collection("users")
    doc := bson.D{
        {Key: "email", Value: c.Email},
        {Key: "password_hash", Value: string(hash)},
        {Key: "created_at", Value: time.Now()},
    }
    res, err := users.InsertOne(ctx, doc)
    if err != nil {
        if mongo.IsDuplicateKeyError(err) {
            h.writeErr(w, http.StatusConflict, "email already exists")
            return
        }
        log.Printf("register error: %v", err)
        h.writeErr(w, http.StatusInternalServerError, "db error")
        return
    }
    oid, _ := res.InsertedID.(primitive.ObjectID)
    w.WriteHeader(http.StatusCreated)
    _ = json.NewEncoder(w).Encode(map[string]any{"id": oid.Hex(), "email": c.Email})
}

func (h *Handler) handleAuth(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}

	var c credentials
	if err := json.NewDecoder(r.Body).Decode(&c); err != nil {
		h.writeErr(w, http.StatusBadRequest, "invalid json")
		return
	}

	c.Email = strings.TrimSpace(strings.ToLower(c.Email))
	if c.Email == "" || c.Password == "" {
		h.writeErr(w, http.StatusBadRequest, "email and password required")
		return
	}

    ctx := r.Context()
    users := h.db.Collection("users")
    var doc struct {
        ID           primitive.ObjectID `bson:"_id"`
        PasswordHash string             `bson:"password_hash"`
    }
    if err := users.FindOne(ctx, bson.D{{Key: "email", Value: c.Email}}).Decode(&doc); err != nil {
        h.writeErr(w, http.StatusUnauthorized, "invalid credentials")
        return
    }
    if err := bcrypt.CompareHashAndPassword([]byte(doc.PasswordHash), []byte(c.Password)); err != nil {
        h.writeErr(w, http.StatusUnauthorized, "invalid credentials")
        return
    }
    tokens, err := auth.GenerateTokens(h.cfg.JWTSecret, doc.ID.Hex(), c.Email)
    if err != nil {
        h.writeErr(w, http.StatusInternalServerError, "token error")
        return
    }
    h.setAuthCookies(w, tokens)
    _ = json.NewEncoder(w).Encode(map[string]any{"ok": true})
}

func (h *Handler) writeErr(w http.ResponseWriter, code int, msg string) {
	w.WriteHeader(code)
	_ = json.NewEncoder(w).Encode(map[string]any{"error": msg})
}

func (h *Handler) setAuthCookies(w http.ResponseWriter, tp auth.TokenPair) {
	sameSite := http.SameSiteLaxMode
	switch strings.ToLower(h.cfg.CookieSameSite) {
	case "strict":
		sameSite = http.SameSiteStrictMode
	case "none":
		sameSite = http.SameSiteNoneMode
	}
	cookieCommon := func(name, value string, maxAge int, httpOnly bool) *http.Cookie {
		return &http.Cookie{
			Name:     name,
			Value:    value,
			Path:     "/",
			Domain:   h.cfg.CookieDomain,
			Secure:   h.cfg.CookieSecure,
			HttpOnly: httpOnly,
			SameSite: sameSite,
			MaxAge:   maxAge,
		}
	}
	http.SetCookie(w, cookieCommon("token", tp.AccessToken, int((15*time.Minute)/time.Second), true))
	http.SetCookie(w, cookieCommon("refresh_token", tp.RefreshToken, int((7*24*time.Hour)/time.Second), true))
}

func (h *Handler) clearAuthCookies(w http.ResponseWriter) {
	sameSite := http.SameSiteLaxMode
	switch strings.ToLower(h.cfg.CookieSameSite) {
	case "strict":
		sameSite = http.SameSiteStrictMode
	case "none":
		sameSite = http.SameSiteNoneMode
	}
	expired := time.Unix(0, 0)
	base := func(name string) *http.Cookie {
		return &http.Cookie{
			Name:     name,
			Value:    "",
			Path:     "/",
			Domain:   h.cfg.CookieDomain,
			Secure:   h.cfg.CookieSecure,
			HttpOnly: true,
			SameSite: sameSite,
			Expires:  expired,
			MaxAge:   -1,
		}
	}
	http.SetCookie(w, base("token"))
	http.SetCookie(w, base("refresh_token"))
}

func (h *Handler) handleRefresh(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}

	c, err := r.Cookie("refresh_token")
	if err != nil || c.Value == "" {
		h.writeErr(w, http.StatusUnauthorized, "missing refresh token")
		return
	}

	claims, err := auth.Verify(c.Value, h.cfg.JWTSecret, "refresh")
	if err != nil {
		h.writeErr(w, http.StatusUnauthorized, "invalid refresh token")
		return
	}

    users := h.db.Collection("users")
    oid, err := primitive.ObjectIDFromHex(claims.Subject)
    if err != nil {
        h.writeErr(w, http.StatusUnauthorized, "user not found")
        return
    }
    if err := users.FindOne(r.Context(), bson.D{{Key: "_id", Value: oid}}).Err(); err != nil {
        h.writeErr(w, http.StatusUnauthorized, "user not found")
        return
    }

	tokens, err := auth.GenerateTokens(h.cfg.JWTSecret, claims.Subject, "")
	if err != nil {
		h.writeErr(w, http.StatusInternalServerError, "token error")
		return
	}
	h.setAuthCookies(w, tokens)
	_ = json.NewEncoder(w).Encode(map[string]any{"ok": true})
}

func (h *Handler) handleLogout(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}
	h.clearAuthCookies(w)
	_ = json.NewEncoder(w).Encode(map[string]any{"ok": true})
}

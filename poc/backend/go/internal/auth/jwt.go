package auth

import (
	"crypto/subtle"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

type TokenPair struct {
	AccessToken  string
	RefreshToken string
}

type Claims struct {
	Type string `json:"type"`
	jwt.RegisteredClaims
}

func constantTimeEqual(a, b string) bool {
	return subtle.ConstantTimeCompare([]byte(a), []byte(b)) == 1
}

func GenerateTokens(secret, userID, email string) (TokenPair, error) {
	now := time.Now()
	access := jwt.NewWithClaims(jwt.SigningMethodHS256, Claims{
		Type: "access",
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   userID,
			ExpiresAt: jwt.NewNumericDate(now.Add(15 * time.Minute)),
			IssuedAt:  jwt.NewNumericDate(now),
		},
	})

	refresh := jwt.NewWithClaims(jwt.SigningMethodHS256, Claims{
		Type: "refresh",
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   userID,
			ExpiresAt: jwt.NewNumericDate(now.Add(7 * 24 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(now),
		},
	})

	at, err := access.SignedString([]byte(secret))
	if err != nil {
		return TokenPair{}, err
	}

	rt, err := refresh.SignedString([]byte(secret))
	if err != nil {
		return TokenPair{}, err
	}

	return TokenPair{AccessToken: at, RefreshToken: rt}, nil
}

func Verify(token, secret, expectedType string) (*Claims, error) {
	parsed, err := jwt.ParseWithClaims(token, &Claims{}, func(t *jwt.Token) (interface{}, error) {
		if t.Method != jwt.SigningMethodHS256 {
			return nil, jwt.ErrTokenUnverifiable
		}
		return []byte(secret), nil
	})
	if err != nil {
		return nil, err
	}

	claims, ok := parsed.Claims.(*Claims)
	if !ok || !parsed.Valid {
		return nil, jwt.ErrTokenInvalidClaims
	}
	if !constantTimeEqual(claims.Type, expectedType) {
		return nil, jwt.ErrTokenInvalidClaims
	}
	return claims, nil
}

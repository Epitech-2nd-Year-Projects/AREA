package password

import (
	"fmt"

	"golang.org/x/crypto/bcrypt"
)

// Hasher hashes and verifies passwords with pepper support
type Hasher struct {
	Cost   int
	Pepper string
}

// Hash returns the bcrypt hash of the provided password combined with the configured pepper
func (h Hasher) Hash(password string) (string, error) {
	if password == "" {
		return "", fmt.Errorf("password.Hasher.Hash: password is empty")
	}
	payload := h.applyPepper(password)
	hash, err := bcrypt.GenerateFromPassword([]byte(payload), h.cost())
	if err != nil {
		return "", fmt.Errorf("password.Hasher.Hash: bcrypt.GenerateFromPassword: %w", err)
	}
	return string(hash), nil
}

// Compare verifies that the provided password matches the stored hash
func (h Hasher) Compare(hash string, password string) error {
	if hash == "" {
		return fmt.Errorf("password.Hasher.Compare: hash is empty")
	}
	payload := h.applyPepper(password)
	if err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(payload)); err != nil {
		return fmt.Errorf("password.Hasher.Compare: bcrypt.CompareHashAndPassword: %w", err)
	}
	return nil
}

func (h Hasher) cost() int {
	if h.Cost == 0 {
		return bcrypt.DefaultCost
	}
	return h.Cost
}

func (h Hasher) applyPepper(password string) string {
	if h.Pepper == "" {
		return password
	}
	return password + h.Pepper
}

package password

import (
	"strings"
	"testing"

	"golang.org/x/crypto/bcrypt"
)

func TestHasherHashAndCompare(t *testing.T) {
	h := Hasher{Pepper: "pep"}

	hash, err := h.Hash("hunter2")
	if err != nil {
		t.Fatalf("Hasher.Hash() error = %v", err)
	}
	if hash == "" {
		t.Fatal("Hasher.Hash() returned empty hash")
	}

	if cost, err := bcrypt.Cost([]byte(hash)); err != nil {
		t.Fatalf("bcrypt.Cost() error = %v", err)
	} else if cost != bcrypt.DefaultCost {
		t.Fatalf("Hasher.Hash() cost = %d, want %d", cost, bcrypt.DefaultCost)
	}

	if err := h.Compare(hash, "hunter2"); err != nil {
		t.Fatalf("Hasher.Compare() error = %v", err)
	}

	if err := h.Compare(hash, "wrong"); err == nil || !strings.Contains(err.Error(), "bcrypt.CompareHashAndPassword") {
		t.Fatalf("Hasher.Compare() expected mismatch error, got %v", err)
	}
}

func TestHasherCustomCost(t *testing.T) {
	h := Hasher{Cost: bcrypt.MinCost}

	hash, err := h.Hash("value")
	if err != nil {
		t.Fatalf("Hasher.Hash() error = %v", err)
	}

	cost, err := bcrypt.Cost([]byte(hash))
	if err != nil {
		t.Fatalf("bcrypt.Cost() error = %v", err)
	}
	if cost != bcrypt.MinCost {
		t.Fatalf("Hasher.Hash() cost = %d, want %d", cost, bcrypt.MinCost)
	}
}

func TestHasherErrorCases(t *testing.T) {
	if _, err := (Hasher{}).Hash(""); err == nil {
		t.Fatal("Hasher.Hash() expected error for empty password")
	}

	if err := (Hasher{}).Compare("", "password"); err == nil {
		t.Fatal("Hasher.Compare() expected error for empty hash")
	}
}

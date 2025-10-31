package cipher

import (
	"bytes"
	"encoding/base64"
	"strings"
	"testing"
)

func TestNewAESCipherFromString(t *testing.T) {
	rawKey := bytes.Repeat([]byte{0xAB}, 32)
	encoded := base64.StdEncoding.EncodeToString(rawKey)

	c, err := NewAESCipherFromString(encoded)
	if err != nil {
		t.Fatalf("NewAESCipherFromString() error = %v", err)
	}

	// Mutate the original slice to ensure the cipher keeps an internal copy.
	for i := range rawKey {
		rawKey[i] = 0
	}

	msg := "super-secret-value"
	token, err := c.Encrypt(msg)
	if err != nil {
		t.Fatalf("Encrypt() error = %v", err)
	}

	decoded, err := c.Decrypt(token)
	if err != nil {
		t.Fatalf("Decrypt() error = %v", err)
	}
	if decoded != msg {
		t.Fatalf("Decrypt() got = %q, want %q", decoded, msg)
	}
}

func TestNewAESCipherErrors(t *testing.T) {
	if _, err := NewAESCipherFromString("not-base64"); err == nil {
		t.Fatal("NewAESCipherFromString() expected error for invalid base64")
	}

	if _, err := NewAESCipher([]byte("short-key")); err == nil {
		t.Fatal("NewAESCipher() expected error for invalid key length")
	}
}

func TestAESCipherEmptyValues(t *testing.T) {
	key := bytes.Repeat([]byte{0x42}, 16)
	c, err := NewAESCipher(key)
	if err != nil {
		t.Fatalf("NewAESCipher() error = %v", err)
	}

	enc, err := c.Encrypt("")
	if err != nil {
		t.Fatalf("Encrypt() empty error = %v", err)
	}
	if enc != "" {
		t.Fatalf("Encrypt() empty got = %q, want empty string", enc)
	}

	dec, err := c.Decrypt("")
	if err != nil {
		t.Fatalf("Decrypt() empty error = %v", err)
	}
	if dec != "" {
		t.Fatalf("Decrypt() empty got = %q, want empty string", dec)
	}
}

func TestAESCipherDecryptErrors(t *testing.T) {
	key := bytes.Repeat([]byte{0x11}, 16)
	c, err := NewAESCipher(key)
	if err != nil {
		t.Fatalf("NewAESCipher() error = %v", err)
	}

	if _, err := c.Decrypt("%%%"); err == nil {
		t.Fatal("Decrypt() expected error for invalid base64 payload")
	}

	shortPayload := base64.StdEncoding.EncodeToString([]byte("tiny"))
	if _, err := c.Decrypt(shortPayload); err == nil || !strings.Contains(err.Error(), "payload too short") {
		t.Fatalf("Decrypt() expected payload length error, got %v", err)
	}

	valid, err := c.Encrypt("message")
	if err != nil {
		t.Fatalf("Encrypt() error = %v", err)
	}
	payload, err := base64.StdEncoding.DecodeString(valid)
	if err != nil {
		t.Fatalf("DecodeString() error = %v", err)
	}
	payload[len(payload)-1] ^= 0xFF
	tampered := base64.StdEncoding.EncodeToString(payload)

	if _, err := c.Decrypt(tampered); err == nil || !strings.Contains(err.Error(), "cipher.Open") {
		t.Fatalf("Decrypt() expected authentication error, got %v", err)
	}
}

func TestNoopCipher(t *testing.T) {
	var c NoopCipher
	value := "plain-text"

	enc, err := c.Encrypt(value)
	if err != nil {
		t.Fatalf("NoopCipher.Encrypt() error = %v", err)
	}
	if enc != value {
		t.Fatalf("NoopCipher.Encrypt() got = %q, want %q", enc, value)
	}

	dec, err := c.Decrypt(value)
	if err != nil {
		t.Fatalf("NoopCipher.Decrypt() error = %v", err)
	}
	if dec != value {
		t.Fatalf("NoopCipher.Decrypt() got = %q, want %q", dec, value)
	}
}

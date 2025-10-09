package cipher

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"encoding/base64"
	"fmt"
	"io"
)

// Cipher wraps symmetric encryption operations used for token storage
type Cipher interface {
	Encrypt(value string) (string, error)
	Decrypt(value string) (string, error)
}

// AESCipher implements Cipher using AES-GCM
type AESCipher struct {
	key []byte
}

// NewAESCipherFromString builds an AES-GCM cipher from a base64 encoded key
func NewAESCipherFromString(encoded string) (*AESCipher, error) {
	raw, err := base64.StdEncoding.DecodeString(encoded)
	if err != nil {
		return nil, fmt.Errorf("decode key: %w", err)
	}
	return NewAESCipher(raw)
}

// NewAESCipher constructs an AES-GCM cipher from the provided raw key
func NewAESCipher(key []byte) (*AESCipher, error) {
	if len(key) != 16 && len(key) != 24 && len(key) != 32 {
		return nil, fmt.Errorf("invalid aes key length %d", len(key))
	}
	cpy := make([]byte, len(key))
	copy(cpy, key)
	return &AESCipher{key: cpy}, nil
}

// Encrypt encrypts the plaintext string and returns a base64 encoded payload
func (c *AESCipher) Encrypt(value string) (string, error) {
	if value == "" {
		return "", nil
	}
	block, err := aes.NewCipher(c.key)
	if err != nil {
		return "", fmt.Errorf("aes.NewCipher: %w", err)
	}
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", fmt.Errorf("cipher.NewGCM: %w", err)
	}

	nonce := make([]byte, gcm.NonceSize())
	if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
		return "", fmt.Errorf("rand.Read: %w", err)
	}

	ciphertext := gcm.Seal(nil, nonce, []byte(value), nil)
	payload := append(nonce, ciphertext...)
	return base64.StdEncoding.EncodeToString(payload), nil
}

// Decrypt decodes and decrypts the base64 payload returning the plaintext
func (c *AESCipher) Decrypt(value string) (string, error) {
	if value == "" {
		return "", nil
	}

	payload, err := base64.StdEncoding.DecodeString(value)
	if err != nil {
		return "", fmt.Errorf("decode payload: %w", err)
	}

	block, err := aes.NewCipher(c.key)
	if err != nil {
		return "", fmt.Errorf("aes.NewCipher: %w", err)
	}
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", fmt.Errorf("cipher.NewGCM: %w", err)
	}
	if len(payload) < gcm.NonceSize() {
		return "", fmt.Errorf("payload too short")
	}

	nonce := payload[:gcm.NonceSize()]
	ciphertext := payload[gcm.NonceSize():]

	plaintext, err := gcm.Open(nil, nonce, ciphertext, nil)
	if err != nil {
		return "", fmt.Errorf("cipher.Open: %w", err)
	}
	return string(plaintext), nil
}

// NoopCipher implements Cipher without transformations (for testing)
type NoopCipher struct{}

// Encrypt returns the input unchanged
func (NoopCipher) Encrypt(value string) (string, error) { return value, nil }

// Decrypt returns the input unchanged
func (NoopCipher) Decrypt(value string) (string, error) { return value, nil }

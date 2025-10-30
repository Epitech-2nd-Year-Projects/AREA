package mail

import (
	"fmt"
	"strings"
)

var recipientSeparator = strings.NewReplacer(";", ",", "\n", ",")

// ParseList normalizes email recipient inputs into a slice of addresses
func ParseList(value any, allowEmpty bool) ([]string, error) {
	if value == nil {
		return nil, nil
	}

	emails := make([]string, 0, 4)

	collect := func(raw any) error {
		if raw == nil {
			return nil
		}
		str, err := ToString(raw)
		if err != nil {
			if allowEmpty {
				return nil
			}
			return err
		}
		str = strings.TrimSpace(str)
		if str == "" {
			return nil
		}

		parts := strings.Split(recipientSeparator.Replace(str), ",")
		for _, part := range parts {
			address := Normalize(part)
			if address != "" {
				emails = append(emails, address)
			}
		}
		return nil
	}

	switch typed := value.(type) {
	case []string:
		for _, item := range typed {
			if err := collect(item); err != nil {
				return nil, err
			}
		}
	case []any:
		for _, item := range typed {
			if err := collect(item); err != nil {
				return nil, err
			}
		}
	default:
		if err := collect(typed); err != nil {
			return nil, err
		}
	}

	emails = FilterEmpty(emails)
	if len(emails) == 0 {
		if allowEmpty {
			return nil, nil
		}
		return nil, fmt.Errorf("no recipients provided")
	}

	return emails, nil
}

// Normalize trims and standardizes an email address
func Normalize(raw string) string {
	return strings.TrimSpace(raw)
}

// FilterEmpty removes blank entries from the provided slice
func FilterEmpty(values []string) []string {
	result := make([]string, 0, len(values))
	for _, value := range values {
		if trimmed := strings.TrimSpace(value); trimmed != "" {
			result = append(result, trimmed)
		}
	}
	return result
}

// ToString converts supported types to string values
func ToString(value any) (string, error) {
	switch v := value.(type) {
	case string:
		return v, nil
	case fmt.Stringer:
		return v.String(), nil
	default:
		return "", fmt.Errorf("not a string")
	}
}

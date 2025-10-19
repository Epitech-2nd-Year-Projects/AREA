package area

import (
	"fmt"
	"math"
)

func toInt(value any) (int, error) {
	switch v := value.(type) {
	case int:
		return v, nil
	case int32:
		return int(v), nil
	case int64:
		return int(v), nil
	case float64:
		if math.Mod(v, 1) != 0 {
			return 0, fmt.Errorf("not an integer")
		}
		return int(v), nil
	case float32:
		if math.Mod(float64(v), 1) != 0 {
			return 0, fmt.Errorf("not an integer")
		}
		return int(v), nil
	default:
		return 0, fmt.Errorf("not a number")
	}
}

func toString(value any) (string, error) {
	switch v := value.(type) {
	case string:
		return v, nil
	case fmt.Stringer:
		return v.String(), nil
	default:
		return "", fmt.Errorf("not a string")
	}
}

func toStringLower(value any) (string, error) {
	str, err := toString(value)
	if err != nil {
		return "", err
	}
	return normalizeProvisionKey(str), nil
}

func toMapStringAny(value any) (map[string]any, error) {
	if value == nil {
		return nil, fmt.Errorf("nil map")
	}
	switch v := value.(type) {
	case map[string]any:
		return v, nil
	case map[any]any:
		result := make(map[string]any, len(v))
		for key, item := range v {
			keyStr, ok := key.(string)
			if !ok {
				return nil, fmt.Errorf("map key not string")
			}
			result[keyStr] = item
		}
		return result, nil
	default:
		return nil, fmt.Errorf("not a map")
	}
}

func cloneMapAny(value map[string]any) map[string]any {
	if len(value) == 0 {
		return nil
	}
	cloned := make(map[string]any, len(value))
	for key, item := range value {
		switch v := item.(type) {
		case map[string]any:
			cloned[key] = cloneMapAny(v)
		case []any:
			cloned[key] = cloneSliceAny(v)
		default:
			cloned[key] = v
		}
	}
	return cloned
}

func cloneSliceAny(values []any) []any {
	if len(values) == 0 {
		return nil
	}
	cloned := make([]any, len(values))
	for idx, item := range values {
		switch v := item.(type) {
		case map[string]any:
			cloned[idx] = cloneMapAny(v)
		case []any:
			cloned[idx] = cloneSliceAny(v)
		default:
			cloned[idx] = v
		}
	}
	return cloned
}

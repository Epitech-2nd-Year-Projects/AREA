package area

import (
	"fmt"
	"math"
	"strings"
	"time"
)

const (
	timerComponentName = "timer_interval"
	timerProviderName  = "scheduler"
)

type timerConfig struct {
	frequencyValue int
	frequencyUnit  string
	startAt        *time.Time
	timeZone       string
	location       *time.Location
}

type timerUnit struct {
	labelSingular string
	labelPlural   string
	duration      time.Duration
}

var timerUnits = map[string]timerUnit{
	"minute":  {labelSingular: "minute", labelPlural: "minutes", duration: time.Minute},
	"minutes": {labelSingular: "minute", labelPlural: "minutes", duration: time.Minute},
	"hour":    {labelSingular: "hour", labelPlural: "hours", duration: time.Hour},
	"hours":   {labelSingular: "hour", labelPlural: "hours", duration: time.Hour},
	"day":     {labelSingular: "day", labelPlural: "days", duration: 24 * time.Hour},
	"days":    {labelSingular: "day", labelPlural: "days", duration: 24 * time.Hour},
}

func decodeTimerConfig(params map[string]any) (timerConfig, error) {
	cfg := timerConfig{}

	valueRaw, ok := params["frequencyValue"]
	if !ok {
		return cfg, fmt.Errorf("timer config: frequencyValue missing")
	}
	value, err := toInt(valueRaw)
	if err != nil || value <= 0 {
		return cfg, fmt.Errorf("timer config: invalid frequencyValue")
	}
	cfg.frequencyValue = value

	unitRaw, ok := params["frequencyUnit"]
	if !ok {
		return cfg, fmt.Errorf("timer config: frequencyUnit missing")
	}
	unitStr, err := toString(unitRaw)
	if err != nil {
		return cfg, fmt.Errorf("timer config: invalid frequencyUnit")
	}
	unitStr = strings.ToLower(strings.TrimSpace(unitStr))
	unitData, ok := timerUnits[unitStr]
	if !ok {
		return cfg, fmt.Errorf("timer config: unsupported frequencyUnit %q", unitStr)
	}
	cfg.frequencyUnit = unitData.labelSingular

	if tzRaw, ok := params["timeZone"]; ok {
		tz, err := toString(tzRaw)
		if err != nil {
			return cfg, fmt.Errorf("timer config: invalid timeZone")
		}
		tz = strings.TrimSpace(tz)
		if tz != "" {
			loc, err := time.LoadLocation(tz)
			if err != nil {
				return cfg, fmt.Errorf("timer config: unsupported timeZone %q", tz)
			}
			cfg.timeZone = tz
			cfg.location = loc
		}
	}

	if startRaw, ok := params["startAt"]; ok {
		startStr, err := toString(startRaw)
		if err != nil {
			return cfg, fmt.Errorf("timer config: invalid startAt")
		}
		startStr = strings.TrimSpace(startStr)
		if startStr != "" {
			parsed, err := time.Parse(time.RFC3339, startStr)
			if err != nil {
				return cfg, fmt.Errorf("timer config: startAt must be RFC3339")
			}
			utc := parsed.UTC()
			cfg.startAt = &utc
		}
	}

	return cfg, nil
}

func (cfg timerConfig) interval() time.Duration {
	unit, ok := timerUnits[cfg.frequencyUnit]
	if !ok {
		return 0
	}
	return time.Duration(cfg.frequencyValue) * unit.duration
}

func (cfg timerConfig) nextAfter(reference time.Time) (time.Time, error) {
	interval := cfg.interval()
	if interval <= 0 {
		return time.Time{}, fmt.Errorf("timer config: non-positive interval")
	}

	ref := reference.UTC()
	if cfg.startAt == nil {
		return ref.Add(interval), nil
	}

	start := cfg.startAt.UTC()
	if ref.Before(start) {
		return start, nil
	}

	elapsed := ref.Sub(start)
	cycles := elapsed/interval + 1
	return start.Add(cycles * interval), nil
}

func (cfg timerConfig) description() string {
	unit := timerUnits[cfg.frequencyUnit]
	label := unit.labelSingular
	if cfg.frequencyValue != 1 {
		label = unit.labelPlural
	}
	return fmt.Sprintf("every %d %s", cfg.frequencyValue, label)
}

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

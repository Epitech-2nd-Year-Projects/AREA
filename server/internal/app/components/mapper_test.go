package components

import (
	"testing"

	componentdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/component"
	"github.com/google/uuid"
)

func TestToSummaryClonesMetadata(t *testing.T) {
	componentID := uuid.New()
	providerID := uuid.New()
	metadata := map[string]any{"parameters": []any{"value"}}
	component := componentdomain.Component{
		ID:          componentID,
		Provider:    componentdomain.Provider{ID: providerID, Name: "scheduler", DisplayName: "Scheduler"},
		Kind:        componentdomain.KindAction,
		Name:        "timer_interval",
		DisplayName: "Recurring timer",
		Metadata:    metadata,
	}

	summary := ToSummary(&component, componentID)
	if summary.Metadata == nil {
		t.Fatalf("expected metadata to be set")
	}

	cloned := *summary.Metadata
	cloned["parameters"] = []any{"mutated"}

	if original, _ := metadata["parameters"].([]any); len(original) != 1 || original[0] != "value" {
		t.Fatalf("expected source metadata to remain unchanged")
	}
	if summary.Id != componentID {
		t.Fatalf("unexpected component id %s", summary.Id)
	}
	if summary.Provider.Id != providerID {
		t.Fatalf("unexpected provider id %s", summary.Provider.Id)
	}
}

func TestToSummaryHandlesNilComponent(t *testing.T) {
	fallback := uuid.New()
	summary := ToSummary(nil, fallback)
	if summary.Id != fallback {
		t.Fatalf("expected fallback id, got %s", summary.Id)
	}
}

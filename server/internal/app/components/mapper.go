package components

import (
	openapi "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/adapters/inbound/http/openapi"
	componentdomain "github.com/Epitech-2nd-Year-Projects/AREA/server/internal/domain/component"
	"github.com/google/uuid"
	openapi_types "github.com/oapi-codegen/runtime/types"
)

// MapComponents converts domain components into OpenAPI summaries ready for transport
func MapComponents(items []componentdomain.Component) []openapi.ComponentSummary {
	if len(items) == 0 {
		return make([]openapi.ComponentSummary, 0)
	}
	result := make([]openapi.ComponentSummary, 0, len(items))
	for _, item := range items {
		summary := ToSummary(&item, item.ID)
		result = append(result, summary)
	}
	return result
}

// ToSummary converts a single component into an OpenAPI summary representation
func ToSummary(component *componentdomain.Component, fallbackID uuid.UUID) openapi.ComponentSummary {
	if component == nil {
		return openapi.ComponentSummary{
			Id:          openapi_types.UUID(fallbackID),
			Provider:    openapi.ServiceProviderSummary{},
			Metadata:    nil,
			Name:        "",
			DisplayName: "",
		}
	}

	var description *string
	if trimmed := component.Description; trimmed != "" {
		desc := trimmed
		description = &desc
	}

	var metadata *map[string]interface{}
	if len(component.Metadata) > 0 {
		cloned := cloneMetadata(component.Metadata)
		metadata = &cloned
	}

	provider := openapi.ServiceProviderSummary{
		Id:          openapi_types.UUID(component.Provider.ID),
		Name:        component.Provider.Name,
		DisplayName: component.Provider.DisplayName,
	}

	return openapi.ComponentSummary{
		Id:          openapi_types.UUID(component.ID),
		Name:        component.Name,
		DisplayName: component.DisplayName,
		Description: description,
		Kind:        openapi.ComponentSummaryKind(component.Kind),
		Provider:    provider,
		Metadata:    metadata,
	}
}

func cloneMetadata(source map[string]any) map[string]interface{} {
	if len(source) == 0 {
		return map[string]interface{}{}
	}
	clone := make(map[string]interface{}, len(source))
	for key, value := range source {
		clone[key] = value
	}
	return clone
}

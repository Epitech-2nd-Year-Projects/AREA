import type { Service } from '@/lib/api/contracts/services'
import type {
  ServiceProviderDetailDTO,
  ServiceProviderListResponseDTO
} from '@/lib/api/contracts/openapi/services'

function mapServiceProviderToService(
  provider: ServiceProviderDetailDTO
): Service {
  return {
    name: provider.name,
    displayName: provider.displayName,
    description: '',
    actions: [],
    reactions: [],
    category: provider.category ?? undefined,
    needsConnection: provider.oauthType !== 'none'
  }
}

export function mapServiceProviderListResponse(
  response: ServiceProviderListResponseDTO
): Service[] {
  if (!response.providers) return []
  return response.providers.map(mapServiceProviderToService)
}

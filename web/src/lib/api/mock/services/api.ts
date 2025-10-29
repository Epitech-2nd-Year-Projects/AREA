import type { ServiceProviderListResponseDTO } from '@/lib/api/contracts/openapi/services'
import { mockServices } from '../data'

export async function listServiceProvidersMock(): Promise<ServiceProviderListResponseDTO> {
  const providers = mockServices.map((service) => ({
    id: `svc-${service.name}`,
    name: service.name,
    displayName: service.displayName,
    oauthType: 'oauth2' as const,
    enabled: true,
    createdAt: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000).toISOString(),
    updatedAt: new Date().toISOString(),
    category: 'default'
  }))
  return { providers }
}

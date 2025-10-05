import type { Area, AreaComponent, AreaStatus } from '@/lib/api/contracts/areas'
import type {
  AreaComponentDTO,
  AreaDTO,
  ListAreasResponseDTO
} from '@/lib/api/contracts/openapi/areas'

function cloneParams(
  params?: Record<string, unknown> | null
): Record<string, unknown> {
  if (!params) return {}
  return Object.entries(params).reduce<Record<string, unknown>>(
    (acc, [key, value]) => {
      acc[key] = value
      return acc
    },
    {}
  )
}

function normalizeStatus(status: string): AreaStatus {
  const normalized = status?.toLowerCase()
  if (
    normalized === 'enabled' ||
    normalized === 'disabled' ||
    normalized === 'archived'
  ) {
    return normalized
  }
  return 'disabled'
}

function mapAreaComponent(dto: AreaComponentDTO): AreaComponent {
  const provider = dto.component.provider
  const fallbackName = dto.component.displayName || dto.component.name
  return {
    id: dto.componentId,
    configId: dto.configId,
    name: dto.name ?? fallbackName,
    description: dto.component.description ?? '',
    serviceName: provider.name,
    serviceDisplayName: provider.displayName || provider.name,
    params: cloneParams(dto.params)
  }
}

export function mapAreaDTOToArea(dto: AreaDTO): Area {
  const status = normalizeStatus(dto.status)
  return {
    id: dto.id,
    name: dto.name,
    description: dto.description ?? '',
    status,
    enabled: status === 'enabled',
    createdAt: new Date(dto.createdAt),
    updatedAt: new Date(dto.updatedAt),
    action: mapAreaComponent(dto.action),
    reactions: dto.reactions.map(mapAreaComponent)
  }
}

export function mapListAreasResponse(response: ListAreasResponseDTO): Area[] {
  return response.areas.map(mapAreaDTOToArea)
}

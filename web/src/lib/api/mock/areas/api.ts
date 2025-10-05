import type {
  AreaDTO,
  CreateAreaRequestDTO,
  ListAreasResponseDTO
} from '@/lib/api/contracts/openapi/areas'
import {
  mockUserLinkedAreas,
  mockActions,
  mockReactions,
  mockServices
} from '../data'
import type { Area, AreaComponent } from '@/lib/api/contracts/areas'
import { ApiError } from '@/lib/api/http/errors'

const serviceDisplayNameByName = mockServices.reduce<Record<string, string>>(
  (acc, service) => {
    acc[service.name] = service.displayName
    return acc
  },
  {}
)

function cloneParams(
  params?: Record<string, unknown>
): Record<string, unknown> | undefined {
  if (!params) return undefined
  const entries = Object.entries(params)
  if (!entries.length) return undefined
  return entries.reduce<Record<string, unknown>>((acc, [key, value]) => {
    acc[key] = value
    return acc
  }, {})
}

function toComponentSummary(
  component: AreaComponent,
  kind: 'action' | 'reaction'
) {
  return {
    id: component.id,
    kind,
    name: component.name,
    displayName: component.name,
    description: component.description || null,
    provider: {
      id: `svc-${component.serviceName}`,
      name: component.serviceName,
      displayName: component.serviceDisplayName
    }
  }
}

function toAreaDTO(area: Area): AreaDTO {
  return {
    id: area.id,
    name: area.name,
    description: area.description || null,
    status: area.status,
    createdAt: area.createdAt.toISOString(),
    updatedAt: area.updatedAt.toISOString(),
    action: {
      configId: area.action.configId,
      componentId: area.action.id,
      name: area.action.name,
      params: cloneParams(area.action.params) ?? {},
      component: toComponentSummary(area.action, 'action')
    },
    reactions: area.reactions.map((reaction) => ({
      configId: reaction.configId,
      componentId: reaction.id,
      name: reaction.name,
      params: cloneParams(reaction.params) ?? {},
      component: toComponentSummary(reaction, 'reaction')
    }))
  }
}

function generateId(prefix: string) {
  return `${prefix}-${Math.random().toString(36).slice(2, 10)}`
}

function resolveAreaComponent(
  componentId: string,
  kind: 'action' | 'reaction',
  name?: string,
  params?: Record<string, unknown>
): AreaComponent {
  const collection = kind === 'action' ? mockActions : mockReactions
  const fallback = collection.find((item) => item.id === componentId)
  const serviceName = fallback?.serviceName ?? 'custom'
  return {
    id: componentId,
    configId: generateId(`cfg-${kind}`),
    name: name ?? fallback?.name ?? 'Custom component',
    description: fallback?.description ?? '',
    serviceName,
    serviceDisplayName: serviceDisplayNameByName[serviceName] ?? serviceName,
    params: params ? { ...params } : {}
  }
}

export async function listAreasMock(): Promise<ListAreasResponseDTO> {
  return {
    areas: mockUserLinkedAreas.map(toAreaDTO)
  }
}

export async function createAreaMock(
  body: CreateAreaRequestDTO
): Promise<AreaDTO> {
  const now = new Date()
  const area: Area = {
    id: generateId('area'),
    name: body.name,
    description: body.description ?? '',
    status: 'enabled',
    enabled: true,
    createdAt: now,
    updatedAt: now,
    action: resolveAreaComponent(
      body.action.componentId,
      'action',
      body.action.name,
      body.action.params
    ),
    reactions: body.reactions.map((reaction) =>
      resolveAreaComponent(
        reaction.componentId,
        'reaction',
        reaction.name,
        reaction.params
      )
    )
  }

  if (!area.reactions.length) {
    throw new ApiError(
      400,
      'missingReactions',
      'At least one reaction is required'
    )
  }

  mockUserLinkedAreas.unshift(area)

  return toAreaDTO(area)
}

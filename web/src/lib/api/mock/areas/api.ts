import type {
  AreaDTO,
  AreaHistoryResponseDTO,
  CreateAreaRequestDTO,
  DuplicateAreaRequestDTO,
  ListAreasResponseDTO,
  UpdateAreaRequestDTO,
  UpdateAreaStatusRequestDTO
} from '@/lib/api/contracts/openapi/areas'
import {
  mockUserLinkedAreas,
  mockActions,
  mockReactions,
  mockServices,
  buildMockAreaHistory
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

function findAreaOrThrow(areaId: string) {
  const area = mockUserLinkedAreas.find((item) => item.id === areaId)
  if (!area) {
    throw new ApiError(404, 'areaNotFound', 'Area not found')
  }
  return area
}

export async function updateAreaMock(
  areaId: string,
  body: UpdateAreaRequestDTO
): Promise<AreaDTO> {
  const area = findAreaOrThrow(areaId)

  if (body.name !== undefined) {
    area.name = body.name
  }
  if (body.description !== undefined) {
    area.description = body.description ?? ''
  }

  if (body.action) {
    if (area.action.configId !== body.action.configId) {
      throw new ApiError(
        400,
        'invalidActionConfig',
        'Unknown action configuration'
      )
    }
    if (body.action.name !== undefined) {
      area.action.name = body.action.name
    }
    if (body.action.params !== undefined) {
      area.action.params = cloneParams(body.action.params) ?? {}
    }
  }

  if (body.reactions) {
    body.reactions.forEach((reactionPatch) => {
      const reaction = area.reactions.find(
        (item) => item.configId === reactionPatch.configId
      )
      if (!reaction) {
        throw new ApiError(
          400,
          'invalidReactionConfig',
          'Unknown reaction configuration'
        )
      }
      if (reactionPatch.name !== undefined) {
        reaction.name = reactionPatch.name
      }
      if (reactionPatch.params !== undefined) {
        reaction.params = cloneParams(reactionPatch.params) ?? {}
      }
    })
  }

  area.updatedAt = new Date()

  return toAreaDTO(area)
}

export async function updateAreaStatusMock(
  areaId: string,
  body: UpdateAreaStatusRequestDTO
): Promise<AreaDTO> {
  const area = findAreaOrThrow(areaId)
  area.status = body.status
  area.enabled = body.status === 'enabled'
  area.updatedAt = new Date()
  return toAreaDTO(area)
}

export async function deleteAreaMock(areaId: string): Promise<void> {
  const index = mockUserLinkedAreas.findIndex((item) => item.id === areaId)
  if (index === -1) {
    throw new ApiError(404, 'areaNotFound', 'Area not found')
  }
  mockUserLinkedAreas.splice(index, 1)
}

export async function executeAreaMock(areaId: string): Promise<void> {
  findAreaOrThrow(areaId)
}

export async function duplicateAreaMock(
  areaId: string,
  body?: DuplicateAreaRequestDTO
): Promise<AreaDTO> {
  const original = findAreaOrThrow(areaId)
  const now = new Date()
  const cloneComponent = (component: AreaComponent): AreaComponent => ({
    ...component,
    configId: generateId('cfg-dup'),
    params: cloneParams(component.params) ?? {}
  })
  const duplicated: Area = {
    ...original,
    id: generateId('area'),
    name: body?.name ?? `${original.name} (copy)`,
    description:
      body && Object.prototype.hasOwnProperty.call(body, 'description')
        ? (body.description ?? '')
        : original.description,
    createdAt: now,
    updatedAt: now,
    action: cloneComponent(original.action),
    reactions: original.reactions.map(cloneComponent)
  }
  mockUserLinkedAreas.unshift(duplicated)
  return toAreaDTO(duplicated)
}

export async function listAreaHistoryMock(
  areaId: string,
  params?: { limit?: number }
): Promise<AreaHistoryResponseDTO> {
  const area = findAreaOrThrow(areaId)
  const runs = buildMockAreaHistory(area)
  const limit = params?.limit ?? runs.length
  const executions = runs.slice(0, limit).map((run, index) => {
    const reaction = area.reactions[0] ?? area.action
    return {
      jobId: `${area.id}-job-${index}`,
      status: run.status === 'success' ? 'succeeded' : 'failed',
      attempt: 1,
      runAt: run.executedAt.toISOString(),
      createdAt: run.executedAt.toISOString(),
      updatedAt: run.executedAt.toISOString(),
      error: run.status === 'failure' ? (run.errorMessage ?? null) : null,
      resultPayload:
        run.status === 'success'
          ? {
              durationMs: run.durationMs,
              reactionsTriggered: run.reactionsTriggered
            }
          : { reactionsTriggered: run.reactionsTriggered },
      reaction: {
        component: reaction.name,
        provider: reaction.serviceDisplayName
      }
    }
  })

  return { executions }
}

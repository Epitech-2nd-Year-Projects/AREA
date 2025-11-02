import { apiFetchClient } from '../../http/client'
import { buildClientOptions } from '../common'
import type { ClientRequestOptions } from '../common'
import type {
  AreaDTO,
  AreaHistoryResponseDTO,
  CreateAreaRequestDTO,
  DuplicateAreaRequestDTO,
  ListAreasResponseDTO,
  UpdateAreaRequestDTO,
  UpdateAreaStatusRequestDTO
} from '@/lib/api/contracts/openapi/areas'
import { apiRuntime } from '@/lib/api/runtime'
import {
  createAreaMock,
  deleteAreaMock,
  duplicateAreaMock,
  executeAreaMock,
  listAreaHistoryMock,
  listAreasMock,
  updateAreaMock,
  updateAreaStatusMock
} from '@/lib/api/mock/areas'

export function listAreasClient(options?: ClientRequestOptions) {
  if (apiRuntime.useMocks) {
    return listAreasMock()
  }
  return apiFetchClient<ListAreasResponseDTO>(
    '/v1/areas',
    buildClientOptions(options)
  )
}

export function createAreaClient(
  body: CreateAreaRequestDTO,
  options?: ClientRequestOptions
) {
  if (apiRuntime.useMocks) {
    return createAreaMock(body)
  }
  return apiFetchClient<AreaDTO>('/v1/areas', {
    method: 'POST',
    body,
    ...buildClientOptions(options)
  })
}

export function updateAreaClient(
  areaId: string,
  body: UpdateAreaRequestDTO,
  options?: ClientRequestOptions
) {
  if (apiRuntime.useMocks) {
    return updateAreaMock(areaId, body)
  }
  return apiFetchClient<AreaDTO>(`/v1/areas/${areaId}`, {
    method: 'PATCH',
    body,
    ...buildClientOptions(options)
  })
}

export function deleteAreaClient(
  areaId: string,
  options?: ClientRequestOptions
) {
  if (apiRuntime.useMocks) {
    return deleteAreaMock(areaId)
  }
  return apiFetchClient<void>(`/v1/areas/${areaId}`, {
    method: 'DELETE',
    ...buildClientOptions(options)
  })
}

export function executeAreaClient(
  areaId: string,
  options?: ClientRequestOptions
) {
  if (apiRuntime.useMocks) {
    return executeAreaMock(areaId)
  }
  return apiFetchClient<void>(`/v1/areas/${areaId}/execute`, {
    method: 'POST',
    ...buildClientOptions(options)
  })
}

export function updateAreaStatusClient(
  areaId: string,
  body: UpdateAreaStatusRequestDTO,
  options?: ClientRequestOptions
) {
  if (apiRuntime.useMocks) {
    return updateAreaStatusMock(areaId, body)
  }
  return apiFetchClient<AreaDTO>(`/v1/areas/${areaId}/status`, {
    method: 'PATCH',
    body,
    ...buildClientOptions(options)
  })
}

export function duplicateAreaClient(
  areaId: string,
  body?: DuplicateAreaRequestDTO,
  options?: ClientRequestOptions
) {
  if (apiRuntime.useMocks) {
    return duplicateAreaMock(areaId, body)
  }
  return apiFetchClient<AreaDTO>(`/v1/areas/${areaId}/duplicate`, {
    method: 'POST',
    body,
    ...buildClientOptions(options)
  })
}

export function listAreaHistoryClient(
  areaId: string,
  params?: { limit?: number },
  options?: ClientRequestOptions
) {
  if (apiRuntime.useMocks) {
    return listAreaHistoryMock(areaId, params)
  }
  const search = new URLSearchParams()
  if (params?.limit !== undefined) {
    search.set('limit', params.limit.toString())
  }
  const query = search.toString()
  const path = query
    ? `/v1/areas/${areaId}/history?${query}`
    : `/v1/areas/${areaId}/history`
  return apiFetchClient<AreaHistoryResponseDTO>(
    path,
    buildClientOptions(options)
  )
}

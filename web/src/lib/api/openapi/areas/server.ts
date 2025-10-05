import { apiFetchServer } from '../../http/server'
import { buildServerOptions } from '../common'
import type { ServerRequestOptions } from '../common'
import type {
  AreaDTO,
  CreateAreaRequestDTO,
  ListAreasResponseDTO
} from '@/lib/api/contracts/openapi/areas'
import { apiRuntime } from '@/lib/api/runtime'
import { createAreaMock, listAreasMock } from '@/lib/api/mock/areas'

export function listAreasServer(options?: ServerRequestOptions) {
  if (apiRuntime.useMocks) {
    return listAreasMock()
  }
  return apiFetchServer<ListAreasResponseDTO>(
    '/v1/areas',
    buildServerOptions(options)
  )
}

export function createAreaServer(
  body: CreateAreaRequestDTO,
  options?: ServerRequestOptions
) {
  if (apiRuntime.useMocks) {
    return createAreaMock(body)
  }
  return apiFetchServer<AreaDTO>('/v1/areas', {
    method: 'POST',
    body,
    ...buildServerOptions(options)
  })
}

import { apiFetchClient } from '../../http/client'
import { buildClientOptions } from '../common'
import type { ClientRequestOptions } from '../common'
import type {
  AreaDTO,
  CreateAreaRequestDTO,
  ListAreasResponseDTO
} from '@/lib/api/contracts/openapi/areas'
import { apiRuntime } from '@/lib/api/runtime'
import { createAreaMock, listAreasMock } from '@/lib/api/mock/areas'

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

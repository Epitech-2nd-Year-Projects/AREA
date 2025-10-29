import { apiFetchServer } from '../../http/server'
import { buildServerOptions } from '../common'
import type { ServerRequestOptions } from '../common'
import type { ServiceProviderListResponseDTO } from '@/lib/api/contracts/openapi/services'
import { apiRuntime } from '@/lib/api/runtime'
import { listServiceProvidersMock } from '@/lib/api/mock/services'

export function listServiceProvidersServer(options?: ServerRequestOptions) {
  if (apiRuntime.useMocks) {
    return listServiceProvidersMock()
  }
  return apiFetchServer<ServiceProviderListResponseDTO>(
    '/v1/services',
    buildServerOptions(options)
  )
}

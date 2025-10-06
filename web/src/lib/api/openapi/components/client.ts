import { apiFetchClient } from '../../http/client'
import { buildClientOptions } from '../common'
import type { ClientRequestOptions } from '../common'
import type { ComponentSummaryDTO } from '@/lib/api/contracts/openapi/areas'
import { apiRuntime } from '@/lib/api/runtime'
import { getAvailableComponentsMock } from '@/lib/api/mock'

export type ComponentListResponseDTO = {
  components: ComponentSummaryDTO[]
}

export function listAvailableComponentsClient(
  params?: { kind?: 'action' | 'reaction'; provider?: string },
  options?: ClientRequestOptions
) {
  if (apiRuntime.useMocks) {
    return getAvailableComponentsMock(params)
  }
  const search = new URLSearchParams()
  if (params?.kind) search.set('kind', params.kind)
  if (params?.provider) search.set('provider', params.provider)
  const query = search.toString()
  const path = query
    ? `/v1/components/available?${query}`
    : '/v1/components/available'
  return apiFetchClient<ComponentListResponseDTO>(
    path,
    buildClientOptions(options)
  )
}

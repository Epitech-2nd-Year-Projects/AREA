import { componentsKeys } from './query-keys'
import {
  listAvailableComponentsClient,
  listComponentsClient,
  type ComponentListResponseDTO
} from './client'
import type { ClientRequestOptions } from '../common'
import type { ComponentSummaryDTO } from '@/lib/api/contracts/openapi/areas'

export const componentsQueries = {
  list: (args?: {
    params?: { kind?: 'action' | 'reaction'; provider?: string }
    clientOptions?: ClientRequestOptions
  }) => ({
    queryKey: componentsKeys.list(args?.params),
    queryFn: () =>
      listComponentsClient(args?.params, args?.clientOptions).then(
        (res: ComponentListResponseDTO) => res.components
      ) as Promise<ComponentSummaryDTO[]>
  }),
  available: (args?: {
    params?: { kind?: 'action' | 'reaction'; provider?: string }
    clientOptions?: ClientRequestOptions
  }) => ({
    queryKey: componentsKeys.available(args?.params),
    queryFn: () =>
      listAvailableComponentsClient(args?.params, args?.clientOptions).then(
        (res: ComponentListResponseDTO) => res.components
      ) as Promise<ComponentSummaryDTO[]>
  })
}

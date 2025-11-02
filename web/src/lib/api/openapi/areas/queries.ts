import type { ClientRequestOptions } from '../common'
import { listAreaHistoryClient, listAreasClient } from './client'
import { areasKeys } from './query-keys'
import { mapAreaHistoryResponse, mapListAreasResponse } from './adapter'

export const areasQueries = {
  list: (options?: { clientOptions?: ClientRequestOptions }) => ({
    queryKey: areasKeys.list(),
    queryFn: async () => {
      const response = await listAreasClient(options?.clientOptions)
      return mapListAreasResponse(response)
    }
  }),
  history: (
    areaId: string,
    options?: { limit?: number; clientOptions?: ClientRequestOptions }
  ) => ({
    queryKey: areasKeys.history(areaId),
    queryFn: async () => {
      const response = await listAreaHistoryClient(
        areaId,
        options?.limit !== undefined ? { limit: options.limit } : undefined,
        options?.clientOptions
      )
      return mapAreaHistoryResponse(response)
    }
  })
}

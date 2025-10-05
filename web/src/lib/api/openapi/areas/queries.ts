import type { ClientRequestOptions } from '../common'
import { listAreasClient } from './client'
import { areasKeys } from './query-keys'
import { mapListAreasResponse } from './adapter'

export const areasQueries = {
  list: (options?: { clientOptions?: ClientRequestOptions }) => ({
    queryKey: areasKeys.list(),
    queryFn: async () => {
      const response = await listAreasClient(options?.clientOptions)
      return mapListAreasResponse(response)
    }
  })
}

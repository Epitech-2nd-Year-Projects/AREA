import type { ClientRequestOptions } from '../common'
import {
  listServiceProvidersClient,
  listServiceSubscriptionsClient
} from './client'
import { servicesKeys } from './query-keys'
import { mapServiceProviderListResponse } from './adapter'

export const servicesQueries = {
  list: (options?: { clientOptions?: ClientRequestOptions }) => ({
    queryKey: servicesKeys.list(),
    queryFn: async () => {
      const response = await listServiceProvidersClient(options?.clientOptions)
      return mapServiceProviderListResponse(response)
    }
  }),
  subscriptions: (options?: { clientOptions?: ClientRequestOptions }) => ({
    queryKey: servicesKeys.subscriptions(),
    queryFn: () => listServiceSubscriptionsClient(options?.clientOptions)
  })
}

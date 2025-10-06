import type { ClientRequestOptions } from '../common'
import { currentUserClient, listIdentitiesClient } from './client'
import { authKeys } from './query-keys'

export const authQueries = {
  currentUser: (options?: { clientOptions?: ClientRequestOptions }) => ({
    queryKey: authKeys.currentUser(),
    queryFn: () => currentUserClient(options?.clientOptions)
  }),
  identities: (options?: { clientOptions?: ClientRequestOptions }) => ({
    queryKey: authKeys.identities(),
    queryFn: () => listIdentitiesClient(options?.clientOptions)
  })
}

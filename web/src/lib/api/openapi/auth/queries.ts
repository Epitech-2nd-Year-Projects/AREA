import type { ClientRequestOptions } from '../common'
import { currentUserClient } from './client'
import { authKeys } from './query-keys'

export const authQueries = {
  currentUser: (options?: { clientOptions?: ClientRequestOptions }) => ({
    queryKey: authKeys.currentUser(),
    queryFn: () => currentUserClient(options?.clientOptions)
  })
}

import type { ClientRequestOptions } from '../common'
import { aboutKeys } from './query-keys'
import { fetchAboutClient } from './client'

export const aboutQueries = {
  detail: (options?: { clientOptions?: ClientRequestOptions }) => ({
    queryKey: aboutKeys.detail(),
    queryFn: () => fetchAboutClient(options?.clientOptions)
  })
}

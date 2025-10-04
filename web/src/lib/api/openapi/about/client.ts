import { apiFetchClient } from '../../http/client'
import { buildClientOptions } from '../common'
import type { ClientRequestOptions } from '../common'
import type { AboutResponseDTO } from '@/lib/api/contracts/openapi/about'
import { apiRuntime } from '@/lib/api/runtime'
import { getAboutMock } from '@/lib/api/mock/about'

export function fetchAboutClient(options?: ClientRequestOptions) {
  if (apiRuntime.useMocks) {
    return getAboutMock()
  }
  return apiFetchClient<AboutResponseDTO>(
    '/about.json',
    buildClientOptions(options)
  )
}

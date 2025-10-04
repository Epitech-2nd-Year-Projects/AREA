import { apiFetchServer } from '../../http/server'
import { buildServerOptions } from '../common'
import type { ServerRequestOptions } from '../common'
import type { AboutResponseDTO } from '@/lib/api/contracts/openapi/about'
import { apiRuntime } from '@/lib/api/runtime'
import { getAboutMock } from '@/lib/api/mock/about'

export function fetchAboutServer(options?: ServerRequestOptions) {
  if (apiRuntime.useMocks) {
    return getAboutMock()
  }
  return apiFetchServer<AboutResponseDTO>(
    '/about.json',
    buildServerOptions(options)
  )
}

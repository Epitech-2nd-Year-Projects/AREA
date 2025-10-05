import { useQuery, type UseQueryOptions } from '@tanstack/react-query'
import { ApiError } from '../../http/errors'
import type { ClientRequestOptions } from '../common'
import type { AboutResponseDTO } from '@/lib/api/contracts/openapi/about'
import { aboutKeys } from './query-keys'
import { fetchAboutClient } from './client'

type AboutQueryOptions = {
  clientOptions?: ClientRequestOptions
} & Omit<
  UseQueryOptions<
    AboutResponseDTO,
    ApiError,
    AboutResponseDTO,
    ReturnType<typeof aboutKeys.detail>
  >,
  'queryKey' | 'queryFn'
>

export function useAboutQuery(options?: AboutQueryOptions) {
  const { clientOptions, ...queryOptions } = options ?? {}
  return useQuery({
    queryKey: aboutKeys.detail(),
    queryFn: () => fetchAboutClient(clientOptions),
    ...queryOptions
  })
}

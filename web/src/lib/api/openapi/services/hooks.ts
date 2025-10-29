import { useQuery, type UseQueryOptions } from '@tanstack/react-query'
import { ApiError } from '../../http/errors'
import type { ClientRequestOptions } from '../common'
import type { Service } from '@/lib/api/contracts/services'
import { servicesKeys } from './query-keys'
import { servicesQueries } from './queries'

type ServiceProvidersQueryOptions = {
  clientOptions?: ClientRequestOptions
} & Omit<
  UseQueryOptions<
    Service[],
    ApiError,
    Service[],
    ReturnType<typeof servicesKeys.list>
  >,
  'queryKey' | 'queryFn'
>

export function useServiceProvidersQuery(
  options?: ServiceProvidersQueryOptions
) {
  const { clientOptions, ...queryOptions } = options ?? {}
  return useQuery({
    ...servicesQueries.list({ clientOptions }),
    ...queryOptions
  })
}

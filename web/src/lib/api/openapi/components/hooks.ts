import { useQuery, type UseQueryOptions } from '@tanstack/react-query'
import type { ApiError } from '../../http/errors'
import type { ClientRequestOptions } from '../common'
import type { ComponentSummaryDTO } from '@/lib/api/contracts/openapi/areas'
import { componentsQueries } from './queries'
import { componentsKeys } from './query-keys'

type AvailableComponentsOptions = {
  params?: { kind?: 'action' | 'reaction'; provider?: string }
  clientOptions?: ClientRequestOptions
} & Omit<
  UseQueryOptions<
    ComponentSummaryDTO[],
    ApiError,
    ComponentSummaryDTO[],
    ReturnType<typeof componentsKeys.available>
  >,
  'queryKey' | 'queryFn'
>

export function useAvailableComponentsQuery(
  options?: AvailableComponentsOptions
) {
  const { clientOptions, meta, ...queryOptions } = options ?? {}
  return useQuery({
    ...componentsQueries.available({
      params: options?.params,
      clientOptions
    }),
    meta: { redirectOn401: true, ...(meta ?? {}) },
    ...queryOptions
  })
}

type ComponentsOptions = {
  params?: { kind?: 'action' | 'reaction'; provider?: string }
  clientOptions?: ClientRequestOptions
} & Omit<
  UseQueryOptions<
    ComponentSummaryDTO[],
    ApiError,
    ComponentSummaryDTO[],
    ReturnType<typeof componentsKeys.list>
  >,
  'queryKey' | 'queryFn'
>

export function useComponentsQuery(options?: ComponentsOptions) {
  const { clientOptions, meta, ...queryOptions } = options ?? {}
  return useQuery({
    ...componentsQueries.list({
      params: options?.params,
      clientOptions
    }),
    meta: { ...(meta ?? {}) },
    ...queryOptions
  })
}

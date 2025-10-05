import {
  useMutation,
  useQuery,
  useQueryClient,
  type UseMutationOptions,
  type UseQueryOptions
} from '@tanstack/react-query'
import { ApiError } from '../../http/errors'
import type { ClientRequestOptions } from '../common'
import type { Area } from '@/lib/api/contracts/areas'
import type { CreateAreaRequestDTO } from '@/lib/api/contracts/openapi/areas'
import { areasQueries } from './queries'
import { areasMutations } from './mutations'
import { areasKeys } from './query-keys'

type AreasQueryOptions = {
  clientOptions?: ClientRequestOptions
} & Omit<
  UseQueryOptions<Area[], ApiError, Area[], ReturnType<typeof areasKeys.list>>,
  'queryKey' | 'queryFn'
>

type CreateAreaMutationOptions = {
  clientOptions?: ClientRequestOptions
} & Omit<
  UseMutationOptions<Area, ApiError, CreateAreaRequestDTO, unknown>,
  'mutationFn' | 'mutationKey'
>

export function useAreasQuery(options?: AreasQueryOptions) {
  const { clientOptions, meta, ...queryOptions } = options ?? {}
  return useQuery({
    ...areasQueries.list({ clientOptions }),
    meta: { redirectOn401: true, ...(meta ?? {}) },
    ...queryOptions
  })
}

export function useCreateAreaMutation(options?: CreateAreaMutationOptions) {
  const queryClient = useQueryClient()
  const { clientOptions, onSuccess, ...mutationOptions } = options ?? {}
  return useMutation({
    ...areasMutations.create({ clientOptions }),
    onSuccess: async (data, variables, context, mutation) => {
      await queryClient.invalidateQueries({ queryKey: areasKeys.list() })
      if (onSuccess) {
        await onSuccess(data, variables, context, mutation)
      }
    },
    ...mutationOptions
  })
}

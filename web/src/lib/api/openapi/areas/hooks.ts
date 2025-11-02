import {
  useMutation,
  useQuery,
  useQueryClient,
  type UseMutationOptions,
  type UseQueryOptions
} from '@tanstack/react-query'
import { ApiError } from '../../http/errors'
import type { ClientRequestOptions } from '../common'
import type { Area, AreaHistoryEntry } from '@/lib/api/contracts/areas'
import type {
  CreateAreaRequestDTO,
  DuplicateAreaRequestDTO,
  UpdateAreaRequestDTO,
  UpdateAreaStatusRequestDTO
} from '@/lib/api/contracts/openapi/areas'
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

type UpdateAreaMutationOptions = {
  clientOptions?: ClientRequestOptions
} & Omit<
  UseMutationOptions<Area, ApiError, UpdateAreaRequestDTO, unknown>,
  'mutationFn' | 'mutationKey'
>

type UpdateAreaStatusMutationOptions = {
  clientOptions?: ClientRequestOptions
} & Omit<
  UseMutationOptions<Area, ApiError, UpdateAreaStatusRequestDTO, unknown>,
  'mutationFn' | 'mutationKey'
>

type DuplicateAreaMutationOptions = {
  clientOptions?: ClientRequestOptions
} & Omit<
  UseMutationOptions<
    Area,
    ApiError,
    DuplicateAreaRequestDTO | undefined,
    unknown
  >,
  'mutationFn' | 'mutationKey'
>

type DeleteAreaMutationOptions = {
  clientOptions?: ClientRequestOptions
} & Omit<
  UseMutationOptions<void, ApiError, void, unknown>,
  'mutationFn' | 'mutationKey'
>

type ExecuteAreaMutationOptions = {
  clientOptions?: ClientRequestOptions
} & Omit<
  UseMutationOptions<void, ApiError, void, unknown>,
  'mutationFn' | 'mutationKey'
>

type AreaHistoryQueryOptions = {
  limit?: number
  clientOptions?: ClientRequestOptions
} & Omit<
  UseQueryOptions<
    AreaHistoryEntry[],
    ApiError,
    AreaHistoryEntry[],
    ReturnType<typeof areasKeys.history>
  >,
  'queryKey' | 'queryFn'
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

export function useUpdateAreaMutation(
  areaId: string,
  options?: UpdateAreaMutationOptions
) {
  const queryClient = useQueryClient()
  const { clientOptions, onSuccess, ...mutationOptions } = options ?? {}
  return useMutation({
    ...areasMutations.update(areaId, { clientOptions }),
    onSuccess: async (data, variables, context, mutation) => {
      await Promise.all([
        queryClient.invalidateQueries({ queryKey: areasKeys.list() }),
        queryClient.invalidateQueries({ queryKey: areasKeys.detail(areaId) })
      ])
      if (onSuccess) {
        await onSuccess(data, variables, context, mutation)
      }
    },
    ...mutationOptions
  })
}

export function useUpdateAreaStatusMutation(
  areaId: string,
  options?: UpdateAreaStatusMutationOptions
) {
  const queryClient = useQueryClient()
  const { clientOptions, onSuccess, ...mutationOptions } = options ?? {}
  return useMutation({
    ...areasMutations.updateStatus(areaId, { clientOptions }),
    onSuccess: async (data, variables, context, mutation) => {
      await Promise.all([
        queryClient.invalidateQueries({ queryKey: areasKeys.list() }),
        queryClient.invalidateQueries({ queryKey: areasKeys.detail(areaId) })
      ])
      if (onSuccess) {
        await onSuccess(data, variables, context, mutation)
      }
    },
    ...mutationOptions
  })
}

export function useDuplicateAreaMutation(
  areaId: string,
  options?: DuplicateAreaMutationOptions
) {
  const queryClient = useQueryClient()
  const { clientOptions, onSuccess, ...mutationOptions } = options ?? {}
  return useMutation({
    ...areasMutations.duplicate(areaId, { clientOptions }),
    onSuccess: async (data, variables, context, mutation) => {
      await queryClient.invalidateQueries({ queryKey: areasKeys.list() })
      if (onSuccess) {
        await onSuccess(data, variables, context, mutation)
      }
    },
    ...mutationOptions
  })
}

export function useDeleteAreaMutation(
  areaId: string,
  options?: DeleteAreaMutationOptions
) {
  const queryClient = useQueryClient()
  const { clientOptions, onSuccess, ...mutationOptions } = options ?? {}
  return useMutation({
    ...areasMutations.delete(areaId, { clientOptions }),
    onSuccess: async (data, variables, context, mutation) => {
      await Promise.all([
        queryClient.invalidateQueries({ queryKey: areasKeys.list() }),
        queryClient.invalidateQueries({ queryKey: areasKeys.detail(areaId) })
      ])
      if (onSuccess) {
        await onSuccess(data, variables, context, mutation)
      }
    },
    ...mutationOptions
  })
}

export function useExecuteAreaMutation(
  areaId: string,
  options?: ExecuteAreaMutationOptions
) {
  const queryClient = useQueryClient()
  const { clientOptions, onSuccess, ...mutationOptions } = options ?? {}
  return useMutation({
    ...areasMutations.execute(areaId, { clientOptions }),
    onSuccess: async (data, variables, context, mutation) => {
      await queryClient.invalidateQueries({
        queryKey: areasKeys.history(areaId)
      })
      if (onSuccess) {
        await onSuccess(data, variables, context, mutation)
      }
    },
    ...mutationOptions
  })
}

export function useAreaHistoryQuery(
  areaId: string,
  options?: AreaHistoryQueryOptions
) {
  const { clientOptions, limit, meta, ...queryOptions } = options ?? {}
  return useQuery({
    ...areasQueries.history(areaId, { limit, clientOptions }),
    meta: { redirectOn401: true, ...(meta ?? {}) },
    ...queryOptions
  })
}

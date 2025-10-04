import {
  useMutation,
  useQuery,
  useQueryClient,
  type UseMutationOptions,
  type UseQueryOptions
} from '@tanstack/react-query'
import { ApiError } from '../../http/errors'
import type { ClientRequestOptions } from '../common'
import {
  AuthSessionResponseDTO,
  LoginRequestDTO,
  UserResponseDTO,
  VerifyEmailRequestDTO
} from '@/lib/api/contracts/openapi/auth'
import { authKeys } from './query-keys'
import { authQueries } from './queries'
import { authMutations, invalidateAuthUser } from './mutations'

type CurrentUserQueryOptions = {
  clientOptions?: ClientRequestOptions
} & Omit<
  UseQueryOptions<
    UserResponseDTO,
    ApiError,
    UserResponseDTO,
    ReturnType<typeof authKeys.currentUser>
  >,
  'queryKey' | 'queryFn'
>

type AuthSessionMutationOptions<Variables> = {
  clientOptions?: ClientRequestOptions
} & Omit<
  UseMutationOptions<AuthSessionResponseDTO, ApiError, Variables, unknown>,
  'mutationFn' | 'mutationKey'
>

type LogoutMutationOptions = {
  clientOptions?: ClientRequestOptions
} & Omit<
  UseMutationOptions<void, ApiError, void, unknown>,
  'mutationFn' | 'mutationKey'
>

export function useCurrentUserQuery(options?: CurrentUserQueryOptions) {
  const { clientOptions, ...queryOptions } = options ?? {}
  return useQuery({
    ...authQueries.currentUser({ clientOptions }),
    ...queryOptions
  })
}

export function useLoginMutation(
  options?: AuthSessionMutationOptions<LoginRequestDTO>
) {
  const queryClient = useQueryClient()
  const { clientOptions, onSuccess, ...mutationOptions } = options ?? {}
  return useMutation({
    ...authMutations.login({ clientOptions }),
    onSuccess: async (data, variables, context, mutation) => {
      await invalidateAuthUser(queryClient)
      if (onSuccess) {
        await onSuccess(data, variables, context, mutation)
      }
    },
    ...mutationOptions
  })
}

export function useVerifyEmailMutation(
  options?: AuthSessionMutationOptions<VerifyEmailRequestDTO>
) {
  const queryClient = useQueryClient()
  const { clientOptions, onSuccess, ...mutationOptions } = options ?? {}
  return useMutation({
    ...authMutations.verifyEmail({ clientOptions }),
    onSuccess: async (data, variables, context, mutation) => {
      await invalidateAuthUser(queryClient)
      if (onSuccess) {
        await onSuccess(data, variables, context, mutation)
      }
    },
    ...mutationOptions
  })
}

export function useLogoutMutation(options?: LogoutMutationOptions) {
  const queryClient = useQueryClient()
  const { clientOptions, onSuccess, ...mutationOptions } = options ?? {}
  return useMutation({
    ...authMutations.logout({ clientOptions }),
    onSuccess: async (data, variables, context, mutation) => {
      await invalidateAuthUser(queryClient)
      if (onSuccess) {
        await onSuccess(data, variables, context, mutation)
      }
    },
    ...mutationOptions
  })
}

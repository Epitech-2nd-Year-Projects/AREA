import { useMutation, type UseMutationOptions } from '@tanstack/react-query'
import { ApiError } from '../../http/errors'
import type { ClientRequestOptions } from '../common'
import type {
  RegisterUserRequestDTO,
  RegisterUserResponseDTO
} from '@/lib/api/contracts/openapi/users'
import type {
  UserResponseDTO,
  EmailChangeResponseDTO
} from '@/lib/api/contracts/openapi/auth'
import {
  userMutations,
  type AdminResetUserPasswordVariables,
  type AdminUpdateUserEmailVariables,
  type AdminUpdateUserStatusVariables
} from './mutations'

export type RegisterUserMutationOptions = {
  clientOptions?: ClientRequestOptions
} & Omit<
  UseMutationOptions<
    RegisterUserResponseDTO,
    ApiError,
    RegisterUserRequestDTO,
    unknown
  >,
  'mutationFn' | 'mutationKey'
>

export type AdminResetUserPasswordMutationOptions = {
  clientOptions?: ClientRequestOptions
} & Omit<
  UseMutationOptions<
    UserResponseDTO,
    ApiError,
    AdminResetUserPasswordVariables,
    unknown
  >,
  'mutationFn' | 'mutationKey'
>

export type AdminUpdateUserEmailMutationOptions = {
  clientOptions?: ClientRequestOptions
} & Omit<
  UseMutationOptions<
    EmailChangeResponseDTO,
    ApiError,
    AdminUpdateUserEmailVariables,
    unknown
  >,
  'mutationFn' | 'mutationKey'
>

export type AdminUpdateUserStatusMutationOptions = {
  clientOptions?: ClientRequestOptions
} & Omit<
  UseMutationOptions<
    UserResponseDTO,
    ApiError,
    AdminUpdateUserStatusVariables,
    unknown
  >,
  'mutationFn' | 'mutationKey'
>

export function useRegisterUserMutation(options?: RegisterUserMutationOptions) {
  const { clientOptions, ...mutationOptions } = options ?? {}
  return useMutation({
    ...userMutations.register({ clientOptions }),
    ...mutationOptions
  })
}

export function useAdminResetUserPasswordMutation(
  options?: AdminResetUserPasswordMutationOptions
) {
  const { clientOptions, ...mutationOptions } = options ?? {}
  return useMutation({
    ...userMutations.adminResetUserPassword({ clientOptions }),
    ...mutationOptions
  })
}

export function useAdminUpdateUserEmailMutation(
  options?: AdminUpdateUserEmailMutationOptions
) {
  const { clientOptions, ...mutationOptions } = options ?? {}
  return useMutation({
    ...userMutations.adminUpdateUserEmail({ clientOptions }),
    ...mutationOptions
  })
}

export function useAdminUpdateUserStatusMutation(
  options?: AdminUpdateUserStatusMutationOptions
) {
  const { clientOptions, ...mutationOptions } = options ?? {}
  return useMutation({
    ...userMutations.adminUpdateUserStatus({ clientOptions }),
    ...mutationOptions
  })
}

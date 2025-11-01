import type { ClientRequestOptions } from '../common'
import {
  registerUserClient,
  adminResetUserPasswordClient,
  adminUpdateUserEmailClient,
  adminUpdateUserStatusClient
} from './client'
import { userMutationKeys } from './keys'
import type {
  RegisterUserRequestDTO,
  AdminResetPasswordRequestDTO,
  AdminUpdateEmailRequestDTO,
  AdminUpdateStatusRequestDTO
} from '@/lib/api/contracts/openapi/users'

export const userMutations = {
  register: (options?: { clientOptions?: ClientRequestOptions }) => ({
    mutationKey: userMutationKeys.register(),
    mutationFn: (variables: RegisterUserRequestDTO) =>
      registerUserClient(variables, options?.clientOptions)
  }),
  adminResetUserPassword: (options?: {
    clientOptions?: ClientRequestOptions
  }) => ({
    mutationKey: userMutationKeys.adminResetUserPassword(),
    mutationFn: (variables: AdminResetUserPasswordVariables) =>
      adminResetUserPasswordClient(
        variables.userId,
        variables.body,
        options?.clientOptions
      )
  }),
  adminUpdateUserEmail: (options?: {
    clientOptions?: ClientRequestOptions
  }) => ({
    mutationKey: userMutationKeys.adminUpdateUserEmail(),
    mutationFn: (variables: AdminUpdateUserEmailVariables) =>
      adminUpdateUserEmailClient(
        variables.userId,
        variables.body,
        options?.clientOptions
      )
  }),
  adminUpdateUserStatus: (options?: {
    clientOptions?: ClientRequestOptions
  }) => ({
    mutationKey: userMutationKeys.adminUpdateUserStatus(),
    mutationFn: (variables: AdminUpdateUserStatusVariables) =>
      adminUpdateUserStatusClient(
        variables.userId,
        variables.body,
        options?.clientOptions
      )
  })
}

export type AdminUserMutationVariables = {
  userId: string
}

export type AdminResetUserPasswordVariables = AdminUserMutationVariables & {
  body: AdminResetPasswordRequestDTO
}

export type AdminUpdateUserEmailVariables = AdminUserMutationVariables & {
  body: AdminUpdateEmailRequestDTO
}

export type AdminUpdateUserStatusVariables = AdminUserMutationVariables & {
  body: AdminUpdateStatusRequestDTO
}

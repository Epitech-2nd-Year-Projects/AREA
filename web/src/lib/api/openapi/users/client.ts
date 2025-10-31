import { apiFetchClient } from '../../http/client'
import { buildClientOptions } from '../common'
import type { ClientRequestOptions } from '../common'
import type {
  RegisterUserRequestDTO,
  RegisterUserResponseDTO,
  AdminResetPasswordRequestDTO,
  AdminUpdateEmailRequestDTO,
  AdminUpdateStatusRequestDTO
} from '@/lib/api/contracts/openapi/users'
import type {
  UserResponseDTO,
  EmailChangeResponseDTO
} from '@/lib/api/contracts/openapi/auth'
import { apiRuntime } from '@/lib/api/runtime'
import { registerUserMock } from '@/lib/api/mock/users'

export function registerUserClient(
  body: RegisterUserRequestDTO,
  options?: ClientRequestOptions
) {
  if (apiRuntime.useMocks) {
    return registerUserMock(body)
  }
  return apiFetchClient<RegisterUserResponseDTO>('/v1/users', {
    method: 'POST',
    body,
    ...buildClientOptions(options)
  })
}

export function adminResetUserPasswordClient(
  userId: string,
  body: AdminResetPasswordRequestDTO,
  options?: ClientRequestOptions
) {
  if (apiRuntime.useMocks) {
    throw new Error('adminResetUserPassword mock not implemented')
  }
  return apiFetchClient<UserResponseDTO>(`/v1/admin/users/${userId}/password`, {
    method: 'PATCH',
    body,
    ...buildClientOptions(options)
  })
}

export function adminUpdateUserEmailClient(
  userId: string,
  body: AdminUpdateEmailRequestDTO,
  options?: ClientRequestOptions
) {
  if (apiRuntime.useMocks) {
    throw new Error('adminUpdateUserEmail mock not implemented')
  }
  return apiFetchClient<EmailChangeResponseDTO>(
    `/v1/admin/users/${userId}/email`,
    {
      method: 'PATCH',
      body,
      ...buildClientOptions(options)
    }
  )
}

export function adminUpdateUserStatusClient(
  userId: string,
  body: AdminUpdateStatusRequestDTO,
  options?: ClientRequestOptions
) {
  if (apiRuntime.useMocks) {
    throw new Error('adminUpdateUserStatus mock not implemented')
  }
  return apiFetchClient<UserResponseDTO>(`/v1/admin/users/${userId}/status`, {
    method: 'PATCH',
    body,
    ...buildClientOptions(options)
  })
}

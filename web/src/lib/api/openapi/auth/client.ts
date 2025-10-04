import { apiFetchClient } from '../../http/client'
import { buildClientOptions } from '../common'
import type { ClientRequestOptions } from '../common'
import {
  AuthSessionResponseDTO,
  LoginRequestDTO,
  UserResponseDTO,
  VerifyEmailRequestDTO
} from '@/lib/api/contracts/openapi/auth'
import { apiRuntime } from '@/lib/api/runtime'
import {
  currentUserMock,
  loginMock,
  logoutMock,
  verifyEmailMock
} from '@/lib/api/mock/auth'

export function loginClient(
  body: LoginRequestDTO,
  options?: ClientRequestOptions
) {
  if (apiRuntime.useMocks) {
    return loginMock(body)
  }
  return apiFetchClient<AuthSessionResponseDTO>('/v1/auth/login', {
    method: 'POST',
    body,
    ...buildClientOptions(options)
  })
}

export function verifyEmailClient(
  body: VerifyEmailRequestDTO,
  options?: ClientRequestOptions
) {
  if (apiRuntime.useMocks) {
    return verifyEmailMock(body)
  }
  return apiFetchClient<AuthSessionResponseDTO>('/v1/auth/verify', {
    method: 'POST',
    body,
    ...buildClientOptions(options)
  })
}

export function logoutClient(options?: ClientRequestOptions) {
  if (apiRuntime.useMocks) {
    return logoutMock()
  }
  return apiFetchClient<void>('/v1/auth/logout', {
    method: 'POST',
    ...buildClientOptions(options)
  })
}

export function currentUserClient(options?: ClientRequestOptions) {
  if (apiRuntime.useMocks) {
    return currentUserMock()
  }
  return apiFetchClient<UserResponseDTO>(
    '/v1/auth/me',
    buildClientOptions(options)
  )
}

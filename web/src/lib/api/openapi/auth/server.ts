import { apiFetchServer } from '../../http/server'
import { buildServerOptions } from '../common'
import type { ServerRequestOptions } from '../common'
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

export function loginServer(
  body: LoginRequestDTO,
  options?: ServerRequestOptions
) {
  if (apiRuntime.useMocks) {
    return loginMock(body)
  }
  return apiFetchServer<AuthSessionResponseDTO>('/v1/auth/login', {
    method: 'POST',
    body,
    ...buildServerOptions(options)
  })
}

export function verifyEmailServer(
  body: VerifyEmailRequestDTO,
  options?: ServerRequestOptions
) {
  if (apiRuntime.useMocks) {
    return verifyEmailMock(body)
  }
  return apiFetchServer<AuthSessionResponseDTO>('/v1/auth/verify', {
    method: 'POST',
    body,
    ...buildServerOptions(options)
  })
}

export function logoutServer(options?: ServerRequestOptions) {
  if (apiRuntime.useMocks) {
    return logoutMock()
  }
  return apiFetchServer<void>('/v1/auth/logout', {
    method: 'POST',
    ...buildServerOptions(options)
  })
}

export function currentUserServer(options?: ServerRequestOptions) {
  if (apiRuntime.useMocks) {
    return currentUserMock()
  }
  return apiFetchServer<UserResponseDTO>(
    '/v1/auth/me',
    buildServerOptions(options)
  )
}

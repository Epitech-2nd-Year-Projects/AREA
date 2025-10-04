import { apiFetchServer } from '../../http/server'
import { buildServerOptions } from '../common'
import type { ServerRequestOptions } from '../common'
import {
  AuthSessionResponseDTO,
  LoginRequestDTO,
  OAuthAuthorizationRequestDTO,
  OAuthAuthorizationResponseDTO,
  OAuthExchangeRequestDTO,
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

export function authorizeOAuthServer(
  provider: string,
  body?: OAuthAuthorizationRequestDTO,
  options?: ServerRequestOptions
) {
  if (apiRuntime.useMocks) {
    throw new Error('OAuth authorize mock not implemented')
  }
  return apiFetchServer<OAuthAuthorizationResponseDTO>(
    `/v1/oauth/${provider}/authorize`,
    {
      method: 'POST',
      body,
      ...buildServerOptions(options)
    }
  )
}

export function exchangeOAuthServer(
  provider: string,
  body: OAuthExchangeRequestDTO,
  options?: ServerRequestOptions
) {
  if (apiRuntime.useMocks) {
    throw new Error('OAuth exchange mock not implemented')
  }
  return apiFetchServer<AuthSessionResponseDTO>(
    `/v1/oauth/${provider}/exchange`,
    {
      method: 'POST',
      body,
      ...buildServerOptions(options)
    }
  )
}

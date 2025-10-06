import { apiFetchClient } from '../../http/client'
import { buildClientOptions } from '../common'
import type { ClientRequestOptions } from '../common'
import {
  AuthSessionResponseDTO,
  LoginRequestDTO,
  OAuthAuthorizationRequestDTO,
  OAuthAuthorizationResponseDTO,
  OAuthExchangeRequestDTO,
  IdentityListResponseDTO,
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

export function listIdentitiesClient(options?: ClientRequestOptions) {
  if (apiRuntime.useMocks) {
    throw new Error('Identities mock not implemented')
  }
  return apiFetchClient<IdentityListResponseDTO>(
    '/v1/identities',
    buildClientOptions(options)
  )
}

export function authorizeOAuthClient(
  provider: string,
  body?: OAuthAuthorizationRequestDTO,
  options?: ClientRequestOptions
) {
  if (apiRuntime.useMocks) {
    throw new Error('OAuth authorize mock not implemented')
  }
  return apiFetchClient<OAuthAuthorizationResponseDTO>(
    `/v1/oauth/${provider}/authorize`,
    {
      method: 'POST',
      body,
      ...buildClientOptions(options)
    }
  )
}

export function exchangeOAuthClient(
  provider: string,
  body: OAuthExchangeRequestDTO,
  options?: ClientRequestOptions
) {
  if (apiRuntime.useMocks) {
    throw new Error('OAuth exchange mock not implemented')
  }
  return apiFetchClient<AuthSessionResponseDTO>(
    `/v1/oauth/${provider}/exchange`,
    {
      method: 'POST',
      body,
      ...buildClientOptions(options)
    }
  )
}

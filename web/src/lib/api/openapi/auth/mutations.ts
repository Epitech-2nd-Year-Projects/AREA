import type { ClientRequestOptions } from '../common'
import {
  authorizeOAuthClient,
  exchangeOAuthClient,
  loginClient,
  logoutClient,
  verifyEmailClient,
  changePasswordClient,
  changeEmailClient
} from './client'
import { authMutationKeys, authKeys } from './query-keys'
import type {
  LoginRequestDTO,
  OAuthAuthorizationRequestDTO,
  OAuthExchangeRequestDTO,
  VerifyEmailRequestDTO,
  ChangePasswordRequestDTO,
  ChangeEmailRequestDTO
} from '@/lib/api/contracts/openapi/auth'
import type { QueryClient } from '@tanstack/react-query'

export type AuthorizeOAuthVariables = {
  provider: string
  body?: OAuthAuthorizationRequestDTO
}

export type ExchangeOAuthVariables = {
  provider: string
  body: OAuthExchangeRequestDTO
}

export const authMutations = {
  login: (options?: { clientOptions?: ClientRequestOptions }) => ({
    mutationKey: authMutationKeys.login(),
    mutationFn: (variables: LoginRequestDTO) =>
      loginClient(variables, options?.clientOptions)
  }),
  verifyEmail: (options?: { clientOptions?: ClientRequestOptions }) => ({
    mutationKey: authMutationKeys.verifyEmail(),
    mutationFn: (variables: VerifyEmailRequestDTO) =>
      verifyEmailClient(variables, options?.clientOptions)
  }),
  logout: (options?: { clientOptions?: ClientRequestOptions }) => ({
    mutationKey: authMutationKeys.logout(),
    mutationFn: () => logoutClient(options?.clientOptions)
  }),
  authorizeOAuth: (options?: { clientOptions?: ClientRequestOptions }) => ({
    mutationKey: authMutationKeys.authorizeOAuth(),
    mutationFn: (variables: AuthorizeOAuthVariables) =>
      authorizeOAuthClient(
        variables.provider,
        variables.body,
        options?.clientOptions
      )
  }),
  exchangeOAuth: (options?: { clientOptions?: ClientRequestOptions }) => ({
    mutationKey: authMutationKeys.exchangeOAuth(),
    mutationFn: (variables: ExchangeOAuthVariables) =>
      exchangeOAuthClient(
        variables.provider,
        variables.body,
        options?.clientOptions
      )
  }),
  changePassword: (options?: { clientOptions?: ClientRequestOptions }) => ({
    mutationKey: authMutationKeys.changePassword(),
    mutationFn: (variables: ChangePasswordRequestDTO) =>
      changePasswordClient(variables, options?.clientOptions)
  }),
  changeEmail: (options?: { clientOptions?: ClientRequestOptions }) => ({
    mutationKey: authMutationKeys.changeEmail(),
    mutationFn: (variables: ChangeEmailRequestDTO) =>
      changeEmailClient(variables, options?.clientOptions)
  })
}

export async function invalidateAuthUser(queryClient: QueryClient) {
  await queryClient.invalidateQueries({ queryKey: authKeys.currentUser() })
}

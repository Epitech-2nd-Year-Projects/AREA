import type { ClientRequestOptions } from '../common'
import { loginClient, logoutClient, verifyEmailClient } from './client'
import { authMutationKeys, authKeys } from './query-keys'
import type {
  LoginRequestDTO,
  VerifyEmailRequestDTO
} from '@/lib/api/contracts/openapi/auth'
import type { QueryClient } from '@tanstack/react-query'

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
  })
}

export async function invalidateAuthUser(queryClient: QueryClient) {
  await queryClient.invalidateQueries({ queryKey: authKeys.currentUser() })
}

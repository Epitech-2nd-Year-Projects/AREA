import { useMutation, type UseMutationOptions } from '@tanstack/react-query'
import { ApiError } from '../../http/errors'
import type { ClientRequestOptions } from '../common'
import type {
  RegisterUserRequestDTO,
  RegisterUserResponseDTO
} from '@/lib/api/contracts/openapi/users'
import { userMutations } from './mutations'

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

export function useRegisterUserMutation(options?: RegisterUserMutationOptions) {
  const { clientOptions, ...mutationOptions } = options ?? {}
  return useMutation({
    ...userMutations.register({ clientOptions }),
    ...mutationOptions
  })
}

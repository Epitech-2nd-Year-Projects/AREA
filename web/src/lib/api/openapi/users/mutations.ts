import type { ClientRequestOptions } from '../common'
import { registerUserClient } from './client'
import { userMutationKeys } from './keys'
import type { RegisterUserRequestDTO } from '@/lib/api/contracts/openapi/users'

export const userMutations = {
  register: (options?: { clientOptions?: ClientRequestOptions }) => ({
    mutationKey: userMutationKeys.register(),
    mutationFn: (variables: RegisterUserRequestDTO) =>
      registerUserClient(variables, options?.clientOptions)
  })
}

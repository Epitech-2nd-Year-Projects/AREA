import { apiFetchClient } from '../../http/client'
import { buildClientOptions } from '../common'
import type { ClientRequestOptions } from '../common'
import type {
  RegisterUserRequestDTO,
  RegisterUserResponseDTO
} from '@/lib/api/contracts/openapi/users'
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

import { apiFetchServer } from '../../http/server'
import { buildServerOptions } from '../common'
import type { ServerRequestOptions } from '../common'
import type {
  RegisterUserRequestDTO,
  RegisterUserResponseDTO
} from '@/lib/api/contracts/openapi/users'
import { apiRuntime } from '@/lib/api/runtime'
import { registerUserMock } from '@/lib/api/mock/users'

export function registerUserServer(
  body: RegisterUserRequestDTO,
  options?: ServerRequestOptions
) {
  if (apiRuntime.useMocks) {
    return registerUserMock(body)
  }
  return apiFetchServer<RegisterUserResponseDTO>('/v1/users', {
    method: 'POST',
    body,
    ...buildServerOptions(options)
  })
}

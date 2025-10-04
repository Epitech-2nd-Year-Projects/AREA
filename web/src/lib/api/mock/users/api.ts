import { ApiError } from '@/lib/api/http/errors'
import { markPendingVerification, issueVerificationToken } from '../state'
import { mockRegisterUser, mockUsers } from '../data'
import type {
  RegisterUserRequestDTO,
  RegisterUserResponseDTO
} from '@/lib/api/openapi/users'

export async function registerUserMock(
  body: RegisterUserRequestDTO
): Promise<RegisterUserResponseDTO> {
  const result = await mockRegisterUser(body)

  if (result.status === 'error') {
    if (result.code === 'EMAIL_IN_USE') {
      throw new ApiError(409, 'email_already_registered', result.message)
    }
    throw new ApiError(500, 'unknown_error', result.message)
  }

  const user = mockUsers.find((candidate) => candidate.email === result.email)
  if (!user) {
    throw new ApiError(500, 'unknown_error', 'User registration failed')
  }

  markPendingVerification(user)
  const { expiresAt } = issueVerificationToken(user.email)

  return {
    expires_at: new Date(expiresAt).toISOString()
  }
}

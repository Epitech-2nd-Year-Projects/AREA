import { ApiError } from '@/lib/api/http/errors'
import {
  consumeVerificationToken,
  markActiveUser,
  setCurrentSession,
  clearSession,
  assertSession,
  toUserDTO,
  issueVerificationToken
} from '../state'
import { mockLoginUser, mockMarkUserEmailVerified } from '../data'
import type {
  AuthSessionResponseDTO,
  LoginRequestDTO,
  UserResponseDTO,
  VerifyEmailRequestDTO
} from '@/lib/api/openapi/auth'

export async function loginMock(
  body: LoginRequestDTO
): Promise<AuthSessionResponseDTO> {
  const result = await mockLoginUser(body)

  if (result.status === 'error') {
    const code =
      result.code === 'INVALID_CREDENTIALS'
        ? 'invalidCredentials'
        : 'unknownError'
    throw new ApiError(400, code, result.message)
  }

  if (result.status === 'unverified') {
    const { expiresAt } = issueVerificationToken(result.email)
    console.info(
      `[mock-api] Verification token for ${result.email} renewed (expires ${new Date(expiresAt).toISOString()})`
    )
    throw new ApiError(
      403,
      'accountRequiresVerification',
      'Account requires verification'
    )
  }

  const user = result.user
  markActiveUser(user)
  setCurrentSession(user.email)

  return { user: toUserDTO(user) }
}

export async function verifyEmailMock(
  body: VerifyEmailRequestDTO
): Promise<AuthSessionResponseDTO> {
  const email = consumeVerificationToken(body.token)
  const user = mockMarkUserEmailVerified(email)

  if (!user) {
    throw new ApiError(400, 'invalidToken', 'Invalid token')
  }

  markActiveUser(user)
  setCurrentSession(user.email)

  return { user: toUserDTO(user) }
}

export async function logoutMock(): Promise<void> {
  clearSession()
}

export async function currentUserMock(): Promise<UserResponseDTO> {
  const user = assertSession()
  return { user: toUserDTO(user) }
}

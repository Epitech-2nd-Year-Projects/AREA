import { ApiError } from '@/lib/api/http/errors'
import {
  consumeVerificationToken,
  markActiveUser,
  setCurrentSession,
  clearSession,
  assertSession,
  toUserDTO,
  issueVerificationToken,
  currentSessionExpiry
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
  const expiresAt = setCurrentSession(user.email)

  return {
    tokenType: 'session',
    expiresAt: new Date(expiresAt ?? Date.now()).toISOString(),
    user: toUserDTO(user)
  }
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
  const expiresAt = setCurrentSession(user.email)

  return {
    tokenType: 'session',
    expiresAt: new Date(expiresAt ?? Date.now()).toISOString(),
    user: toUserDTO(user)
  }
}

export async function logoutMock(): Promise<void> {
  clearSession()
}

export async function currentUserMock(): Promise<UserResponseDTO> {
  const user = assertSession()
  const expiresAt = currentSessionExpiry()
  if (expiresAt && expiresAt < Date.now()) {
    clearSession()
    throw new ApiError(401, 'notAuthenticated', 'Session missing or expired')
  }
  return { user: toUserDTO(user) }
}

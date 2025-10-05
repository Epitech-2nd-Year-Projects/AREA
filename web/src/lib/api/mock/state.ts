import { ApiError } from '@/lib/api/http/errors'
import type { User } from '@/lib/api/contracts/users'
import type { UserDTO } from '@/lib/api/openapi/auth'
import { mockUsers } from './data'

const TOKEN_PREFIX = 'mock-token:'
const FIFTEEN_MINUTES_IN_MS = 15 * 60 * 1000

const verificationTokens = new Map<
  string,
  { email: string; expiresAt: number }
>()
const userMeta = new Map<
  string,
  {
    createdAt: number
    updatedAt: number
    lastLoginAt: number | null
    status: string
  }
>()
let currentSessionEmail: string | null = null

const now = () => Date.now()

export function ensureUserMeta(user: User) {
  let meta = userMeta.get(user.email)
  if (!meta) {
    meta = {
      createdAt: now(),
      updatedAt: now(),
      lastLoginAt: user.emailVerified ? now() : null,
      status: user.emailVerified ? 'active' : 'pendingVerification'
    }
    userMeta.set(user.email, meta)
  }
  return meta
}

for (const user of mockUsers) {
  const meta = ensureUserMeta(user)
  meta.createdAt = meta.createdAt - 86_400_000
  meta.updatedAt = meta.updatedAt - 3_600_000
  if (user.emailVerified) {
    meta.lastLoginAt = now() - 600_000
    meta.status = 'active'
  }
}

function randomId() {
  if (typeof crypto !== 'undefined' && 'randomUUID' in crypto) {
    try {
      return crypto.randomUUID()
    } catch {}
  }
  return Math.random().toString(36).slice(2)
}

function revokeTokensForEmail(email: string) {
  for (const [token, record] of verificationTokens.entries()) {
    if (record.email === email) {
      verificationTokens.delete(token)
    }
  }
}

export function issueVerificationToken(email: string) {
  revokeTokensForEmail(email)
  const token = `${TOKEN_PREFIX}${randomId()}`
  const expiresAt = now() + FIFTEEN_MINUTES_IN_MS
  verificationTokens.set(token, { email, expiresAt })
  console.info(
    `[mock-api] Verification token for ${email}: ${token} (expires ${new Date(expiresAt).toISOString()})`
  )
  return { token, expiresAt }
}

export function consumeVerificationToken(token: string) {
  const record = verificationTokens.get(token)
  if (!record) {
    throw new ApiError(400, 'invalidToken', 'Invalid token')
  }
  verificationTokens.delete(token)
  if (record.expiresAt < now()) {
    throw new ApiError(410, 'tokenExpired', 'Token expired or already used')
  }
  return record.email
}

export function toUserDTO(user: User): UserDTO {
  const meta = ensureUserMeta(user)
  return {
    id: user.id,
    email: user.email,
    status: meta.status,
    createdAt: new Date(meta.createdAt).toISOString(),
    updatedAt: new Date(meta.updatedAt).toISOString(),
    lastLoginAt: meta.lastLoginAt
      ? new Date(meta.lastLoginAt).toISOString()
      : null
  }
}

export function markPendingVerification(user: User) {
  const meta = ensureUserMeta(user)
  meta.status = 'pendingVerification'
  meta.updatedAt = now()
}

export function markActiveUser(user: User) {
  const meta = ensureUserMeta(user)
  meta.status = 'active'
  meta.lastLoginAt = now()
  meta.updatedAt = now()
}

export function setCurrentSession(email: string | null) {
  currentSessionEmail = email
}

export function assertSession(): User {
  if (!currentSessionEmail) {
    throw new ApiError(401, 'notAuthenticated', 'Session missing or expired')
  }
  const user = mockUsers.find(
    (candidate) => candidate.email === currentSessionEmail
  )
  if (!user) {
    currentSessionEmail = null
    throw new ApiError(401, 'notAuthenticated', 'Session missing or expired')
  }
  return user
}

export function clearSession() {
  currentSessionEmail = null
}

export type LoginRequestDTO = {
  email: string
  password: string
}

export type VerifyEmailRequestDTO = {
  token: string
}

export type UserDTO = {
  id: string
  email: string
  role: string
  status: string
  createdAt: string
  updatedAt: string
  lastLoginAt?: string | null
}

export type AuthSessionResponseDTO = {
  tokenType?: string
  expiresAt?: string
  user: UserDTO
}

export type UserResponseDTO = {
  user: UserDTO
}

export type OAuthAuthorizationRequestDTO = {
  redirectUri?: string
  scopes?: string[]
  state?: string
  prompt?: string
  usePkce?: boolean
}

export type OAuthAuthorizationResponseDTO = {
  authorizationUrl: string
  state?: string
  codeVerifier?: string
  codeChallenge?: string
  codeChallengeMethod?: 'plain' | 'S256'
}

export type OAuthExchangeRequestDTO = {
  code: string
  redirectUri?: string
  codeVerifier?: string
  state?: string
}

export type IdentitySummaryDTO = {
  id: string
  provider: string
  subject: string
  scopes?: string[]
  connectedAt: string
  expiresAt?: string | null
}

export type IdentityListResponseDTO = {
  identities: IdentitySummaryDTO[]
}

export type ChangePasswordRequestDTO = {
  currentPassword?: string
  newPassword?: string
}

export type ChangeEmailRequestDTO = {
  email?: string
  password?: string
}

export type EmailChangeResponseDTO = {
  user: UserDTO
  verificationExpiresAt?: string | null
}

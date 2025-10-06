const baseKey = ['openapi', 'auth'] as const

export const authKeys = {
  all: () => baseKey,
  currentUser: () => [...baseKey, 'current-user'] as const,
  identities: () => [...baseKey, 'identities'] as const
}

export const authMutationKeys = {
  login: () => [...baseKey, 'login'] as const,
  verifyEmail: () => [...baseKey, 'verify-email'] as const,
  logout: () => [...baseKey, 'logout'] as const,
  authorizeOAuth: () => [...baseKey, 'oauth', 'authorize'] as const,
  exchangeOAuth: () => [...baseKey, 'oauth', 'exchange'] as const
}

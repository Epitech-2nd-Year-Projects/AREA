const baseKey = ['openapi', 'users'] as const

export const userMutationKeys = {
  register: () => [...baseKey, 'register'] as const,
  adminResetUserPassword: () =>
    [...baseKey, 'admin', 'password', 'reset'] as const,
  adminUpdateUserEmail: () => [...baseKey, 'admin', 'email', 'update'] as const,
  adminUpdateUserStatus: () =>
    [...baseKey, 'admin', 'status', 'update'] as const
}

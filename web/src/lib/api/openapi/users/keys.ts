const baseKey = ['openapi', 'users'] as const

export const userMutationKeys = {
  register: () => [...baseKey, 'register'] as const
}

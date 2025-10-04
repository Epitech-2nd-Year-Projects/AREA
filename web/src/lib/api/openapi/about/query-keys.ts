const baseKey = ['openapi', 'about'] as const

export const aboutKeys = {
  all: () => baseKey,
  detail: () => baseKey
}

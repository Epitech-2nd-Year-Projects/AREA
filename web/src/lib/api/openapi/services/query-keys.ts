const baseKey = ['openapi', 'services'] as const

export const servicesKeys = {
  all: () => baseKey,
  list: () => [...baseKey, 'list'] as const
} as const

const baseKey = ['openapi', 'areas'] as const

export const areasKeys = {
  all: () => [...baseKey] as const,
  list: () => [...baseKey, 'list'] as const
}

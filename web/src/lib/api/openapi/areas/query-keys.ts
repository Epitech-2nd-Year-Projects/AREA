const baseKey = ['openapi', 'areas'] as const

export const areasKeys = {
  all: () => [...baseKey] as const,
  list: () => [...baseKey, 'list'] as const,
  detail: (areaId: string) => [...baseKey, areaId, 'detail'] as const,
  history: (areaId: string) => [...baseKey, areaId, 'history'] as const
}

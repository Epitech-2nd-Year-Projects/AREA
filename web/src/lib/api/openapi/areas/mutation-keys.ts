const baseKey = ['openapi', 'areas'] as const

export const areasMutationKeys = {
  create: () => [...baseKey, 'create'] as const
}

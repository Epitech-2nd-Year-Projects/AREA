const baseKey = ['openapi', 'areas'] as const

export const areasMutationKeys = {
  create: () => [...baseKey, 'create'] as const,
  update: (areaId: string) => [...baseKey, areaId, 'update'] as const,
  delete: (areaId: string) => [...baseKey, areaId, 'delete'] as const,
  execute: (areaId: string) => [...baseKey, areaId, 'execute'] as const,
  updateStatus: (areaId: string) => [...baseKey, areaId, 'status'] as const,
  duplicate: (areaId: string) => [...baseKey, areaId, 'duplicate'] as const
}

const baseKey = ['components'] as const

export const componentsKeys = {
  root: () => baseKey,
  available: (params?: { kind?: 'action' | 'reaction'; provider?: string }) =>
    [
      ...baseKey,
      'available',
      params?.kind ?? 'all',
      params?.provider ?? 'all'
    ] as const
} as const

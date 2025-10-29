const baseKey = ['components'] as const

export const componentsKeys = {
  root: () => baseKey,
  list: (params?: { kind?: 'action' | 'reaction'; provider?: string }) =>
    [
      ...baseKey,
      'list',
      params?.kind ?? 'all',
      params?.provider ?? 'all'
    ] as const,
  available: (params?: { kind?: 'action' | 'reaction'; provider?: string }) =>
    [
      ...baseKey,
      'available',
      params?.kind ?? 'all',
      params?.provider ?? 'all'
    ] as const
} as const

const baseKey = ['logo'] as const

export const logoKeys = {
  all: () => baseKey,
  detail: (name: string) => [...baseKey, 'detail', name] as const
}

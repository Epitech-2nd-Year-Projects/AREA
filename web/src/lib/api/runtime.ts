import { env } from '@/env'

const mode = env.NEXT_PUBLIC_API_MODE

export const apiRuntime = {
  mode,
  useMocks: mode === 'mock'
} as const

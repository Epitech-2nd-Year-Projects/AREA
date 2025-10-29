import { useQuery, type UseQueryOptions } from '@tanstack/react-query'
import { logoKeys } from './query-keys'
import { fetchLogo } from './client'

type LogoQueryOptions = Omit<
  UseQueryOptions<
    string | null,
    Error,
    string | null,
    ReturnType<typeof logoKeys.detail>
  >,
  'queryKey' | 'queryFn'
>

export function useLogoQuery(name: string, options?: LogoQueryOptions) {
  return useQuery({
    queryKey: logoKeys.detail(name),
    queryFn: () => fetchLogo(name),
    ...options
  })
}

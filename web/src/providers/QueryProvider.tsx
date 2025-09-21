'use client'

import {
  QueryCache,
  QueryClient,
  QueryClientProvider
} from '@tanstack/react-query'
import { type ReactNode, useMemo } from 'react'
import { isRetryableError } from '@/lib/api/http/messages'
import { ApiError } from '@/lib/api/http/errors'
import { useRouter } from 'next/navigation'
import type { Query } from '@tanstack/query-core'

export default function QueryProvider({ children }: { children: ReactNode }) {
  const router = useRouter()

  const client = useMemo(
    () =>
      new QueryClient({
        queryCache: new QueryCache({
          onError: (
            error: Error,
            query: Query<unknown, unknown, unknown, readonly unknown[]>
          ) => {
            if (error instanceof ApiError && error.status === 401) {
              const meta = query.meta as { redirectOn401?: boolean } | undefined
              const shouldRedirect = Boolean(meta?.redirectOn401)
              if (!shouldRedirect) return

              const next = `${location.pathname}${location.search}`
              router.push(`/login?next=${encodeURIComponent(next)}`)
            }
          }
        }),
        defaultOptions: {
          queries: {
            staleTime: 30_000,
            refetchOnWindowFocus: false,
            retry: (failureCount, error) =>
              isRetryableError(error) && failureCount < 2
          },
          mutations: {
            retry: (failureCount, error) =>
              isRetryableError(error) && failureCount < 1
          }
        }
      }),
    [router]
  )

  return <QueryClientProvider client={client}>{children}</QueryClientProvider>
}

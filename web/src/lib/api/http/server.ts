'server-only'
import { apiConfig } from '@/env'
import { parseAndThrowApiError } from './errors'

type FetchOptions = {
  method?: 'GET' | 'POST' | 'PATCH' | 'DELETE'
  body?: unknown
  signal?: AbortSignal
  next?:
    | { revalidate?: number; tags?: string[] }
    | { revalidate?: false; tags?: string[] }
  cache?: RequestCache
  cookieHeader?: string
}

export async function apiFetchServer<T>(
  path: string,
  opts: FetchOptions = {}
): Promise<T> {
  const cookieHeader = await resolveCookieHeader(opts.cookieHeader)

  const url = apiConfig.buildUrl(path)

  const res = await fetch(url, {
    method: opts.method ?? 'GET',
    headers: {
      Accept: 'application/json',
      ...(opts.body ? { 'Content-Type': 'application/json' } : {}),
      ...(cookieHeader ? { cookie: cookieHeader } : {})
    },
    body: opts.body ? JSON.stringify(opts.body) : undefined,
    cache: opts.cache,
    next: opts.next
  })

  if (!res.ok) {
    await parseAndThrowApiError(res)
  }
  if (res.status === 204) return undefined as T
  return (await res.json()) as T
}

async function resolveCookieHeader(explicitHeader?: string): Promise<string> {
  if (explicitHeader) return explicitHeader
  if (typeof window !== 'undefined') return ''

  try {
    const { cookies } = (await import(
      'next/headers'
    )) as typeof import('next/headers')
    const cookieStore = await cookies()

    return cookieStore
      .getAll()
      .map((c) => `${c.name}=${c.value}`)
      .join('; ')
  } catch (e) {
    console.error(e)
    return ''
  }
}

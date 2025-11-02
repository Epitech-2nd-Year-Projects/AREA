import { apiConfig } from '@/env'
import { parseAndThrowApiError } from './errors'

type FetchOptions = {
  method?: 'GET' | 'POST' | 'PATCH' | 'DELETE'
  body?: unknown
  signal?: AbortSignal
  csrfToken?: string
  tryRefresh?: boolean
}

let refreshPromise: Promise<void> | null = null

async function refreshSession() {
  refreshPromise ??= fetch(apiConfig.buildUrl('/auth/refresh'), {
    method: 'POST',
    headers: { Accept: 'application/json', 'Content-Type': 'application/json' },
    credentials: 'include'
  })
    .then(async (res) => {
      if (!res.ok) {
        await parseAndThrowApiError(res)
      }
    })
    .finally(() => {
      refreshPromise = null
    })
  return refreshPromise
}

export async function apiFetchClient<T>(
  path: string,
  opts: FetchOptions = {}
): Promise<T> {
  const headers: HeadersInit = {
    Accept: 'application/json',
    ...(opts.body ? { 'Content-Type': 'application/json' } : {})
  }
  if (opts.csrfToken) headers['X-CSRF-Token'] = opts.csrfToken

  const doFetch = () =>
    fetch(apiConfig.buildUrl(path), {
      method: opts.method ?? 'GET',
      headers,
      credentials: 'include',
      body: opts.body ? JSON.stringify(opts.body) : undefined,
      signal: opts.signal
    })

  let res = await doFetch()

  if (res.status === 401 && opts.tryRefresh !== false) {
    try {
      await refreshSession()
      res = await doFetch()
    } catch {}
  }

  if (!res.ok) {
    await parseAndThrowApiError(res)
  }

  if (res.status === 204 || res.status === 205) return undefined as T

  const rawBody = await res.text()
  if (!rawBody) return undefined as T

  const trimmedBody = rawBody.trim()
  if (!trimmedBody) return undefined as T

  try {
    return JSON.parse(trimmedBody) as T
  } catch (error) {
    throw error
  }
}

import type { ReadonlyURLSearchParams } from 'next/navigation'

const OAUTH_STORAGE_PREFIX = 'area.oauth'

export const OAUTH_CLEANUP_PARAMS = [
  'code',
  'state',
  'scope',
  'authuser',
  'prompt',
  'hd',
  'error',
  'error_description'
]

export type OAuthSessionState = {
  provider: string
  redirectUri: string
  state?: string
  codeVerifier?: string
  createdAt: number
}

let sessionStorageAvailable: boolean | null = null

const isSessionStorageAvailable = () => {
  if (sessionStorageAvailable !== null) {
    return sessionStorageAvailable
  }
  if (typeof window === 'undefined') {
    sessionStorageAvailable = false
    return sessionStorageAvailable
  }
  try {
    const key = '__area_oauth_test__'
    window.sessionStorage.setItem(key, '1')
    window.sessionStorage.removeItem(key)
    sessionStorageAvailable = true
  } catch {
    sessionStorageAvailable = false
  }
  return sessionStorageAvailable
}

function buildStorageKey(provider: string) {
  return `${OAUTH_STORAGE_PREFIX}.${provider}`
}

export function persistOAuthState(provider: string, state: OAuthSessionState) {
  if (!isSessionStorageAvailable()) return
  window.sessionStorage.setItem(
    buildStorageKey(provider),
    JSON.stringify(state)
  )
}

export function readOAuthState(provider: string): OAuthSessionState | null {
  if (!isSessionStorageAvailable()) return null
  try {
    const raw = window.sessionStorage.getItem(buildStorageKey(provider))
    if (!raw) return null
    return JSON.parse(raw) as OAuthSessionState
  } catch {
    return null
  }
}

export function clearOAuthState(provider: string) {
  if (!isSessionStorageAvailable()) return
  window.sessionStorage.removeItem(buildStorageKey(provider))
}

export function buildCleanOAuthPath(
  searchParams: URLSearchParams | ReadonlyURLSearchParams,
  pathname = '/login'
) {
  const params = new URLSearchParams(searchParams.toString())
  for (const param of OAUTH_CLEANUP_PARAMS) {
    params.delete(param)
  }
  const query = params.toString()
  return query ? `${pathname}?${query}` : pathname
}

export function extractRedirectFromUri(uri: string) {
  const attemptParse = (value: string, base?: string) => {
    try {
      const url = base ? new URL(value, base) : new URL(value)
      return { redirect: url.searchParams.get('redirect'), success: true }
    } catch {
      return { redirect: null, success: false }
    }
  }

  const direct = attemptParse(uri)
  if (direct.success) return direct.redirect
  if (typeof window !== 'undefined') {
    const fallback = attemptParse(uri, window.location.origin)
    return fallback.success ? fallback.redirect : null
  }
  return null
}

export function sanitizeRedirectTarget(target: string | null | undefined) {
  if (!target) return null
  const trimmed = target.trim()
  if (!trimmed) return null
  if (!trimmed.startsWith('/') || trimmed.startsWith('//')) return null
  return trimmed
}

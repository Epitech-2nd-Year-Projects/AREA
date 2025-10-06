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
  flow?: string
  redirect?: string | null
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

const CLIENT_STATE_PREFIX = 'area:'

type ClientOAuthStatePayload = {
  v: 1
  provider: string
  flow?: string
  redirect?: string | null
  nonce: string
}

const OAUTH_SESSION_PREFIX = `${OAUTH_STORAGE_PREFIX}.`

const generateNonce = () => {
  try {
    if (typeof globalThis.crypto !== 'undefined') {
      if (typeof globalThis.crypto.randomUUID === 'function') {
        return globalThis.crypto.randomUUID()
      }
      const buffer = new Uint8Array(16)
      globalThis.crypto.getRandomValues(buffer)
      return Array.from(buffer)
        .map((value) => value.toString(16).padStart(2, '0'))
        .join('')
    }
  } catch {}
  return Math.random().toString(36).slice(2, 12)
}

function encodeClientState(payload: ClientOAuthStatePayload) {
  const json = JSON.stringify(payload)
  return `${CLIENT_STATE_PREFIX}${encodeURIComponent(json)}`
}

function decodeClientState(value: string) {
  const raw = value.slice(CLIENT_STATE_PREFIX.length)
  const json = decodeURIComponent(raw)
  return JSON.parse(json) as ClientOAuthStatePayload
}

export function createClientOAuthState(options: {
  provider: string
  flow?: string
  redirect?: string | null
}) {
  const payload: ClientOAuthStatePayload = {
    v: 1,
    provider: options.provider,
    flow: options.flow,
    redirect: options.redirect ?? null,
    nonce: generateNonce()
  }
  const value = encodeClientState(payload)
  return { value, payload }
}

export function parseClientOAuthState(value?: string | null) {
  if (!value || !value.startsWith(CLIENT_STATE_PREFIX)) {
    return null
  }
  try {
    const payload = decodeClientState(value)
    if (payload.v !== 1) return null
    if (!payload.provider) return null
    return payload
  } catch {
    return null
  }
}

export function readOAuthStateByStateValue(
  stateValue: string
): OAuthSessionState | null {
  if (!isSessionStorageAvailable()) return null
  try {
    for (let index = 0; index < window.sessionStorage.length; index += 1) {
      const key = window.sessionStorage.key(index)
      if (!key || !key.startsWith(OAUTH_SESSION_PREFIX)) continue
      const raw = window.sessionStorage.getItem(key)
      if (!raw) continue
      const parsed = JSON.parse(raw) as OAuthSessionState
      if (parsed.state && parsed.state === stateValue) {
        return parsed
      }
    }
  } catch {
    return null
  }
  return null
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

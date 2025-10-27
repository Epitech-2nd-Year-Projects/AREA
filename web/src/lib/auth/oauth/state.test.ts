import { afterEach, beforeEach, describe, expect, test } from 'vitest'

import {
  buildCleanOAuthPath,
  clearOAuthState,
  createClientOAuthState,
  extractRedirectFromUri,
  parseClientOAuthState,
  persistOAuthState,
  readOAuthState,
  readOAuthStateByStateValue,
  sanitizeRedirectTarget
} from './state'

const provider = 'google'

describe('OAuth state helpers', () => {
  beforeEach(() => {
    window.sessionStorage.clear()
  })

  afterEach(() => {
    window.sessionStorage.clear()
  })

  test('creates and parses client OAuth state payloads', () => {
    const { value, payload } = createClientOAuthState({
      provider,
      flow: 'login',
      redirect: '/dashboard'
    })

    expect(value.startsWith('area:')).toBe(true)
    const parsed = parseClientOAuthState(value)

    expect(parsed).not.toBeNull()
    expect(parsed?.provider).toBe(provider)
    expect(parsed?.flow).toBe('login')
    expect(parsed?.redirect).toBe('/dashboard')
    expect(parsed?.nonce).toBeTruthy()
    expect(parsed?.nonce?.length).toBeGreaterThanOrEqual(10)
    expect(parsed).toEqual(payload)
  })

  test('returns null when parsing invalid client state', () => {
    expect(parseClientOAuthState(null)).toBeNull()
    expect(parseClientOAuthState('invalid')).toBeNull()
    expect(parseClientOAuthState('area:{"v":2}')).toBeNull()
  })

  test('builds clean OAuth path without transient parameters', () => {
    const params = new URLSearchParams(
      'code=abc123&state=xyz&redirect=/dashboard&error=access_denied&keep=1'
    )
    const cleaned = buildCleanOAuthPath(params, '/login')
    expect(cleaned).toBe('/login?redirect=%2Fdashboard&keep=1')
  })

  test('sanitizes redirect targets', () => {
    expect(sanitizeRedirectTarget('/dashboard')).toBe('/dashboard')
    expect(sanitizeRedirectTarget('   /settings  ')).toBe('/settings')
    expect(sanitizeRedirectTarget('http://malicious.com')).toBeNull()
    expect(sanitizeRedirectTarget('//evil.com')).toBeNull()
    expect(sanitizeRedirectTarget('profile')).toBeNull()
    expect(sanitizeRedirectTarget('')).toBeNull()
  })

  test('extracts redirect parameter from URIs', () => {
    expect(
      extractRedirectFromUri(
        'https://example.com/oauth/callback?redirect=/dashboard'
      )
    ).toBe('/dashboard')
    expect(
      extractRedirectFromUri('/oauth/callback?redirect=/account/settings')
    ).toBe('/account/settings')
    expect(extractRedirectFromUri('https://example.com/oauth/callback')).toBe(
      null
    )
  })

  test('persists, reads, and clears OAuth session state in storage', () => {
    const state = {
      provider,
      redirectUri: 'https://example.com/oauth/callback',
      state: 'state-123',
      codeVerifier: 'challenge',
      createdAt: Date.now()
    }

    persistOAuthState(provider, state)

    expect(readOAuthState(provider)).toEqual(state)
    expect(readOAuthState('other')).toBeNull()
    expect(readOAuthStateByStateValue('state-123')).toEqual(state)

    clearOAuthState(provider)
    expect(readOAuthState(provider)).toBeNull()
    expect(readOAuthStateByStateValue('state-123')).toBeNull()
  })
})

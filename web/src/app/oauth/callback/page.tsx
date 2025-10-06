'use client'
import { useEffect, useMemo, useState } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import { Loader2 } from 'lucide-react'
import { useExchangeOAuthMutation } from '@/lib/api/openapi/auth'
import { useSubscribeServiceExchangeMutation } from '@/lib/api/openapi/services'
import { ApiError } from '@/lib/api/http/errors'
import type { OAuthSessionState } from '@/lib/auth/oauth'
import {
  clearOAuthState,
  parseClientOAuthState,
  readOAuthState,
  readOAuthStateByStateValue,
  sanitizeRedirectTarget
} from '@/lib/auth/oauth'
import { useQueryClient } from '@tanstack/react-query'
import { authKeys } from '@/lib/api/openapi/auth/query-keys'
import { aboutKeys } from '@/lib/api/openapi/about/query-keys'

export default function OAuthCallbackPage() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const serialized = searchParams.toString()
  const queryClient = useQueryClient()
  const [message, setMessage] = useState<string>('Completing authorization...')

  const { mutateAsync: exchangeOAuth } = useExchangeOAuthMutation()
  const { mutateAsync: exchangeSubscription } =
    useSubscribeServiceExchangeMutation()

  const params = useMemo(() => new URLSearchParams(serialized), [serialized])

  useEffect(() => {
    if (typeof window === 'undefined') return
    const code = params.get('code')
    const oauthError = params.get('error')
    const stateParam = params.get('state')
    const providerFromQuery = params.get('provider') || undefined
    const flowFromQuery = params.get('flow') || undefined
    const redirectFromQuery =
      sanitizeRedirectTarget(params.get('redirect')) || undefined
    const parsedState = parseClientOAuthState(stateParam)

    const candidateProviders = [
      parsedState?.provider,
      providerFromQuery
    ].filter(
      (value): value is string => typeof value === 'string' && value.length > 0
    )

    let stored: OAuthSessionState | null = null
    for (const candidate of candidateProviders) {
      stored = readOAuthState(candidate)
      if (stored) break
    }

    if (!stored && stateParam) {
      stored = readOAuthStateByStateValue(stateParam)
    }

    const provider =
      stored?.provider ?? parsedState?.provider ?? providerFromQuery
    const flow = stored?.flow ?? parsedState?.flow ?? flowFromQuery
    const redirectTarget =
      sanitizeRedirectTarget(stored?.redirect ?? parsedState?.redirect) ||
      redirectFromQuery

    const goNext = (fallback: string) => {
      router.replace(redirectTarget || fallback)
    }

    if (oauthError) {
      if (provider) clearOAuthState(provider)
      setMessage('Authorization canceled or failed. Redirecting...')
      goNext(flow === 'service' ? '/dashboard/profile' : '/login')
      return
    }

    if (!code || !provider || !flow) {
      setMessage('Missing OAuth parameters. Redirecting...')
      goNext('/login')
      return
    }

    let cancelled = false

    const run = async () => {
      const session = stored
      if (!session) {
        clearOAuthState(provider)
        setMessage('Session expired. Redirecting...')
        goNext(flow === 'service' ? '/dashboard/profile' : '/login')
        return
      }
      if (session.state && stateParam && session.state !== stateParam) {
        clearOAuthState(provider)
        setMessage('State mismatch. Redirecting...')
        goNext(flow === 'service' ? '/dashboard/profile' : '/login')
        return
      }

      try {
        if (flow === 'login') {
          await exchangeOAuth({
            provider,
            body: {
              code,
              redirectUri: session.redirectUri,
              codeVerifier: session.codeVerifier,
              state: stateParam ?? session.state
            }
          })
          if (cancelled) return
          clearOAuthState(provider)
          setMessage('Login successful. Redirecting...')
          goNext('/dashboard')
          return
        }

        await exchangeSubscription({
          provider,
          body: {
            code,
            redirectUri: session.redirectUri,
            codeVerifier: session.codeVerifier
          }
        })
        if (cancelled) return
        clearOAuthState(provider)
        await Promise.all([
          queryClient.invalidateQueries({ queryKey: authKeys.currentUser() }),
          queryClient.invalidateQueries({ queryKey: aboutKeys.detail() })
        ])
        setMessage('Service connected. Redirecting...')
        goNext('/dashboard/profile')
      } catch (error) {
        if (cancelled) return
        clearOAuthState(provider)
        if (error instanceof ApiError) {
          setMessage('Authorization failed. Redirecting...')
        } else {
          setMessage('Unexpected error. Redirecting...')
        }
        goNext(flow === 'service' ? '/dashboard/profile' : '/login')
      }
    }

    run()
    return () => {
      cancelled = true
    }
  }, [
    aboutKeys,
    authKeys,
    exchangeOAuth,
    exchangeSubscription,
    params,
    queryClient,
    router
  ])

  return (
    <div className="flex h-[60vh] flex-col items-center justify-center gap-3">
      <Loader2 className="h-6 w-6 animate-spin" aria-hidden />
      <p className="text-muted-foreground text-sm">{message}</p>
    </div>
  )
}

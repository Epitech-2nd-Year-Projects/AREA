'use client'
import { FormEvent, useCallback, useEffect, useMemo, useState } from 'react'
import { Loader2 } from 'lucide-react'
import { useTranslations } from 'next-intl'
import { useRouter, useSearchParams } from 'next/navigation'
import {
  useAuthorizeOAuthMutation,
  useExchangeOAuthMutation,
  useLoginMutation
} from '@/lib/api/openapi/auth'
import { ApiError } from '@/lib/api/http/errors'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { cn } from '@/lib/utils'
import {
  buildCleanOAuthPath,
  clearOAuthState,
  createClientOAuthState,
  persistOAuthState,
  readOAuthState,
  sanitizeRedirectTarget
} from '@/lib/auth/oauth'

type FeedbackState = {
  message: string
  variant: 'success' | 'error'
}

const GOOGLE_PROVIDER = 'google'

export function LoginForm({
  className,
  ...props
}: React.ComponentProps<'div'>) {
  const router = useRouter()
  const searchParams = useSearchParams()
  const serializedSearchParams = searchParams.toString()
  const t = useTranslations('LoginPage')
  const tAuth = useTranslations('AuthShared')
  const loginMutation = useLoginMutation()
  const { mutateAsync: authorizeOAuth, isPending: isAuthorizePending } =
    useAuthorizeOAuthMutation()
  const { mutateAsync: exchangeOAuth, isPending: isExchangePending } =
    useExchangeOAuthMutation()
  const isPending = loginMutation.isPending
  const isOAuthPending = isAuthorizePending || isExchangePending
  const [statusMessage, setStatusMessage] = useState<string | null>(null)
  const [unverifiedEmail, setUnverifiedEmail] = useState<string | null>(null)
  const [resendFeedback, setResendFeedback] = useState<FeedbackState | null>(
    null
  )
  const redirectParam = useMemo(() => {
    const params = new URLSearchParams(serializedSearchParams)
    return sanitizeRedirectTarget(params.get('redirect'))
  }, [serializedSearchParams])

  const completeLogin = useCallback(
    (preferredRedirect?: string | null) => {
      const destination =
        sanitizeRedirectTarget(preferredRedirect) ??
        redirectParam ??
        '/dashboard'
      router.push(destination)
    },
    [redirectParam, router]
  )

  useEffect(() => {
    const params = new URLSearchParams(serializedSearchParams)
    const needsVerification = params.get('needsVerification')
    const emailParam = params.get('email')

    if (needsVerification && emailParam) {
      const normalizedEmail = emailParam.trim()
      setStatusMessage(t('emailNotVerified', { email: normalizedEmail }))
      setUnverifiedEmail(normalizedEmail)
      setResendFeedback({
        message: tAuth('resendVerificationSuccess', { email: normalizedEmail }),
        variant: 'success'
      })
      router.replace('/login')
    }
  }, [router, serializedSearchParams, t, tAuth])

  useEffect(() => {
    if (typeof window === 'undefined') return

    const params = new URLSearchParams(serializedSearchParams)
    const code = params.get('code')
    const oauthError = params.get('error')
    const stateParam = params.get('state')

    if (!code && !oauthError) {
      return
    }

    const cleanAndReplace = () => {
      const cleanPath = buildCleanOAuthPath(params)
      router.replace(cleanPath, { scroll: false })
    }

    if (oauthError) {
      clearOAuthState(GOOGLE_PROVIDER)
      setStatusMessage(null)
      setResendFeedback(null)
      setUnverifiedEmail(null)
      if (oauthError === 'access_denied') {
        toast.error(t('oauth.canceled'))
      } else {
        toast.error(t('oauth.exchangeFailed'))
      }
      cleanAndReplace()
      return
    }

    if (!code) {
      return
    }

    let cancelled = false

    const runExchange = async () => {
      setResendFeedback(null)
      setUnverifiedEmail(null)
      setStatusMessage(t('oauth.exchanging'))

      const storedState = readOAuthState(GOOGLE_PROVIDER)

      if (!storedState) {
        clearOAuthState(GOOGLE_PROVIDER)
        setStatusMessage(null)
        toast.error(t('oauth.stateMismatch'))
        cleanAndReplace()
        return
      }

      if (storedState.state && stateParam && storedState.state !== stateParam) {
        clearOAuthState(GOOGLE_PROVIDER)
        setStatusMessage(null)
        toast.error(t('oauth.stateMismatch'))
        cleanAndReplace()
        return
      }

      try {
        await exchangeOAuth({
          provider: storedState.provider,
          body: {
            code,
            redirectUri: storedState.redirectUri,
            codeVerifier: storedState.codeVerifier,
            state: stateParam ?? storedState.state
          }
        })

        if (cancelled) return

        clearOAuthState(GOOGLE_PROVIDER)
        setStatusMessage(null)
        setResendFeedback(null)
        setUnverifiedEmail(null)

        const cleanPath = buildCleanOAuthPath(params)
        router.replace(cleanPath, { scroll: false })

        completeLogin(storedState.redirect)
      } catch (error) {
        if (cancelled) return

        clearOAuthState(GOOGLE_PROVIDER)
        setStatusMessage(null)

        if (error instanceof ApiError) {
          if (error.status === 404) {
            toast.error(t('oauth.unavailable'))
          } else if (error.status === 400) {
            toast.error(t('oauth.exchangeFailed'))
          } else {
            toast.error(t('errors.generic'))
          }
        } else {
          toast.error(t('errors.generic'))
        }

        const cleanPath = buildCleanOAuthPath(params)
        router.replace(cleanPath, { scroll: false })
      }
    }

    runExchange()

    return () => {
      cancelled = true
    }
  }, [exchangeOAuth, router, serializedSearchParams, t, completeLogin])

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()

    const form = event.currentTarget
    const formData = new FormData(form)

    const email = String(formData.get('email') ?? '').trim()
    const password = String(formData.get('password') ?? '')

    setStatusMessage(null)
    setResendFeedback(null)

    if (!email) {
      toast.error(t('errors.emailRequired'))
      return
    }

    if (!password) {
      toast.error(t('errors.passwordRequired'))
      return
    }

    try {
      await loginMutation.mutateAsync({ email, password })
      setUnverifiedEmail(null)
      setStatusMessage(null)
      form.reset()
      completeLogin()
    } catch (error) {
      if (error instanceof ApiError) {
        if (error.status === 400) {
          toast.error(t('errors.invalidCredentials'))
          setUnverifiedEmail(null)
          return
        }
        if (error.status === 403) {
          setUnverifiedEmail(email)
          setStatusMessage(t('emailNotVerified', { email }))
          setResendFeedback({
            message: tAuth('resendVerificationSuccess', { email }),
            variant: 'success'
          })
          return
        }
      }
      toast.error(t('errors.generic'))
      setUnverifiedEmail(null)
    }
  }

  const handleGoogleLogin = async () => {
    if (typeof window === 'undefined') return

    setStatusMessage(null)
    setResendFeedback(null)
    setUnverifiedEmail(null)

    const redirectUri = new URL(
      '/oauth/callback',
      window.location.origin
    ).toString()
    const next = redirectParam ?? '/dashboard'
    const { value: clientState } = createClientOAuthState({
      provider: GOOGLE_PROVIDER,
      flow: 'login',
      redirect: next
    })

    try {
      setStatusMessage(t('oauth.starting'))
      const response = await authorizeOAuth({
        provider: GOOGLE_PROVIDER,
        body: {
          redirectUri,
          usePkce: true,
          state: clientState
        }
      })

      clearOAuthState(GOOGLE_PROVIDER)
      persistOAuthState(GOOGLE_PROVIDER, {
        provider: GOOGLE_PROVIDER,
        redirectUri,
        state: response.state ?? clientState,
        codeVerifier: response.codeVerifier,
        flow: 'login',
        redirect: next,
        createdAt: Date.now()
      })

      window.location.assign(response.authorizationUrl)
    } catch (error) {
      setStatusMessage(null)

      if (error instanceof ApiError) {
        if (error.status === 404) {
          toast.error(t('oauth.unavailable'))
        } else {
          toast.error(t('oauth.initFailed'))
        }
      } else {
        toast.error(t('errors.generic'))
      }
    }
  }

  return (
    <div className={cn('flex flex-col gap-6', className)} {...props}>
      <Card className="overflow-hidden p-0">
        <CardContent>
          <form className="p-6 md:p-8" onSubmit={handleSubmit}>
            <div className="flex flex-col gap-6">
              <div className="flex flex-col items-center text-center">
                <h1 className="text-2xl font-bold">{t('welcomeBack')}</h1>
                <p className="text-muted-foreground text-balance">
                  {t('loginToAccount')}
                </p>
              </div>
              {statusMessage ? (
                <div
                  className={cn(
                    'rounded-md border p-4',
                    unverifiedEmail
                      ? 'border-primary/20 bg-primary/5'
                      : 'border-muted'
                  )}
                  role="status"
                >
                  <p className="font-semibold">{statusMessage}</p>
                  {unverifiedEmail ? (
                    <>
                      <p className="text-muted-foreground mt-1 text-sm">
                        {t('emailNotVerifiedInstructions')}
                      </p>
                      {resendFeedback ? (
                        <span
                          className={cn(
                            'mt-4 block text-sm',
                            resendFeedback.variant === 'error'
                              ? 'text-destructive'
                              : 'text-muted-foreground'
                          )}
                        >
                          {resendFeedback.message}
                        </span>
                      ) : null}
                    </>
                  ) : (
                    <p className="text-muted-foreground mt-1 text-sm">
                      {t('loginSuccessDetails')}
                    </p>
                  )}
                </div>
              ) : null}

              <div className="grid gap-3">
                <Label htmlFor="email">{t('email')}</Label>
                <Input
                  id="email"
                  name="email"
                  type="email"
                  placeholder="m@example.com"
                  defaultValue={searchParams.get('email') ?? ''}
                  required
                />
              </div>
              <div className="grid gap-3">
                <div className="flex items-center">
                  <Label htmlFor="password">{t('password')}</Label>
                  <a
                    href="#"
                    className="ml-auto text-sm underline-offset-2 hover:underline"
                  >
                    {t('forgotYourPassword')}
                  </a>
                </div>
                <Input id="password" name="password" type="password" required />
              </div>
              <Button type="submit" className="w-full" disabled={isPending}>
                {isPending ? (
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                ) : null}
                {t('login')}
              </Button>
              <div className="after:border-border relative text-center text-sm after:absolute after:inset-0 after:top-1/2 after:z-0 after:flex after:items-center after:border-t">
                <span className="bg-card text-muted-foreground relative z-10 px-2">
                  {t('orContinueWith')}
                </span>
              </div>
              <div className="grid gap-4">
                <Button
                  variant="outline"
                  type="button"
                  className="w-full"
                  onClick={handleGoogleLogin}
                  disabled={isOAuthPending}
                  aria-busy={isOAuthPending}
                >
                  {isOAuthPending ? (
                    <Loader2
                      className="h-4 w-4 animate-spin"
                      aria-hidden="true"
                    />
                  ) : (
                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
                      <path
                        d="M12.48 10.92v3.28h7.84c-.24 1.84-.853 3.187-1.787 4.133-1.147 1.147-2.933 2.4-6.053 2.4-4.827 0-8.6-3.893-8.6-8.72s3.773-8.72 8.6-8.72c2.6 0 4.507 1.027 5.907 2.347l2.307-2.307C18.747 1.44 16.133 0 12.48 0 5.867 0 .307 5.387.307 12s5.56 12 12.173 12c3.573 0 6.267-1.173 8.373-3.36 2.16-2.16 2.84-5.213 2.84-7.667 0-.76-.053-1.467-.173-2.053H12.48z"
                        fill="currentColor"
                      />
                    </svg>
                  )}
                  <span className="sr-only">{t('loginWithGoogle')}</span>
                </Button>
              </div>
              <div className="text-center text-sm">
                {t('dontHaveAnAccount')}
                <a href="/register" className="underline underline-offset-4">
                  {t('signUp')}
                </a>
              </div>
            </div>
          </form>
        </CardContent>
      </Card>
      <div className="text-muted-foreground *:[a]:hover:text-primary text-center text-xs text-balance *:[a]:underline *:[a]:underline-offset-4">
        {t('byClickingContinueYouAgreeToOur')}{' '}
        <a href="#">{t('termsOfService')}</a> {t('and')}{' '}
        <a href="#">{t('privacyPolicy')}</a>.
      </div>
    </div>
  )
}

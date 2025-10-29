'use client'

import { useMemo } from 'react'
import Image from 'next/image'
import { useParams, useRouter } from 'next/navigation'
import { useQueryClient } from '@tanstack/react-query'
import { Loader2 } from 'lucide-react'
import { useTranslations } from 'next-intl'

import { useAboutQuery, extractServices } from '@/lib/api/openapi/about'
import {
  useCurrentUserQuery,
  mapUserDTOToUser,
  useIdentitiesQuery
} from '@/lib/api/openapi/auth'
import { ApiError } from '@/lib/api/http/errors'
import { Button } from '@/components/ui/button'
import {
  useSubscribeServiceMutation,
  useUnsubscribeServiceMutation
} from '@/lib/api/openapi/services'
import type { SubscribeServiceResponseDTO } from '@/lib/api/contracts/openapi/services'
import {
  clearOAuthState,
  createClientOAuthState,
  persistOAuthState
} from '@/lib/auth/oauth'
import { DisconnectModal } from '@/components/services/disconnect-modal'
import { authKeys } from '@/lib/api/openapi/auth'
import { useLogoQuery } from '@/lib/api/logo'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import type { ComponentSummaryDTO } from '@/lib/api/contracts/openapi/areas'
import { useComponentsQuery } from '@/lib/api/openapi/components'

export default function ExploreServicePage() {
  const params = useParams<{ service: string }>()
  const t = useTranslations('ExploreServicePage')
  const router = useRouter()
  const queryClient = useQueryClient()

  const { data, isLoading: isServicesLoading, isError } = useAboutQuery()
  const {
    data: userData,
    isLoading: isUserLoading,
    error: userError
  } = useCurrentUserQuery({ retry: false })

  const service = useMemo(() => {
    if (!data) return null
    const services = extractServices(data)
    return services.find((s) => s.name === params.service) ?? null
  }, [data, params.service])

  const isUnauthorized =
    userError instanceof ApiError && userError.status === 401
  const user =
    !isUnauthorized && userData?.user ? mapUserDTOToUser(userData.user) : null
  const isUserAuthenticated = Boolean(user)

  const { data: identitiesData, isLoading: isIdentitiesLoading } =
    useIdentitiesQuery({
      enabled: isUserAuthenticated
    })

  const linked = useMemo(() => {
    if (!isUserAuthenticated || !identitiesData?.identities) {
      return false
    }

    return identitiesData.identities.some(
      (identity) => identity.provider === service?.name
    )
  }, [identitiesData, isUserAuthenticated, service])

  const { mutateAsync: subscribeService, isPending: isSubscribing } =
    useSubscribeServiceMutation()
  const { mutateAsync: unsubscribeService, isPending: isUnsubscribing } =
    useUnsubscribeServiceMutation({
      onSuccess: () => {
        return queryClient.invalidateQueries({
          queryKey: authKeys.identities()
        })
      }
    })
  const { data: logoUrl } = useLogoQuery(service?.name ?? '', {
    enabled: Boolean(service)
  })

  const { data: actions, isLoading: areActionsLoading } = useComponentsQuery({
    params: { provider: params.service, kind: 'reaction' },
    enabled: !!service
  })

  const { data: reactions, isLoading: areReactionsLoading } =
    useComponentsQuery({
      params: { provider: params.service, kind: 'action' },
      enabled: !!service
    })

  const isLoading =
    isServicesLoading ||
    (isUserLoading && !isUnauthorized) ||
    (isIdentitiesLoading && isUserAuthenticated) ||
    areActionsLoading ||
    areReactionsLoading

  if (isLoading) {
    return (
      <div className="mx-auto flex max-w-6xl items-center justify-center py-24">
        <Loader2 className="mr-2 h-6 w-6 animate-spin" aria-hidden />
        <span className="text-muted-foreground text-sm">{t('loading')}</span>
      </div>
    )
  }

  if (isError || !service) {
    return (
      <div className="mx-auto max-w-2xl py-24 text-center">
        <p className="text-destructive text-sm">
          {isError ? t('errorLoading') : t('serviceNotFound')}
        </p>
      </div>
    )
  }

  const handleDisconnectConfirm = async () => {
    if (isUnsubscribing) {
      return
    }

    try {
      await unsubscribeService({ provider: service.name })
    } catch {
      // TODO: show an error toast
    }
  }

  const connectButtonState = isUserAuthenticated
    ? {
        label: linked ? t('linked') : t('connect'),
        variant: 'default' as const
      }
    : { label: t('getStarted'), variant: 'outline' as const }

  const handleConnectClick = isUserAuthenticated
    ? async () => {
        if (linked || isSubscribing) return
        if (typeof window === 'undefined') return

        const provider = service.name
        const redirectUri = new URL(
          '/oauth/callback',
          window.location.origin
        ).toString()
        const redirectTarget = window.location.pathname + window.location.search
        const { value: clientState } = createClientOAuthState({
          provider,
          flow: 'service',
          redirect: redirectTarget
        })

        try {
          const response: SubscribeServiceResponseDTO = await subscribeService({
            provider,
            body: { redirectUri, usePkce: true, state: clientState }
          })

          if (
            response.status === 'authorization_required' &&
            response.authorization
          ) {
            clearOAuthState(provider)
            persistOAuthState(provider, {
              provider,
              redirectUri,
              state: response.authorization.state ?? clientState,
              codeVerifier: response.authorization.codeVerifier,
              flow: 'service',
              redirect: redirectTarget,
              createdAt: Date.now()
            })
            window.location.assign(response.authorization.authorizationUrl)
            return
          }
          router.refresh()
        } catch {
          // TODO: Error toast
        }
      }
    : () => router.push('/register')

  const renderComponent = (component: ComponentSummaryDTO) => (
    <li key={component.name} className="rounded-lg border p-4">
      <h4 className="font-semibold">{component.displayName}</h4>
      <p className="text-muted-foreground text-sm">{component.description}</p>
    </li>
  )

  return (
    <div className="mx-auto flex max-w-6xl flex-col gap-12">
      <div className="flex items-center justify-between gap-4">
        <div className="flex items-center gap-4">
          {logoUrl ? (
            <Image
              src={logoUrl}
              alt={`${service.displayName} logo`}
              className="h-16 w-16 rounded-lg"
              width={64}
              height={64}
            />
          ) : (
            <div className="h-16 w-16 rounded-lg bg-muted animate-pulse" />
          )}
          <div>
            <h1 className="text-4xl font-bold tracking-tight">
              {service.displayName}
            </h1>
            <p className="text-muted-foreground text-lg">
              {t('integrationDetails')}
            </p>
          </div>
        </div>
        {linked ? (
          <DisconnectModal
            serviceName={service.displayName}
            onConfirm={handleDisconnectConfirm}
            fullWidth={false}
          />
        ) : (
          <Button
            className="cursor-pointer"
            variant={connectButtonState.variant}
            onClick={handleConnectClick}
            disabled={linked || isSubscribing}
            aria-disabled={linked || isSubscribing}
          >
            {connectButtonState.label}
          </Button>
        )}
      </div>

      <div className="grid grid-cols-1 gap-8 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>{t('actionsTitle')}</CardTitle>
          </CardHeader>
          <CardContent>
            {actions && actions.length > 0 ? (
              <ul className="flex flex-col gap-4">
                {actions.map(renderComponent)}
              </ul>
            ) : (
              <p className="text-muted-foreground text-sm">{t('noActions')}</p>
            )}
          </CardContent>
        </Card>
        <Card>
          <CardHeader>
            <CardTitle>{t('reactionsTitle')}</CardTitle>
          </CardHeader>
          <CardContent>
            {reactions && reactions.length > 0 ? (
              <ul className="flex flex-col gap-4">
                {reactions.map(renderComponent)}
              </ul>
            ) : (
              <p className="text-muted-foreground text-sm">
                {t('noReactions')}
              </p>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  )
}

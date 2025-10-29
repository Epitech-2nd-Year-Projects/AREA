'use client'

import { useRouter } from 'next/navigation'
import { useTranslations } from 'next-intl'
import { useQueryClient } from '@tanstack/react-query'

import { Button } from '@/components/ui/button'
import { Card, CardContent, CardFooter } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import type { Service } from '@/lib/api/contracts/services'
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
import { DisconnectModal } from './disconnect-modal'
import { authKeys } from '@/lib/api/openapi/auth'
import { useLogoQuery } from '@/lib/api/logo'

type ServiceCardProps = {
  service: Service
  authenticated: boolean
  linked: boolean
}

// This is a temporary type to extend the Service type with properties
// that are expected based on the user's request but may not be in the base type.
type ExtendedService = Service & {
  category?: string
  needsConnection?: boolean
}

export function ServiceCard({
  service,
  authenticated,
  linked
}: ServiceCardProps) {
  const extendedService = service as ExtendedService
  const t = useTranslations('ServiceCard')
  const router = useRouter()
  const queryClient = useQueryClient()
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
  const { data: logoUrl } = useLogoQuery(service.name)

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

  const connectButtonState = authenticated
    ? {
        label: linked ? t('linked') : t('connect'),
        variant: 'default' as const
      }
    : { label: t('getStarted'), variant: 'outline' as const }

  const handleConnectClick = authenticated
    ? async () => {
        if (linked || isSubscribing) return
        if (typeof window === 'undefined') return

        const provider = service.name
        const redirectUri = new URL(
          '/oauth/callback',
          window.location.origin
        ).toString()
        const redirectTarget = '/dashboard/profile'
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

  return (
    <Card className="flex w-full flex-col overflow-hidden">
      <CardContent className="flex flex-col items-center gap-1 p-4 text-center">
        {logoUrl ? (
          <img
            src={logoUrl}
            alt={`${service.displayName} logo`}
            className="h-12 w-12 rounded-full"
          />
        ) : (
          <div className="h-12 w-12 rounded-full bg-muted animate-pulse" />
        )}
        <h3 className="text-base font-semibold">{service.displayName}</h3>
        <div className="flex flex-wrap justify-center gap-2">
          {extendedService.category && (
            <Badge variant="secondary" className="uppercase">
              {extendedService.category}
            </Badge>
          )}
          {extendedService.needsConnection && (
            <Badge variant="outline">OAuth2</Badge>
          )}
        </div>
      </CardContent>
      <CardFooter className="p-4">
        {linked ? (
          <DisconnectModal
            serviceName={service.displayName}
            onConfirm={handleDisconnectConfirm}
          />
        ) : (
          <Button
            className="w-full cursor-pointer"
            variant={connectButtonState.variant}
            onClick={handleConnectClick}
            disabled={linked || isSubscribing}
            aria-disabled={linked || isSubscribing}
          >
            {connectButtonState.label}
          </Button>
        )}
      </CardFooter>
    </Card>
  )
}

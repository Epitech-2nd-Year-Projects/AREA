'use client'

import { useRouter } from 'next/navigation'
import { useTranslations } from 'next-intl'

import { Button } from '@/components/ui/button'
import { Card, CardContent, CardFooter } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import type { Service } from '@/lib/api/contracts/services'
import { useSubscribeServiceMutation } from '@/lib/api/openapi/services'
import type { SubscribeServiceResponseDTO } from '@/lib/api/contracts/openapi/services'
import {
  clearOAuthState,
  createClientOAuthState,
  persistOAuthState
} from '@/lib/auth/oauth'
import { DisconnectModal } from './disconnect-modal'

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
  const { mutateAsync: subscribeService, isPending: isSubscribing } =
    useSubscribeServiceMutation()

  const handleDisconnectConfirm = () => {
    // TODO: Implement service disconnect logic
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
    <Card className="flex h-full w-full flex-col overflow-hidden">
      <CardContent className="flex flex-1 flex-col items-center justify-center gap-2 p-6 text-center">
        <div className="flex h-16 w-16 items-center justify-center rounded-full bg-muted">
          <span className="text-2xl font-bold">
            {service.displayName.charAt(0).toUpperCase()}
          </span>
        </div>
        <h3 className="text-lg font-semibold">{service.displayName}</h3>
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

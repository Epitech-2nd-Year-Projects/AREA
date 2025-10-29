'use client'

import { useRouter } from 'next/navigation'
import Image from 'next/image'
import { useTranslations } from 'next-intl'
import { useQueryClient } from '@tanstack/react-query'

import { Lock } from 'lucide-react'
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

export function ServiceCard({
  service,
  authenticated,
  linked
}: ServiceCardProps) {
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

  return (
    <Card
      className="relative flex w-full cursor-pointer flex-col overflow-hidden transition-transform duration-200 ease-in-out hover:scale-105"
      onClick={() => router.push(`/explore/${service.name}`)}
    >
      {service.needsConnection && (
        <Lock
          className="absolute right-2 top-2 h-4 w-4 text-muted-foreground"
          aria-label="Requires connection"
        />
      )}
      <CardContent className="flex flex-col items-center gap-1 p-4 text-center">
        {logoUrl ? (
          <Image
            src={logoUrl}
            alt={`${service.displayName} logo`}
            className="h-12 w-12 rounded-full"
            width={48}
            height={48}
          />
        ) : (
          <div className="h-12 w-12 animate-pulse rounded-full bg-muted" />
        )}
        <h3 className="text-base font-semibold">{service.displayName}</h3>
        <div className="flex flex-wrap justify-center gap-2">
          {service.category && (
            <Badge variant="secondary" className="uppercase">
              {service.category}
            </Badge>
          )}
        </div>
      </CardContent>
      <CardFooter className="p-4" onClick={(e) => e.stopPropagation()}>
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

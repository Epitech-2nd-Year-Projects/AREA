'use client'
import { FilteredServiceCardList } from '@/components/services/filtered-service-card-list'
import { useTranslations } from 'next-intl'
import { useMemo } from 'react'
import {
  useServiceProvidersQuery,
  useServiceSubscriptionsQuery
} from '@/lib/api/openapi/services'
import { mapUserDTOToUser, useCurrentUserQuery } from '@/lib/api/openapi/auth'
import { Loader2 } from 'lucide-react'

export default function DashboardPage() {
  const t = useTranslations('DashboardPage')
  const { data: services, isLoading: isServicesLoading } =
    useServiceProvidersQuery()
  const { data: userData, isLoading: isUserLoading } = useCurrentUserQuery()
  const user = userData?.user ? mapUserDTOToUser(userData.user) : null
  const isUserAuthenticated = Boolean(user)

  const { data: subscriptionsData, isLoading: isSubscriptionsLoading } =
    useServiceSubscriptionsQuery({
      enabled: isUserAuthenticated
    })

  const userLinkedServices = useMemo(() => {
    if (!isUserAuthenticated) {
      return []
    }

    const providers =
      subscriptionsData?.subscriptions.map((sub) => sub.provider.name) ?? []

    return Array.from(new Set(providers))
  }, [subscriptionsData, isUserAuthenticated])

  const isLoading =
    isServicesLoading ||
    isUserLoading ||
    (isSubscriptionsLoading && isUserAuthenticated)

  if (isLoading) {
    return (
      <div className="flex h-[40vh] flex-col items-center justify-center gap-3">
        <Loader2 className="h-5 w-5 animate-spin" aria-hidden />
        <span className="text-muted-foreground text-sm">{t('loading')}</span>
      </div>
    )
  }

  return (
    <FilteredServiceCardList
      services={services ?? []}
      userLinkedServices={userLinkedServices}
      isUserAuthenticated={isUserAuthenticated}
    />
  )
}

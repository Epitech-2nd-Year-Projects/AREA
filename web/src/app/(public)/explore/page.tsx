'use client'
import { Loader2 } from 'lucide-react'
import { useTranslations } from 'next-intl'
import { useAboutQuery, extractServices } from '@/lib/api/openapi/about'
import { useCurrentUserQuery, mapUserDTOToUser } from '@/lib/api/openapi/auth'
import { ApiError } from '@/lib/api/http/errors'
import { ServiceCardList } from '@/components/services/service-card-list'

export default function ExplorePage() {
  const t = useTranslations('ExplorePage')

  const { data, isLoading: isServicesLoading, isError } = useAboutQuery()
  const {
    data: userData,
    isLoading: isUserLoading,
    error: userError
  } = useCurrentUserQuery({ retry: false })

  const isUnauthorized =
    userError instanceof ApiError && userError.status === 401
  const user =
    !isUnauthorized && userData?.user ? mapUserDTOToUser(userData.user) : null
  const userLinkedServices = user?.connectedServices ?? []
  const services = data ? extractServices(data) : []
  const isUserAuthenticated = Boolean(user)
  const isLoading = isServicesLoading || (isUserLoading && !isUnauthorized)

  if (isLoading) {
    return (
      <div className="mx-auto flex max-w-6xl items-center justify-center py-24">
        <Loader2 className="mr-2 h-6 w-6 animate-spin" aria-hidden />
        <span className="text-muted-foreground text-sm">{t('loading')}</span>
      </div>
    )
  }

  if (isError) {
    return (
      <div className="mx-auto max-w-2xl py-24 text-center">
        <p className="text-destructive text-sm">{t('error')}</p>
      </div>
    )
  }

  return (
    <div className="mx-auto flex max-w-6xl flex-col gap-12">
      <div className="flex flex-col gap-4">
        <h1 className="text-4xl font-bold tracking-tight">{t('title')}</h1>
        <p className="text-muted-foreground text-lg">{t('description')}</p>
      </div>
      <ServiceCardList
        services={services}
        userLinkedServices={userLinkedServices}
        isUserAuthenticated={isUserAuthenticated}
      />
    </div>
  )
}

'use client'
import { ServiceCardList } from '@/components/services/service-card-list'
import { Input } from '@/components/ui/input'
import { useTranslations } from 'next-intl'
import { useMemo, useState } from 'react'
import { useAboutQuery, extractServices } from '@/lib/api/openapi/about'
import {
  mapUserDTOToUser,
  useCurrentUserQuery,
  useIdentitiesQuery
} from '@/lib/api/openapi/auth'
import { Loader2 } from 'lucide-react'

export default function DashboardPage() {
  const t = useTranslations('DashboardPage')
  const { data: aboutData, isLoading: isAboutLoading } = useAboutQuery()
  const { data: userData, isLoading: isUserLoading } = useCurrentUserQuery()
  const user = userData?.user ? mapUserDTOToUser(userData.user) : null
  const isUserAuthenticated = Boolean(user)

  const services = useMemo(
    () => (aboutData ? extractServices(aboutData) : []),
    [aboutData]
  )

  const { data: identitiesData, isLoading: isIdentitiesLoading } =
    useIdentitiesQuery({
      enabled: isUserAuthenticated
    })

  const userLinkedServices = useMemo(() => {
    if (!isUserAuthenticated) {
      return []
    }

    const identityProviders =
      identitiesData?.identities?.map((identity) => identity.provider) ?? []

    return Array.from(new Set(identityProviders))
  }, [identitiesData, isUserAuthenticated])

  const isLoading =
    isAboutLoading || isUserLoading || (isIdentitiesLoading && isUserAuthenticated)

  const [searchValue, setSearchValue] = useState('')

  const filteredServices = useMemo(() => {
    const normalizedQuery = searchValue.trim().toLowerCase()

    if (!normalizedQuery) {
      return services
    }

    return services.filter((service) => {
      const serviceName = service.name.toLowerCase()
      const serviceDisplayName = service.displayName.toLowerCase()

      return (
        serviceName.includes(normalizedQuery) ||
        serviceDisplayName.includes(normalizedQuery)
      )
    })
  }, [searchValue, services])

  if (isLoading) {
    return (
      <div className="flex h-[40vh] flex-col items-center justify-center gap-3">
        <Loader2 className="h-5 w-5 animate-spin" aria-hidden />
        <span className="text-muted-foreground text-sm">{t('loading')}</span>
      </div>
    )
  }

  return (
    <div className="flex flex-col gap-4">
      <Input
        type="text"
        placeholder={t('searchServices')}
        value={searchValue}
        onChange={(event) => setSearchValue(event.target.value)}
      />
      <ServiceCardList
        services={filteredServices}
        userLinkedServices={userLinkedServices}
        isUserAuthenticated={isUserAuthenticated}
      />
    </div>
  )
}

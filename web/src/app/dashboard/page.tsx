'use client'
import { ServiceCardList } from '@/components/services/service-card-list'
import { Input } from '@/components/ui/input'
import { mockServices, mockUserLinkedServices } from '@/data/mocks'
import { useTranslations } from 'next-intl'
import { useMemo, useState } from 'react'

export default function DashboardPage() {
  const t = useTranslations('DashboardPage')
  const isUserAuthenticated = false

  // TODO: Replace with real data
  const services = mockServices
  const userLinkedServices = mockUserLinkedServices

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

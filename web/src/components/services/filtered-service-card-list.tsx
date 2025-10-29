'use client'

import { useMemo, useState } from 'react'
import { useTranslations } from 'next-intl'
import { Input } from '@/components/ui/input'
import { ServiceCardList } from '@/components/services/service-card-list'
import { Service } from '@/lib/api/contracts/services'

interface FilteredServiceCardListProps {
  services: Service[]
  userLinkedServices: string[]
  isUserAuthenticated: boolean
}

export function FilteredServiceCardList({
  services,
  userLinkedServices,
  isUserAuthenticated
}: FilteredServiceCardListProps) {
  const t = useTranslations('DashboardPage')
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

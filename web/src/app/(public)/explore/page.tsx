'use client'
import { useTranslations } from 'next-intl'
import { mockServices, mockUserLinkedServices } from '@/data/mocks'
import { ServiceCardList } from '@/components/service-card-list'

export default function ExplorePage() {
  const t = useTranslations('ExplorePage')

  // TODO: Replace with auth state
  const isUserAuthenticated = false

  // TODO: Replace with real data
  const services = mockServices
  const userLinkedServices = mockUserLinkedServices

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

'use client'
import { AreaCardList } from '@/components/areas/area-card-list'
import CreateAreaModal from '@/components/areas/create-area-modal'
import { Input } from '@/components/ui/input'
import { useLocale, useTranslations } from 'next-intl'
import { useMemo, useState, useEffect } from 'react'
import { toast } from 'sonner'
import { useAreasQuery } from '@/lib/api/openapi/areas'

export default function LinksPage() {
  const locale = useLocale()
  const t = useTranslations('LinksPage')
  const { data: areas, isLoading, isError, error } = useAreasQuery()
  const [searchValue, setSearchValue] = useState('')

  useEffect(() => {
    document.documentElement.lang = locale
  }, [locale])

  useEffect(() => {
    if (isError) {
      toast.error(error?.message ?? t('errorLoadingAreas'))
    }
  }, [isError, error, t])

  const filteredAreas = useMemo(() => {
    const userLinkedAreas = areas ?? []
    const normalizedQuery = searchValue.trim().toLowerCase()

    if (!normalizedQuery) {
      return userLinkedAreas
    }

    return userLinkedAreas.filter((area) => {
      const areaName = area.name.toLowerCase()
      const areaDescription = area.description.toLowerCase()
      const actionServiceName = area.action.serviceName.toLowerCase()
      const reactionServiceNames = area.reactions.map((reaction) =>
        reaction.serviceName.toLowerCase()
      )

      return [
        areaName,
        areaDescription,
        actionServiceName,
        ...reactionServiceNames
      ].some((value) => value.includes(normalizedQuery))
    })
  }, [areas, searchValue])

  const showEmptyState =
    !isLoading &&
    !isError &&
    filteredAreas.length === 0 &&
    searchValue.trim().length === 0
  const showNoMatches =
    !isLoading &&
    !isError &&
    filteredAreas.length === 0 &&
    searchValue.trim().length > 0

  return (
    <div className="flex flex-col gap-4">
      <div className="flex gap-4">
        <CreateAreaModal />
        <Input
          type="text"
          placeholder={t('searchAreas')}
          value={searchValue}
          onChange={(event) => setSearchValue(event.target.value)}
        />
      </div>
      {isLoading ? (
        <p className="text-sm text-muted-foreground">{t('loadingAreas')}</p>
      ) : showEmptyState ? (
        <p className="text-sm text-muted-foreground">{t('emptyState')}</p>
      ) : showNoMatches ? (
        <p className="text-sm text-muted-foreground">{t('noMatches')}</p>
      ) : (
        <AreaCardList areas={filteredAreas} />
      )}
    </div>
  )
}

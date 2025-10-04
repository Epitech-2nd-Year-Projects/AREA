'use client'
import { AreaCardList } from '@/components/areas/area-card-list'
import CreateAreaModal from '@/components/areas/create-area-modal'
import { Input } from '@/components/ui/input'
import { useTranslations } from 'next-intl'
import { useMemo, useState } from 'react'
import type { Area } from '@/lib/api/contracts/areas'

const EMPTY_AREAS: Area[] = []

export default function LinksPage() {
  const t = useTranslations('LinksPage')
  const userLinkedAreas = EMPTY_AREAS
  const [searchValue, setSearchValue] = useState('')

  const filteredAreas = useMemo(() => {
    const normalizedQuery = searchValue.trim().toLowerCase()

    if (!normalizedQuery) {
      return userLinkedAreas
    }

    return userLinkedAreas.filter((area) => {
      const areaName = area.name.toLowerCase()
      const areaDescription = area.description.toLowerCase()
      const actionServiceName = area.action.service_name.toLowerCase()
      const reactionServiceNames = area.reactions.map((reaction) =>
        reaction.service_name.toLowerCase()
      )

      return [
        areaName,
        areaDescription,
        actionServiceName,
        ...reactionServiceNames
      ].some((value) => value.includes(normalizedQuery))
    })
  }, [searchValue, userLinkedAreas])

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
      <AreaCardList areas={filteredAreas} />
    </div>
  )
}

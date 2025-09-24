import { AreaCard } from './area-card'
import { Area } from '@/lib/api/contracts/areas'

type AreaCardListProps = {
  areas: Area[]
}

export function AreaCardList({ areas }: AreaCardListProps) {
  return (
    <div className="grid items-stretch gap-6 sm:grid-cols-2 xl:grid-cols-4">
      {areas.map((area) => {
        return <AreaCard key={area.name} area={area} />
      })}
    </div>
  )
}

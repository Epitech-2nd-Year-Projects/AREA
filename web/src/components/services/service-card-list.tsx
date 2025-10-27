import type { Service } from '@/lib/api/contracts/services'
import { ServiceCard } from './service-card'

type ServiceCardListProps = {
  services: Service[]
  userLinkedServices: string[]
  isUserAuthenticated: boolean
}

export function ServiceCardList({
  services,
  userLinkedServices,
  isUserAuthenticated
}: ServiceCardListProps) {
  return (
    <div className="grid items-start gap-4 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5">
      {services.map((service) => {
        return (
          <ServiceCard
            key={service.name}
            service={service}
            authenticated={isUserAuthenticated}
            linked={userLinkedServices.includes(service.name)}
          />
        )
      })}
    </div>
  )
}

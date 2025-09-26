import { Service } from '@/lib/api/contracts/services'
import { ServiceCard } from './service-card'

type ServiceCardListProps = {
  services: Service[]
  userLinkedServices: string[]
  isUserAuthenticated: boolean
  isMinimal?: boolean
}

export function ServiceCardList({
  services,
  userLinkedServices,
  isUserAuthenticated,
  isMinimal = false
}: ServiceCardListProps) {
  return (
    <div className="grid items-start gap-6 sm:grid-cols-1 xl:grid-cols-2">
      {services.map((service) => {
        return (
          <ServiceCard
            key={service.name}
            service={service}
            authenticated={isUserAuthenticated}
            linked={userLinkedServices.includes(service.name)}
            isMinimal={isMinimal}
          />
        )
      })}
    </div>
  )
}

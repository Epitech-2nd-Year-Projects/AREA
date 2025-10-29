import type { About } from '@/lib/api/contracts/about'
import type { Action } from '@/lib/api/contracts/actions'
import type { Reaction } from '@/lib/api/contracts/reactions'
import type { Service } from '@/lib/api/contracts/services'
import type {
  AboutResponseDTO,
  ComponentDTO,
  ServiceDTO
} from '@/lib/api/contracts/openapi/about'

function toTitleCase(value: string) {
  return value
    .split(/[-_\s]+/)
    .filter(Boolean)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(' ')
}

function mapComponentToAction(
  component: ComponentDTO,
  serviceName: string
): Action {
  return {
    id: component.name,
    name: component.name,
    description: component.description,
    serviceName
  }
}

function mapComponentToReaction(
  component: ComponentDTO,
  serviceName: string
): Reaction {
  return {
    id: component.name,
    name: component.name,
    description: component.description,
    serviceName
  }
}

function mapService(service: ServiceDTO): Service {
  return {
    name: service.name,
    displayName: toTitleCase(service.name),
    description: '',
    actions: service.actions.map((component) =>
      mapComponentToAction(component, service.name)
    ),
    reactions: service.reactions.map((component) =>
      mapComponentToReaction(component, service.name)
    ),
    needsConnection: true
  }
}

export function mapAboutResponse(response: AboutResponseDTO): About {
  return {
    client: {
      host: response.client.host
    },
    server: {
      currentTime: response.server.currentTime * 1000,
      services: response.server.services.map(mapService)
    }
  }
}

export function extractServices(response: AboutResponseDTO): Service[] {
  return response.server.services.map(mapService)
}

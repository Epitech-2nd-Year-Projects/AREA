import type { AboutResponseDTO } from '@/lib/api/openapi/about'
import { mockAbout } from '../data'

function toComponentDTO(component: { name: string; description: string }) {
  return { name: component.name, description: component.description }
}

export async function getAboutMock(): Promise<AboutResponseDTO> {
  const services = mockAbout.server.services.map((service) => ({
    name: service.name,
    actions: service.actions.map(toComponentDTO),
    reactions: service.reactions.map(toComponentDTO)
  }))

  return {
    client: { host: mockAbout.client.host },
    server: {
      current_time: Math.floor(mockAbout.server.currentTime / 1000),
      services
    }
  }
}

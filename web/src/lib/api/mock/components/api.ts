import type { ComponentSummaryDTO } from '@/lib/api/contracts/openapi/areas'
import { mockServices } from '../data'

export async function getAvailableComponentsMock(params?: {
  kind?: 'action' | 'reaction'
  provider?: string
}): Promise<{ components: ComponentSummaryDTO[] }> {
  const components: ComponentSummaryDTO[] = []

  for (const service of mockServices) {
    if (params?.provider && params.provider !== service.name) continue

    if (!params?.kind || params.kind === 'action') {
      for (const a of service.actions) {
        components.push({
          id: a.id,
          kind: 'action',
          name: a.name,
          displayName: a.name,
          description: a.description,
          provider: {
            id: service.name,
            name: service.name,
            displayName: service.displayName
          }
        })
      }
    }

    if (!params?.kind || params.kind === 'reaction') {
      for (const r of service.reactions) {
        components.push({
          id: r.id,
          kind: 'reaction',
          name: r.name,
          displayName: r.name,
          description: r.description,
          provider: {
            id: service.name,
            name: service.name,
            displayName: service.displayName
          }
        })
      }
    }
  }

  return { components }
}


export type ServiceProviderSummaryDTO = {
  id: string
  name: string
  displayName: string
}

export type ComponentSummaryDTO = {
  id: string
  kind: 'action' | 'reaction'
  name: string
  displayName: string
  description?: string | null
  provider: ServiceProviderSummaryDTO
}

export type AreaComponentDTO = {
  configId: string
  componentId: string
  name?: string | null
  params?: Record<string, unknown> | null
  component: ComponentSummaryDTO
}

export type AreaDTO = {
  id: string
  name: string
  description?: string | null
  status: string
  createdAt: string
  updatedAt: string
  action: AreaComponentDTO
  reactions: AreaComponentDTO[]
}

export type ListAreasResponseDTO = {
  areas: AreaDTO[]
}

export type CreateAreaComponentRequestDTO = {
  componentId: string
  name?: string
  params?: Record<string, unknown>
}

export type CreateAreaRequestDTO = {
  name: string
  description?: string
  action: CreateAreaComponentRequestDTO
  reactions: CreateAreaComponentRequestDTO[]
}

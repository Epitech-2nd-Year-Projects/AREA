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
  metadata?: ComponentSummaryMetadataDTO
  provider: ServiceProviderSummaryDTO
}

export type ComponentSummaryMetadataDTO = {
  parameters?: ComponentParameterDTO[]
  [key: string]: unknown
}

export type ComponentParameterDTO = {
  key: string
  label?: string
  type: string
  required?: boolean
  description?: string
  options?: ComponentParameterOptionDTO[]
  [key: string]: unknown
}

export type ComponentParameterOptionDTO = {
  value: string
  label: string
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

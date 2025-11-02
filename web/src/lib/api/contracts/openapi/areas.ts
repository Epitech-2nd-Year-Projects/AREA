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

export type UpdateAreaActionRequestDTO = {
  configId: string
  name?: string
  params?: Record<string, unknown>
}

export type UpdateAreaReactionRequestDTO = {
  configId: string
  name?: string
  params?: Record<string, unknown>
}

export type UpdateAreaRequestDTO = {
  name?: string
  description?: string | null
  action?: UpdateAreaActionRequestDTO
  reactions?: UpdateAreaReactionRequestDTO[]
}

export type UpdateAreaStatusRequestDTO = {
  status: 'enabled' | 'disabled' | 'archived'
}

export type DuplicateAreaRequestDTO = {
  name?: string
  description?: string | null
}

export type AreaHistoryReactionDTO = {
  component: string
  provider: string
}

export type AreaHistoryEntryDTO = {
  jobId: string
  status: string
  attempt: number
  runAt: string
  createdAt: string
  updatedAt: string
  error?: string | null
  resultPayload?: Record<string, unknown>
  reaction: AreaHistoryReactionDTO
}

export type AreaHistoryResponseDTO = {
  executions: AreaHistoryEntryDTO[]
}

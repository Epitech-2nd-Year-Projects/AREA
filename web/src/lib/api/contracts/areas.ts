export type AreaStatus = 'enabled' | 'disabled' | 'archived'

export type AreaComponent = {
  id: string
  configId: string
  name: string
  description: string
  serviceName: string
  serviceDisplayName: string
  params: Record<string, unknown>
}

export type Area = {
  id: string
  name: string
  description: string
  status: AreaStatus
  enabled: boolean
  createdAt: Date
  updatedAt: Date
  action: AreaComponent
  reactions: AreaComponent[]
}

export type AreaHistoryReaction = {
  component: string
  provider: string
}

export type AreaHistoryEntry = {
  jobId: string
  status: string
  attempt: number
  runAt: Date
  createdAt: Date
  updatedAt: Date
  error?: string | null
  resultPayload?: Record<string, unknown>
  reaction: AreaHistoryReaction
}

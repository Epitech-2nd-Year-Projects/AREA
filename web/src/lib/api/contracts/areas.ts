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

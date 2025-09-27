export type UserComponentConfig = {
  id: string
  userId: string
  componentId: string
  name?: string
  params: Record<string, unknown>
  secretsRef?: string
  isActive: boolean
  createdAt: Date
  updatedAt: Date
}

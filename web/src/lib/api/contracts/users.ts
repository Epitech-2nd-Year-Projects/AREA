export enum UserRole {
  Admin = 'admin',
  Member = 'member'
}

export enum UserStatus {
  Active = 'active',
  Pending = 'pending',
  Suspended = 'suspended',
  Deleted = 'deleted'
}

export type User = {
  id: string
  email: string
  role: UserRole
  status?: string
  imageUrl?: string
  emailVerified: boolean
  connectedServices: string[]
  authMethod?: 'password' | 'oauth'
  hasPassword?: boolean
}

export enum UserRole {
  Admin = 'admin',
  User = 'user'
}

export type User = {
  id: string
  email: string
  imageUrl?: string
  role: UserRole
  connectedServices: string[]
}

export enum UserRole {
  Admin = 'admin',
  User = 'user'
}

export type User = {
  id: string
  name: string
  email: string
  imageUrl?: string
  role: UserRole
}

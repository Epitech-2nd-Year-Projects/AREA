import type { User } from '@/lib/api/contracts/users'
import { UserRole } from '@/lib/api/contracts/users'
import type { UserDTO } from '@/lib/api/contracts/openapi/auth'

type AdapterOptions = {
  connectedServices?: string[]
  imageUrl?: string | null
}

export function mapUserDTOToUser(
  dto: UserDTO,
  options: AdapterOptions = {}
): User {
  const normalizedStatus = dto.status?.toLowerCase() ?? ''

  const role = normalizedStatus === 'admin' ? UserRole.Admin : UserRole.User
  const emailVerified = normalizedStatus === 'active'

  return {
    id: dto.id,
    email: dto.email,
    role,
    emailVerified,
    imageUrl: options.imageUrl ?? undefined,
    connectedServices: options.connectedServices ?? []
  }
}

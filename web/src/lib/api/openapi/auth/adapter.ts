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

  const role = dto.role === 'admin' ? UserRole.Admin : UserRole.Member
  const emailVerified = normalizedStatus === 'active'

  return {
    id: dto.id,
    email: dto.email,
    role,
    emailVerified,
    status: dto.status,
    imageUrl: options.imageUrl ?? undefined,
    connectedServices: options.connectedServices ?? []
  }
}

import type { User } from '@/lib/api/contracts/users'
import { UserRole } from '@/lib/api/contracts/users'
import type { UserDTO, SessionAuthDTO } from '@/lib/api/contracts/openapi/auth'

type AdapterOptions = {
  connectedServices?: string[]
  imageUrl?: string | null
  sessionAuth?: SessionAuthDTO | null
}

export function mapUserDTOToUser(
  dto: UserDTO,
  options: AdapterOptions = {}
): User {
  const normalizedStatus = dto.status?.toLowerCase() ?? ''

  const role = dto.role === 'admin' ? UserRole.Admin : UserRole.Member
  const emailVerified = normalizedStatus === 'active'
  const authMethod = options.sessionAuth?.method

  return {
    id: dto.id,
    email: dto.email,
    role,
    emailVerified,
    status: dto.status,
    imageUrl: options.imageUrl ?? undefined,
    connectedServices: options.connectedServices ?? [],
    authMethod,
    hasPassword: authMethod === 'password'
  }
}

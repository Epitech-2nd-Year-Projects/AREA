export type LoginRequestDTO = {
  email: string
  password: string
}

export type VerifyEmailRequestDTO = {
  token: string
}

export type UserDTO = {
  id: string
  email: string
  status: string
  created_at: string
  updated_at: string
  last_login_at?: string | null
}

export type AuthSessionResponseDTO = {
  user: UserDTO
}

export type UserResponseDTO = {
  user: UserDTO
}

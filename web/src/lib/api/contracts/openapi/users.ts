export type RegisterUserRequestDTO = {
  email: string
  password: string
}

export type RegisterUserResponseDTO = {
  expires_at: string
}

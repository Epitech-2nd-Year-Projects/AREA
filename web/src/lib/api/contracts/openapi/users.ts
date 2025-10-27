export type RegisterUserRequestDTO = {
  email: string
  password: string
}

export type RegisterUserResponseDTO = {
  userId: string
  expiresAt: string
}

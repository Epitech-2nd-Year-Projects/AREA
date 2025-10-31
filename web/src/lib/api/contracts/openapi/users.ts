export type RegisterUserRequestDTO = {
  email: string
  password: string
}

export type RegisterUserResponseDTO = {
  userId: string
  expiresAt: string
}

export type AdminResetPasswordRequestDTO = {
  newPassword?: string
}

export type AdminUpdateEmailRequestDTO = {
  email?: string
  sendVerification?: boolean
}

export type AdminUpdateStatusRequestDTO = {
  status?: string
}

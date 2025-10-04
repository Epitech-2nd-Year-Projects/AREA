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

export type OAuthAuthorizationRequestDTO = {
  redirect_uri?: string
  scopes?: string[]
  state?: string
  prompt?: string
  use_pkce?: boolean
}

export type OAuthAuthorizationResponseDTO = {
  authorization_url: string
  state?: string
  code_verifier?: string
  code_challenge?: string
  code_challenge_method?: 'plain' | 'S256'
}

export type OAuthExchangeRequestDTO = {
  code: string
  redirect_uri?: string
  code_verifier?: string
  state?: string
}

export type SubscriptionSummaryDTO = {
  id: string
  providerId: string
  identityId?: string | null
  status: string
  scopeGrants?: string[]
  createdAt: string
  updatedAt?: string
}

export type SubscribeServiceRequestDTO = {
  scopes?: string[]
  redirectUri?: string
  state?: string
  prompt?: string
  usePkce?: boolean
}

export type SubscribeServiceResponseDTO = {
  status: 'authorization_required' | 'subscribed'
  authorization?: import('./auth').OAuthAuthorizationResponseDTO
  subscription?: SubscriptionSummaryDTO
}

export type SubscribeExchangeRequestDTO = {
  code: string
  redirectUri?: string
  codeVerifier?: string
}

export type SubscribeExchangeResponseDTO = {
  subscription: SubscriptionSummaryDTO
  identity?: import('./auth').IdentitySummaryDTO | null
}

export type ServiceProviderDetailDTO = {
  id: string
  name: string
  displayName: string
  category?: string | null
  oauthType: 'none' | 'oauth2' | 'apikey'
  enabled: boolean
  createdAt: string
  updatedAt: string
}

export type ServiceProviderListResponseDTO = {
  providers: ServiceProviderDetailDTO[]
}

export type UserSubscriptionDTO = {
  subscription: SubscriptionSummaryDTO
  provider: ServiceProviderDetailDTO
}

export type SubscriptionListResponseDTO = {
  subscriptions: UserSubscriptionDTO[]
}

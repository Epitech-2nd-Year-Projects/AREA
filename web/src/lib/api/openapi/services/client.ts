import { apiFetchClient } from '../../http/client'
import { buildClientOptions } from '../common'
import type { ClientRequestOptions } from '../common'
import type {
  SubscribeExchangeRequestDTO,
  SubscribeExchangeResponseDTO,
  SubscribeServiceRequestDTO,
  SubscribeServiceResponseDTO,
  SubscriptionListResponseDTO
} from '@/lib/api/contracts/openapi/services'
import { apiRuntime } from '@/lib/api/runtime'
import { listServiceProvidersMock } from '@/lib/api/mock/services'
import type { ServiceProviderListResponseDTO } from '@/lib/api/contracts/openapi/services'

export function subscribeServiceClient(
  provider: string,
  body?: SubscribeServiceRequestDTO,
  options?: ClientRequestOptions
) {
  if (apiRuntime.useMocks) {
    // No mock implementation for service subscription yet
    throw new Error('Service subscribe mock not implemented')
  }
  return apiFetchClient<SubscribeServiceResponseDTO>(
    `/v1/services/${provider}/subscribe`,
    {
      method: 'POST',
      body,
      ...buildClientOptions(options)
    }
  )
}

export function subscribeServiceExchangeClient(
  provider: string,
  body: SubscribeExchangeRequestDTO,
  options?: ClientRequestOptions
) {
  if (apiRuntime.useMocks) {
    // No mock implementation for service subscription exchange yet
    throw new Error('Service subscribe exchange mock not implemented')
  }
  return apiFetchClient<SubscribeExchangeResponseDTO>(
    `/v1/services/${provider}/subscribe/exchange`,
    {
      method: 'POST',
      body,
      ...buildClientOptions(options)
    }
  )
}

export function unsubscribeServiceClient(
  provider: string,
  options?: ClientRequestOptions
) {
  if (apiRuntime.useMocks) {
    throw new Error('Service unsubscribe mock not implemented')
  }

  return apiFetchClient<void>(`/v1/services/${provider}/subscription`, {
    method: 'DELETE',
    ...buildClientOptions(options)
  })
}

export function listServiceProvidersClient(options?: ClientRequestOptions) {
  if (apiRuntime.useMocks) {
    return listServiceProvidersMock()
  }
  return apiFetchClient<ServiceProviderListResponseDTO>(
    '/v1/services',
    buildClientOptions(options)
  )
}

export function listServiceSubscriptionsClient(options?: ClientRequestOptions) {
  if (apiRuntime.useMocks) {
    throw new Error('listServiceSubscriptions mock not implemented')
  }
  return apiFetchClient<SubscriptionListResponseDTO>(
    '/v1/services/subscriptions',
    buildClientOptions(options)
  )
}

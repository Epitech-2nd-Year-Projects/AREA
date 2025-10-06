import { apiFetchClient } from '../../http/client'
import { buildClientOptions } from '../common'
import type { ClientRequestOptions } from '../common'
import type {
  SubscribeExchangeRequestDTO,
  SubscribeExchangeResponseDTO,
  SubscribeServiceRequestDTO,
  SubscribeServiceResponseDTO
} from '@/lib/api/contracts/openapi/services'
import { apiRuntime } from '@/lib/api/runtime'

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

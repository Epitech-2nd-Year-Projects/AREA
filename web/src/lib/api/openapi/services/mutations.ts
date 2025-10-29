import { useMutation, type UseMutationOptions } from '@tanstack/react-query'
import type { ApiError } from '../../http/errors'
import type { ClientRequestOptions } from '../common'
import {
  subscribeServiceClient,
  subscribeServiceExchangeClient,
  unsubscribeServiceClient
} from './client'
import type {
  SubscribeExchangeRequestDTO,
  SubscribeExchangeResponseDTO,
  SubscribeServiceRequestDTO,
  SubscribeServiceResponseDTO
} from '@/lib/api/contracts/openapi/services'

type SubscribeServiceOptions = {
  provider: string
  body?: SubscribeServiceRequestDTO
  clientOptions?: ClientRequestOptions
}

type SubscribeServiceExchangeOptions = {
  provider: string
  body: SubscribeExchangeRequestDTO
  clientOptions?: ClientRequestOptions
}

type UnsubscribeServiceOptions = {
  provider: string
  clientOptions?: ClientRequestOptions
}

export function useSubscribeServiceMutation(
  options?: Omit<
    UseMutationOptions<
      SubscribeServiceResponseDTO,
      ApiError,
      SubscribeServiceOptions,
      unknown
    >,
    'mutationKey' | 'mutationFn'
  >
) {
  return useMutation({
    mutationFn: ({ provider, body, clientOptions }) =>
      subscribeServiceClient(provider, body, clientOptions),
    ...(options ?? {})
  })
}

export function useSubscribeServiceExchangeMutation(
  options?: Omit<
    UseMutationOptions<
      SubscribeExchangeResponseDTO,
      ApiError,
      SubscribeServiceExchangeOptions,
      unknown
    >,
    'mutationKey' | 'mutationFn'
  >
) {
  return useMutation({
    mutationFn: ({ provider, body, clientOptions }) =>
      subscribeServiceExchangeClient(provider, body, clientOptions),
    ...(options ?? {})
  })
}

export function useUnsubscribeServiceMutation(
  options?: Omit<
    UseMutationOptions<void, ApiError, UnsubscribeServiceOptions, unknown>,
    'mutationKey' | 'mutationFn'
  >
) {
  return useMutation({
    mutationFn: ({ provider, clientOptions }) =>
      unsubscribeServiceClient(provider, clientOptions),
    ...(options ?? {})
  })
}

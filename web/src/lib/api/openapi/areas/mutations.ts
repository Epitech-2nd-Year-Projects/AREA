import type { ClientRequestOptions } from '../common'
import {
  createAreaClient,
  deleteAreaClient,
  duplicateAreaClient,
  executeAreaClient,
  updateAreaClient,
  updateAreaStatusClient
} from './client'
import { areasMutationKeys } from './mutation-keys'
import { mapAreaDTOToArea } from './adapter'
import type {
  CreateAreaRequestDTO,
  DuplicateAreaRequestDTO,
  UpdateAreaRequestDTO,
  UpdateAreaStatusRequestDTO
} from '@/lib/api/contracts/openapi/areas'

export const areasMutations = {
  create: (options?: { clientOptions?: ClientRequestOptions }) => ({
    mutationKey: areasMutationKeys.create(),
    mutationFn: async (variables: CreateAreaRequestDTO) => {
      const response = await createAreaClient(variables, options?.clientOptions)
      return mapAreaDTOToArea(response)
    }
  }),
  update: (
    areaId: string,
    options?: { clientOptions?: ClientRequestOptions }
  ) => ({
    mutationKey: areasMutationKeys.update(areaId),
    mutationFn: async (variables: UpdateAreaRequestDTO) => {
      const response = await updateAreaClient(
        areaId,
        variables,
        options?.clientOptions
      )
      return mapAreaDTOToArea(response)
    }
  }),
  delete: (
    areaId: string,
    options?: { clientOptions?: ClientRequestOptions }
  ) => ({
    mutationKey: areasMutationKeys.delete(areaId),
    mutationFn: async () => {
      await deleteAreaClient(areaId, options?.clientOptions)
    }
  }),
  execute: (
    areaId: string,
    options?: { clientOptions?: ClientRequestOptions }
  ) => ({
    mutationKey: areasMutationKeys.execute(areaId),
    mutationFn: async () => {
      await executeAreaClient(areaId, options?.clientOptions)
    }
  }),
  updateStatus: (
    areaId: string,
    options?: { clientOptions?: ClientRequestOptions }
  ) => ({
    mutationKey: areasMutationKeys.updateStatus(areaId),
    mutationFn: async (variables: UpdateAreaStatusRequestDTO) => {
      const response = await updateAreaStatusClient(
        areaId,
        variables,
        options?.clientOptions
      )
      return mapAreaDTOToArea(response)
    }
  }),
  duplicate: (
    areaId: string,
    options?: { clientOptions?: ClientRequestOptions }
  ) => ({
    mutationKey: areasMutationKeys.duplicate(areaId),
    mutationFn: async (variables: DuplicateAreaRequestDTO | undefined) => {
      const response = await duplicateAreaClient(
        areaId,
        variables,
        options?.clientOptions
      )
      return mapAreaDTOToArea(response)
    }
  })
}

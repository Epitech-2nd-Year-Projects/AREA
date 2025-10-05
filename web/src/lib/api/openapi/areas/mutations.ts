import type { ClientRequestOptions } from '../common'
import { createAreaClient } from './client'
import { areasMutationKeys } from './mutation-keys'
import { mapAreaDTOToArea } from './adapter'
import type { CreateAreaRequestDTO } from '@/lib/api/contracts/openapi/areas'

export const areasMutations = {
  create: (options?: { clientOptions?: ClientRequestOptions }) => ({
    mutationKey: areasMutationKeys.create(),
    mutationFn: async (variables: CreateAreaRequestDTO) => {
      const response = await createAreaClient(variables, options?.clientOptions)
      return mapAreaDTOToArea(response)
    }
  })
}

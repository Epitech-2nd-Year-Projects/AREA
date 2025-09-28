import { Action } from './actions'
import { Reaction } from './reactions'

export type Area = {
  id: string
  name: string
  description: string
  enabled: boolean
  action: Action
  reactions: Reaction[]
}

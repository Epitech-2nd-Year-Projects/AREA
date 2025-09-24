import { Action } from './actions'
import { Reaction } from './reactions'

export type Area = {
  id: string
  name: string
  description: string
  action: Action
  reactions: Reaction[]
}

import { Action } from './actions'
import { Reaction } from './reactions'

export type Service = {
  name: string
  displayName: string
  description: string
  actions: Action[]
  reactions: Reaction[]
}

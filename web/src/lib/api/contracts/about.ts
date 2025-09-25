import { Service } from './services'

type Client = {
  host: string
}

type Server = {
  currentTime: number
  services: Service[]
}

export type About = {
  client: Client
  server: Server
}

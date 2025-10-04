export type AboutClientDTO = {
  host: string
}

export type ComponentDTO = {
  name: string
  description: string
}

export type ServiceDTO = {
  name: string
  actions: ComponentDTO[]
  reactions: ComponentDTO[]
}

export type AboutServerDTO = {
  current_time: number
  services: ServiceDTO[]
}

export type AboutResponseDTO = {
  client: AboutClientDTO
  server: AboutServerDTO
}

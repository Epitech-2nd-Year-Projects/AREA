export type ClientRequestOptions = {
  signal?: AbortSignal
  csrfToken?: string
  tryRefresh?: boolean
}

export type ServerRequestOptions = {
  cache?: RequestCache
  next?:
    | { revalidate?: number; tags?: string[] }
    | { revalidate?: false; tags?: string[] }
}

export function buildClientOptions(options?: ClientRequestOptions) {
  if (!options) return {}
  const { signal, csrfToken, tryRefresh } = options
  return { signal, csrfToken, tryRefresh }
}

export function buildServerOptions(options?: ServerRequestOptions) {
  if (!options) return {}
  const { cache, next } = options
  return { cache, next }
}

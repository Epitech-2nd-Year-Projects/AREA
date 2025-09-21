import type { ErrorResponseDTO } from '../contracts/errors'

export class ApiError extends Error {
  status: number
  code: string
  details?: unknown

  constructor(
    status: number,
    code: string,
    message: string,
    details?: unknown
  ) {
    super(message)
    this.name = 'ApiError'
    this.status = status
    this.code = code
    this.details = details ?? undefined
  }
}

export function isApiError(error: unknown): error is ApiError {
  return error instanceof ApiError
}

export async function parseAndThrowApiError(
  response: Response
): Promise<never> {
  let code = 'unknown_error'
  let message = response.statusText ?? 'Request failed'
  let details = null

  try {
    const data = (await response.json()) as Partial<ErrorResponseDTO>
    if (data?.code) code = String(data.code)
    if (data?.message) message = data.message
    details = data?.details
  } catch {}

  throw new ApiError(response.status, code, message, details)
}

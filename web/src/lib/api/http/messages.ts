import { ApiError } from './errors'

export function userMessageFromError(e: unknown): string {
  if (e instanceof DOMException && e.name === 'AbortError') {
    return 'Request was canceled.'
  }
  if (!(e instanceof ApiError)) {
    return 'Something went wrong. Please try again.'
  }

  switch (e.code) {
    case 'notFound':
      return 'The requested resource was not found.'
    default:
      return e.message || 'Unexpected error occurred.'
  }
}

export function isRetryableError(e: unknown): boolean {
  if (e instanceof DOMException && e.name === 'AbortError') return false
  if (!(e instanceof ApiError)) return true
  if (e.status === 429) return true
  return e.status >= 500
}

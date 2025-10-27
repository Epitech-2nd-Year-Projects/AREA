import { describe, expect, test } from 'vitest'

import { ApiError, isApiError, parseAndThrowApiError } from './errors'

describe('API error helpers', () => {
  test('identifies ApiError instances', () => {
    const error = new ApiError(400, 'badRequest', 'Invalid request payload')
    expect(error).toBeInstanceOf(Error)
    expect(isApiError(error)).toBe(true)
    expect(isApiError(new Error('plain'))).toBe(false)
  })

  test('parses API error payloads when available', async () => {
    const response = new Response(
      JSON.stringify({
        code: 'invalid_input',
        message: 'Invalid fields',
        details: { field: 'email' }
      }),
      {
        status: 422,
        statusText: 'Unprocessable Entity',
        headers: { 'Content-Type': 'application/json' }
      }
    )

    await expect(parseAndThrowApiError(response)).rejects.toMatchObject({
      status: 422,
      code: 'invalid_input',
      message: 'Invalid fields',
      details: { field: 'email' }
    })
  })

  test('provides sensible fallbacks when payload cannot be parsed', async () => {
    const response = {
      status: 500,
      statusText: 'Server Error',
      json: async () => {
        throw new Error('invalid json')
      }
    } as unknown as Response

    await expect(parseAndThrowApiError(response)).rejects.toBeInstanceOf(
      ApiError
    )

    await parseAndThrowApiError(response).catch((error) => {
      expect(error).toBeInstanceOf(ApiError)
      const apiError = error as ApiError
      expect(apiError.status).toBe(500)
      expect(apiError.code).toBe('unknownError')
      expect(apiError.details).toBeUndefined()
      expect(apiError.message).toBe('Server Error')
    })

    const noStatusText = {
      status: 404,
      statusText: undefined as unknown as string,
      json: async () => {
        throw new Error('invalid json')
      }
    } as unknown as Response

    await expect(parseAndThrowApiError(noStatusText)).rejects.toBeInstanceOf(
      ApiError
    )

    await parseAndThrowApiError(noStatusText).catch((error) => {
      expect(error).toBeInstanceOf(ApiError)
      const apiError = error as ApiError
      expect(apiError.status).toBe(404)
      expect(apiError.code).toBe('unknownError')
      expect(apiError.details).toBeUndefined()
      expect(apiError.message).toBe('Request failed')
    })
  })
})

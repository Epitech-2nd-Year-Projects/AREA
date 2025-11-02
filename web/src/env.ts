import { z } from 'zod'

const HTTP_URL_REGEX = /^https?:\/\//i

const trimTrailingSlash = (value: string) =>
  value.length > 1 && value.endsWith('/') ? value.replace(/\/+$/, '') : value

const ensureLeadingSlash = (value: string) =>
  value.startsWith('/') ? value : `/${value}`

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).optional(),
  NEXT_PUBLIC_API_URL: z
    .string()
    .trim()
    .min(1, 'NEXT_PUBLIC_API_URL is required')
    .refine(
      (value) => HTTP_URL_REGEX.test(value) || value.startsWith('/'),
      'NEXT_PUBLIC_API_URL must be an absolute http(s) URL or start with "\/"'
    )
    .transform((value) => trimTrailingSlash(value)),
  API_PROXY_TARGET: z
    .string()
    .trim()
    .optional()
    .transform((value) =>
      value && value.length > 0 ? trimTrailingSlash(value) : undefined
    )
    .refine(
      (value) => value === undefined || HTTP_URL_REGEX.test(value),
      'API_PROXY_TARGET must be a valid http(s) URL'
    ),
  CORS_ALLOWED_ORIGIN: z
    .string()
    .trim()
    .optional()
    .refine((value) => {
      if (!value) return true
      try {
        const url = new URL(value)
        return url.protocol === 'http:' || url.protocol === 'https:'
      } catch {
        return false
      }
    }, 'CORS_ALLOWED_ORIGIN must be a valid http(s) origin'),
  NEXT_PUBLIC_API_MODE: z.enum(['live', 'mock']).default('mock')
})

const parsed = envSchema.safeParse({
  NODE_ENV: process.env.NODE_ENV,
  NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL,
  API_PROXY_TARGET: process.env.API_PROXY_TARGET,
  CORS_ALLOWED_ORIGIN: process.env.CORS_ALLOWED_ORIGIN,
  NEXT_PUBLIC_API_MODE: process.env.NEXT_PUBLIC_API_MODE
})

if (!parsed.success) {
  const flattened = parsed.error.flatten()
  const messages = [
    ...Object.entries(flattened.fieldErrors).flatMap(([key, errs]) =>
      (errs ?? []).map((message) => `${key}: ${message}`)
    ),
    ...(flattened.formErrors ?? [])
  ]
  const details = messages.join('\n')
  throw new Error(`Invalid environment variables\n${details}`)
}

const envData = parsed.data
const baseUrl = envData.NEXT_PUBLIC_API_URL
const isRelativeBase = !HTTP_URL_REGEX.test(baseUrl)
const basePath = isRelativeBase ? baseUrl : new URL(baseUrl).pathname
const proxyTarget = envData.API_PROXY_TARGET ?? null
const corsAllowedOrigin = envData.CORS_ALLOWED_ORIGIN ?? null
const apiMode = envData.NEXT_PUBLIC_API_MODE

const isBrowser = typeof window !== 'undefined'

if (!isBrowser && isRelativeBase && !proxyTarget) {
  throw new Error(
    'API_PROXY_TARGET is required when NEXT_PUBLIC_API_URL is a relative path'
  )
}

if (!isBrowser && isRelativeBase && proxyTarget) {
  const proxyPath = new URL(proxyTarget).pathname || '/'
  if (proxyPath !== basePath) {
    throw new Error(
      'API_PROXY_TARGET must include the same path segment as NEXT_PUBLIC_API_URL when using a relative path'
    )
  }
}

const buildUrl = (path: string) => {
  if (!path) throw new Error('Path is required when building an API URL')

  const normalized = ensureLeadingSlash(path)
  const withoutBasePath =
    basePath !== '/' && normalized.startsWith(basePath)
      ? normalized.slice(basePath.length) || '/'
      : normalized

  const base = baseUrl === '/' ? '' : baseUrl
  const baseForContext = !isBrowser && proxyTarget ? proxyTarget : base
  if (withoutBasePath === '/') {
    return baseForContext || '/'
  }

  return `${baseForContext}${withoutBasePath}`
}

process.env.NEXT_PUBLIC_API_URL = baseUrl
if (proxyTarget) process.env.API_PROXY_TARGET = proxyTarget
if (corsAllowedOrigin) process.env.CORS_ALLOWED_ORIGIN = corsAllowedOrigin
process.env.NEXT_PUBLIC_API_MODE = apiMode

export const env = {
  NODE_ENV: envData.NODE_ENV ?? 'development',
  NEXT_PUBLIC_API_URL: baseUrl,
  API_PROXY_TARGET: proxyTarget,
  CORS_ALLOWED_ORIGIN: corsAllowedOrigin,
  NEXT_PUBLIC_API_MODE: apiMode
} as const

export const apiConfig = {
  baseUrl,
  isRelative: isRelativeBase,
  basePath,
  proxyTarget,
  corsAllowedOrigin,
  buildUrl
} as const

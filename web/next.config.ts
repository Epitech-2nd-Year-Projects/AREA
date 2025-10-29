import type { NextConfig } from 'next'
import createNextIntlPlugin from 'next-intl/plugin'

import { apiConfig } from './src/env'

const nextConfig: NextConfig = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'img.logo.dev',
      },
    ],
  },
  turbopack: { root: __dirname },
  async rewrites() {
    if (!apiConfig.isRelative || !apiConfig.proxyTarget) return []

    return [
      {
        source: apiConfig.basePath,
        destination: apiConfig.proxyTarget
      },
      {
        source: `${apiConfig.basePath}/:path*`,
        destination: `${apiConfig.proxyTarget}/:path*`
      }
    ]
  },
  async headers() {
    if (!apiConfig.isRelative || !apiConfig.corsAllowedOrigin) return []

    const corsHeaders = [
      {
        key: 'Access-Control-Allow-Origin',
        value: apiConfig.corsAllowedOrigin
      },
      { key: 'Access-Control-Allow-Credentials', value: 'true' },
      {
        key: 'Access-Control-Allow-Methods',
        value: 'GET,POST,PATCH,DELETE,OPTIONS'
      },
      {
        key: 'Access-Control-Allow-Headers',
        value: 'Content-Type,Authorization,X-CSRF-Token'
      }
    ]

    return [
      {
        source: apiConfig.basePath,
        headers: corsHeaders
      },
      {
        source: `${apiConfig.basePath}/:path*`,
        headers: corsHeaders
      }
    ]
  }
}

const withNextIntl = createNextIntlPlugin()
export default withNextIntl(nextConfig)

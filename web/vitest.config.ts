import path from 'node:path'

import { defineConfig } from 'vitest/config'

export default defineConfig({
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src')
    }
  },
  esbuild: {
    jsx: 'automatic',
    jsxImportSource: 'react'
  },
  test: {
    environment: 'jsdom',
    globals: true,
    exclude: ['e2e/**'],
    include: ['src/**/*.{test,spec}.ts?(x)'],
    pool: 'threads',
    setupFiles: ['./vitest.setup.ts']
  }
})

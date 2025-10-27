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
    include: ['e2e/**/*.e2e.test.tsx'],
    pool: 'threads',
    poolOptions: { threads: { singleThread: true } },
    setupFiles: ['./vitest.setup.ts']
  }
})

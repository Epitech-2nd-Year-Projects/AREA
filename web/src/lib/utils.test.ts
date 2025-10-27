import { describe, expect, it } from 'vitest'
import { cn } from './utils'

describe('cn', () => {
  it('concatenates class names', () => {
    expect(cn('bg-red-500', 'text-white', 'font-semibold')).toBe(
      'bg-red-500 text-white font-semibold'
    )
  })

  it('drops falsy values before merging', () => {
    const shouldHide = false

    expect(cn('text-sm', shouldHide && 'hidden', null, undefined)).toBe(
      'text-sm'
    )
  })

  it('resolves conflicting tailwind utilities using last-one-wins', () => {
    expect(cn('p-2', 'sm:p-4', 'p-6')).toBe('sm:p-4 p-6')
  })
})

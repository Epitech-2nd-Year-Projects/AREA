import '@testing-library/jest-dom/vitest'

import React from 'react'
import { vi } from 'vitest'

vi.mock('next/link', () => {
  const NextLinkMock = React.forwardRef<
    HTMLAnchorElement,
    React.ComponentPropsWithoutRef<'a'> & { href: string | URL }
  >(({ href, children, ...props }, ref) => {
    const resolvedHref = href ? String(href) : ''

    return React.createElement(
      'a',
      { ...props, href: resolvedHref, ref },
      children
    )
  })
  NextLinkMock.displayName = 'NextLinkMock'

  return {
    __esModule: true,
    default: NextLinkMock
  }
})

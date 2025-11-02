import '@testing-library/jest-dom/vitest'

import React from 'react'
import { vi } from 'vitest'

vi.mock('next/link', () => {
  type NextLinkProps = React.ComponentPropsWithoutRef<'a'> & {
    href: string | URL
    prefetch?: boolean
    replace?: boolean
    scroll?: boolean
    shallow?: boolean
    passHref?: boolean
    legacyBehavior?: boolean
    locale?: string
  }

  const NextLinkMock = React.forwardRef<HTMLAnchorElement, NextLinkProps>(
    ({ href, children, ...props }, ref) => {
      const resolvedHref = href ? String(href) : ''
      const {
        prefetch: _prefetch,
        replace: _replace,
        scroll: _scroll,
        shallow: _shallow,
        passHref: _passHref,
        legacyBehavior: _legacyBehavior,
        locale: _locale,
        ...anchorProps
      } = props

      return React.createElement(
        'a',
        { ...anchorProps, href: resolvedHref, ref },
        children
      )
    }
  )
  NextLinkMock.displayName = 'NextLinkMock'

  return {
    __esModule: true,
    default: NextLinkMock
  }
})

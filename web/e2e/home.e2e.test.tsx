import React from 'react'
import { NextIntlClientProvider } from 'next-intl'
import { render, screen, cleanup } from '@testing-library/react'
import { afterEach, describe, expect, test } from 'vitest'
import HomePage from '@/app/(public)/page'
import enMessages from '../messages/en.json'

describe('Home page (integration)', () => {
  afterEach(() => cleanup())

  test('renders translated hero and primary CTA', () => {
    render(
      <NextIntlClientProvider locale="en" messages={enMessages}>
        <HomePage />
      </NextIntlClientProvider>
    )

    expect(
      screen.getByRole('heading', {
        level: 1,
        name: /Build reliable automations without touching a server/i
      })
    ).toBeInTheDocument()

    expect(
      screen.getByRole('link', { name: /Get started for free/i })
    ).toHaveAttribute('href', '/login')
  })
})

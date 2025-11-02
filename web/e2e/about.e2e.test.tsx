import React from 'react'
import { NextIntlClientProvider } from 'next-intl'
import { cleanup, render, screen } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, test, vi } from 'vitest'
import type { AboutResponseDTO } from '@/lib/api/contracts/openapi/about'
import enMessages from '../messages/en.json'

const useAboutQueryMock = vi.hoisted(() => vi.fn())
const toastErrorMock = vi.hoisted(() => vi.fn())

vi.mock('@/lib/api/openapi/about', async () => {
  const adapter = await vi.importActual<
    typeof import('@/lib/api/openapi/about/adapter')
  >('@/lib/api/openapi/about/adapter')

  return {
    ...adapter,
    useAboutQuery: useAboutQueryMock
  }
})

vi.mock('sonner', () => ({
  toast: {
    error: toastErrorMock
  }
}))

import AboutPage from '@/app/(public)/about/page'

const renderAboutPage = () =>
  render(
    <NextIntlClientProvider locale="en" messages={enMessages}>
      <AboutPage />
    </NextIntlClientProvider>
  )

describe('AboutPage (integration)', () => {
  beforeEach(() => {
    useAboutQueryMock.mockReset()
    toastErrorMock.mockReset()
  })

  afterEach(() => {
    cleanup()
  })

  test('shows a loading indicator while fetching data', () => {
    useAboutQueryMock.mockReturnValue({
      data: undefined,
      isLoading: true,
      isError: false
    })

    renderAboutPage()

    expect(screen.getByText(enMessages.AboutPage.loading)).toBeInTheDocument()
    expect(
      screen.queryByRole('heading', { name: enMessages.AboutPage.title })
    ).not.toBeInTheDocument()
  })

  test('renders server details when the about query succeeds', () => {
    const response: AboutResponseDTO = {
      client: { host: 'example.area.dev' },
      server: {
        currentTime: 1_714_588_800,
        services: [
          {
            name: 'weather_station',
            actions: [
              {
                name: 'fetch_weather',
                description: 'Retrieves current weather information'
              }
            ],
            reactions: [
              {
                name: 'send_alert',
                description: 'Sends a notification to subscribers'
              }
            ]
          }
        ]
      }
    }

    useAboutQueryMock.mockReturnValue({
      data: response,
      isLoading: false,
      isError: false
    })

    renderAboutPage()

    expect(
      screen.getByRole('heading', { name: enMessages.AboutPage.title })
    ).toBeInTheDocument()
    expect(screen.getByText('example.area.dev')).toBeInTheDocument()
    expect(screen.getByText('Weather Station')).toBeInTheDocument()
    expect(screen.getByText('fetch_weather')).toBeInTheDocument()
    expect(screen.getByText('send_alert')).toBeInTheDocument()
    expect(
      screen.getByText(enMessages.AboutPage.description)
    ).toBeInTheDocument()
  })

  test('shows an error toast when the about query fails', () => {
    useAboutQueryMock.mockReturnValue({
      data: undefined,
      isLoading: false,
      isError: true
    })

    renderAboutPage()

    expect(toastErrorMock).toHaveBeenCalledWith(enMessages.AboutPage.error)
    expect(
      screen.queryByRole('heading', { name: enMessages.AboutPage.title })
    ).not.toBeInTheDocument()
  })
})

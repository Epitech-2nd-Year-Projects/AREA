import React from 'react'
import { NextIntlClientProvider } from 'next-intl'
import { cleanup, render, screen, waitFor } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, test, vi } from 'vitest'
import type { Service } from '@/lib/api/contracts/services'
import { ApiError } from '@/lib/api/http/errors'
import enMessages from '../messages/en.json'

const useServiceProvidersQueryMock = vi.hoisted(() => vi.fn())
const useCurrentUserQueryMock = vi.hoisted(() => vi.fn())
const useServiceSubscriptionsQueryMock = vi.hoisted(() => vi.fn())
const toastErrorMock = vi.hoisted(() => vi.fn())
const filteredServiceListSpy = vi.hoisted(() => vi.fn())

vi.mock('@/lib/api/openapi/services', () => ({
  useServiceProvidersQuery: useServiceProvidersQueryMock,
  useServiceSubscriptionsQuery: useServiceSubscriptionsQueryMock
}))

vi.mock('@/lib/api/openapi/auth', async () => {
  const adapter = await vi.importActual<
    typeof import('@/lib/api/openapi/auth/adapter')
  >('@/lib/api/openapi/auth/adapter')

  return {
    ...adapter,
    useCurrentUserQuery: useCurrentUserQueryMock
  }
})

vi.mock('@/components/services/filtered-service-card-list', () => ({
  FilteredServiceCardList: (props: {
    services: Service[]
    userLinkedServices: string[]
    isUserAuthenticated: boolean
  }) => {
    filteredServiceListSpy(props)
    return (
      <div data-testid="filtered-service-card-list">
        {props.services.map((service) => service.displayName).join(', ')}
      </div>
    )
  }
}))

vi.mock('sonner', () => ({
  toast: {
    error: toastErrorMock
  }
}))

import ExplorePage from '@/app/(public)/explore/page'

const renderExplorePage = () =>
  render(
    <NextIntlClientProvider locale="en" messages={enMessages}>
      <ExplorePage />
    </NextIntlClientProvider>
  )

describe('ExplorePage (integration)', () => {
  beforeEach(() => {
    useServiceProvidersQueryMock.mockReset()
    useCurrentUserQueryMock.mockReset()
    useServiceSubscriptionsQueryMock.mockReset()
    toastErrorMock.mockReset()
    filteredServiceListSpy.mockReset()
  })

  afterEach(() => {
    cleanup()
  })

  test('shows a loading indicator while services are loading', () => {
    useServiceProvidersQueryMock.mockReturnValue({
      data: undefined,
      isLoading: true,
      isError: false
    })
    useCurrentUserQueryMock.mockReturnValue({
      data: undefined,
      isLoading: false,
      error: undefined
    })
    useServiceSubscriptionsQueryMock.mockReturnValue({
      data: undefined,
      isLoading: false
    })

    renderExplorePage()

    expect(screen.getByText(enMessages.ExplorePage.loading)).toBeInTheDocument()
    expect(
      screen.queryByRole('heading', { name: enMessages.ExplorePage.title })
    ).not.toBeInTheDocument()
    expect(filteredServiceListSpy).not.toHaveBeenCalled()
  })

  test('renders services for guests without requesting subscriptions', () => {
    const services: Service[] = [
      {
        name: 'notion',
        displayName: 'Notion',
        description: 'Workspace platform',
        actions: [],
        reactions: []
      },
      {
        name: 'asana',
        displayName: 'Asana',
        description: 'Project management',
        actions: [],
        reactions: []
      }
    ]

    useServiceProvidersQueryMock.mockReturnValue({
      data: services,
      isLoading: false,
      isError: false
    })
    useCurrentUserQueryMock.mockReturnValue({
      data: undefined,
      isLoading: false,
      error: new ApiError(401, 'unauthorized', 'Unauthorized')
    })
    useServiceSubscriptionsQueryMock.mockReturnValue({
      data: { subscriptions: [] },
      isLoading: false
    })

    renderExplorePage()

    expect(
      screen.getByRole('heading', { name: enMessages.ExplorePage.title })
    ).toBeInTheDocument()
    expect(
      screen.getByText(enMessages.ExplorePage.description)
    ).toBeInTheDocument()
    expect(screen.getByTestId('filtered-service-card-list').textContent).toBe(
      'Notion, Asana'
    )
    expect(filteredServiceListSpy).toHaveBeenCalledWith({
      services,
      userLinkedServices: [],
      isUserAuthenticated: false
    })
    expect(useServiceSubscriptionsQueryMock).toHaveBeenCalledWith({
      enabled: false
    })
  })

  test('shows an error toast when services query fails', async () => {
    useServiceProvidersQueryMock.mockReturnValue({
      data: undefined,
      isLoading: false,
      isError: true
    })
    useCurrentUserQueryMock.mockReturnValue({
      data: undefined,
      isLoading: false,
      error: undefined
    })
    useServiceSubscriptionsQueryMock.mockReturnValue({
      data: undefined,
      isLoading: false
    })

    renderExplorePage()

    await waitFor(() =>
      expect(toastErrorMock).toHaveBeenCalledWith(enMessages.ExplorePage.error)
    )
    expect(filteredServiceListSpy).not.toHaveBeenCalled()
  })
})

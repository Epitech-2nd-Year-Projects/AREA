import React from 'react'
import { NextIntlClientProvider } from 'next-intl'
import { cleanup, fireEvent, render, screen } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, test, vi } from 'vitest'
import type { Service } from '@/lib/api/contracts/services'
import enMessages from '../messages/en.json'

const serviceCardListSpy = vi.hoisted(() => vi.fn())

vi.mock('@/components/services/service-card-list', () => ({
  ServiceCardList: (props: {
    services: Service[]
    userLinkedServices: string[]
    isUserAuthenticated: boolean
  }) => {
    serviceCardListSpy(props)
    return (
      <div data-testid="service-card-list">
        {props.services.map((service) => service.displayName).join(', ')}
      </div>
    )
  }
}))

import { FilteredServiceCardList } from '@/components/services/filtered-service-card-list'

const renderFilteredServiceList = (overrides?: {
  services?: Service[]
  userLinkedServices?: string[]
  isUserAuthenticated?: boolean
}) => {
  const services = overrides?.services ?? [
    {
      name: 'google-drive',
      displayName: 'Google Drive',
      description: 'Cloud file storage',
      actions: [],
      reactions: []
    },
    {
      name: 'slack',
      displayName: 'Slack',
      description: 'Team communication',
      actions: [],
      reactions: []
    }
  ]

  const userLinkedServices = overrides?.userLinkedServices ?? ['slack']
  const isUserAuthenticated = overrides?.isUserAuthenticated ?? true

  return render(
    <NextIntlClientProvider locale="en" messages={enMessages}>
      <FilteredServiceCardList
        services={services}
        userLinkedServices={userLinkedServices}
        isUserAuthenticated={isUserAuthenticated}
      />
    </NextIntlClientProvider>
  )
}

describe('FilteredServiceCardList (integration)', () => {
  beforeEach(() => {
    serviceCardListSpy.mockReset()
  })

  afterEach(() => {
    cleanup()
  })

  test('renders the search input and forwards the initial services to the card list', () => {
    renderFilteredServiceList()

    expect(
      screen.getByPlaceholderText(enMessages.DashboardPage.searchServices)
    ).toBeInTheDocument()
    expect(serviceCardListSpy).toHaveBeenCalledTimes(1)

    const initialCallArgs = serviceCardListSpy.mock.calls[0][0]
    expect(initialCallArgs.services).toHaveLength(2)
    expect(screen.getByTestId('service-card-list').textContent).toContain(
      'Google Drive'
    )
    expect(screen.getByTestId('service-card-list').textContent).toContain(
      'Slack'
    )
  })

  test('filters the service list using a case-insensitive search query', () => {
    renderFilteredServiceList()

    const searchInput = screen.getByPlaceholderText(
      enMessages.DashboardPage.searchServices
    )

    fireEvent.change(searchInput, { target: { value: 'drive' } })

    const lastCallArgs =
      serviceCardListSpy.mock.calls[serviceCardListSpy.mock.calls.length - 1][0]

    expect(lastCallArgs.services).toEqual([
      expect.objectContaining({ name: 'google-drive' })
    ])
    expect(screen.getByTestId('service-card-list').textContent).toBe(
      'Google Drive'
    )
  })
})

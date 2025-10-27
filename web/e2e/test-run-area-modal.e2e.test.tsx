import React from 'react'
import { afterEach, beforeEach, describe, expect, test, vi } from 'vitest'
import { cleanup, fireEvent, render, screen } from '@testing-library/react'
import { NextIntlClientProvider } from 'next-intl'

import { TestRunAreaModal } from '@/components/areas/test-run-area-modal'
import type { Area } from '@/lib/api/contracts/areas'
import enMessages from '../messages/en.json'

const areaFixture: Area = {
  id: 'area-1',
  name: 'Test workflow',
  description: 'Simulated workflow for testing',
  status: 'enabled',
  enabled: true,
  createdAt: new Date('2024-01-01T00:00:00.000Z'),
  updatedAt: new Date('2024-01-01T00:00:00.000Z'),
  action: {
    id: 'action-1',
    configId: 'config-action',
    name: 'New event',
    description: 'Triggers when a new event happens',
    serviceName: 'events',
    serviceDisplayName: 'Events Service',
    params: {}
  },
  reactions: [
    {
      id: 'reaction-1',
      configId: 'config-reaction',
      name: 'Send notification',
      description: 'Delivers a notification to the user',
      serviceName: 'notifications',
      serviceDisplayName: 'Notification Service',
      params: {}
    }
  ]
}

const renderModal = (
  props?: Partial<React.ComponentProps<typeof TestRunAreaModal>>
) =>
  render(
    <NextIntlClientProvider locale="en" messages={enMessages}>
      <TestRunAreaModal
        area={areaFixture}
        open
        onOpenChange={() => {}}
        {...props}
      />
    </NextIntlClientProvider>
  )

describe('TestRunAreaModal (integration)', () => {
  beforeEach(() => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date('2024-05-01T12:34:56.000Z'))
  })

  afterEach(() => {
    cleanup()
    vi.useRealTimers()
  })

  test('renders idle state by default', () => {
    renderModal()

    expect(
      screen.getByRole('heading', {
        name: enMessages.TestRunAreaModal.title,
        level: 2
      })
    ).toBeInTheDocument()
    expect(
      screen.getByText(enMessages.TestRunAreaModal.statusIdle)
    ).toBeInTheDocument()
    expect(
      screen.getByText(enMessages.TestRunAreaModal.idleDescription)
    ).toBeInTheDocument()
  })

  test('updates summary after running the test', () => {
    const onOpenChange = vi.fn()
    renderModal({ onOpenChange })

    const runButton = screen.getByRole('button', {
      name: enMessages.TestRunAreaModal.runTest
    })
    fireEvent.click(runButton)

    expect(
      screen.getByText(enMessages.TestRunAreaModal.statusCompleted)
    ).toBeInTheDocument()
    expect(
      screen.getByRole('button', {
        name: enMessages.TestRunAreaModal.runAgain
      })
    ).toBeInTheDocument()
    expect(screen.getByText(/Simulated at/)).toBeInTheDocument()

    const closeButtons = screen.getAllByRole('button', {
      name: enMessages.TestRunAreaModal.close
    })
    fireEvent.click(closeButtons[0])
    expect(onOpenChange).toHaveBeenCalledWith(false)
  })
})

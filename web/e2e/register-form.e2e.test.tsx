import React from 'react'
import {
  afterEach,
  beforeEach,
  describe,
  expect,
  test,
  vi,
  type Mock
} from 'vitest'
import {
  cleanup,
  fireEvent,
  render,
  screen,
  waitFor
} from '@testing-library/react'
import { NextIntlClientProvider } from 'next-intl'

const { pushMock, mutateAsyncMock } = vi.hoisted(() => {
  return {
    pushMock: vi.fn(),
    mutateAsyncMock: vi.fn()
  }
})

vi.mock('next/navigation', () => ({
  useRouter: () => ({ push: pushMock })
}))

vi.mock('@/lib/api/openapi/users', () => ({
  useRegisterUserMutation: () => ({
    mutateAsync: mutateAsyncMock,
    isPending: false
  })
}))

import { RegisterForm } from '@/components/authentication/register-form'
import enMessages from '../messages/en.json'

const renderForm = () =>
  render(
    <NextIntlClientProvider locale="en" messages={enMessages}>
      <RegisterForm />
    </NextIntlClientProvider>
  )

describe('RegisterForm (integration)', () => {
  beforeEach(() => {
    ;(pushMock as Mock).mockReset()
    ;(mutateAsyncMock as Mock).mockReset()
  })

  afterEach(() => {
    cleanup()
    vi.clearAllMocks()
  })

  test('shows validation message when email is missing', async () => {
    renderForm()

    const submitButton = screen.getByRole('button', {
      name: enMessages.RegisterPage.register
    })
    const form = submitButton.closest('form')
    expect(form).not.toBeNull()
    fireEvent.submit(form!)

    const alert = await screen.findByRole('alert')
    expect(alert).toHaveTextContent(
      enMessages.RegisterPage.errors.emailRequired
    )
    expect(mutateAsyncMock).not.toHaveBeenCalled()
  })

  test('shows validation message when passwords do not match', async () => {
    renderForm()

    const emailInput = screen.getByLabelText(enMessages.RegisterPage.email, {
      selector: 'input'
    })
    const passwordInput = screen.getByLabelText(
      enMessages.RegisterPage.password,
      {
        selector: 'input'
      }
    )
    const confirmInput = screen.getByLabelText(
      enMessages.RegisterPage.confirmPassword,
      {
        selector: 'input'
      }
    )

    fireEvent.input(emailInput, { target: { value: 'user@example.com' } })
    fireEvent.input(passwordInput, { target: { value: 'password123' } })
    fireEvent.input(confirmInput, { target: { value: 'password456' } })

    const submitButton = screen.getByRole('button', {
      name: enMessages.RegisterPage.register
    })
    const form = submitButton.closest('form')
    expect(form).not.toBeNull()
    fireEvent.submit(form!)

    const alert = await screen.findByRole('alert')
    expect(alert).toHaveTextContent(
      enMessages.RegisterPage.errors.passwordMismatch
    )
    expect(mutateAsyncMock).not.toHaveBeenCalled()
  })

  test('submits valid details and redirects to login', async () => {
    renderForm()

    const emailInput = screen.getByLabelText(enMessages.RegisterPage.email, {
      selector: 'input'
    })
    const passwordInput = screen.getByLabelText(
      enMessages.RegisterPage.password,
      {
        selector: 'input'
      }
    )
    const confirmInput = screen.getByLabelText(
      enMessages.RegisterPage.confirmPassword,
      {
        selector: 'input'
      }
    )

    fireEvent.input(emailInput, { target: { value: 'user@example.com' } })
    fireEvent.input(passwordInput, { target: { value: 'password123' } })
    fireEvent.input(confirmInput, { target: { value: 'password123' } })
    ;(mutateAsyncMock as Mock).mockResolvedValue({
      userId: 'user-123',
      expiresAt: '2024-12-31T00:00:00.000Z'
    })

    const submitButton = screen.getByRole('button', {
      name: enMessages.RegisterPage.register
    })
    const form = submitButton.closest('form')
    expect(form).not.toBeNull()
    fireEvent.submit(form!)

    await waitFor(() => {
      expect(mutateAsyncMock).toHaveBeenCalledWith({
        email: 'user@example.com',
        password: 'password123'
      })
    })

    await waitFor(() => {
      expect(pushMock).toHaveBeenCalledTimes(1)
      const destination = (pushMock as Mock).mock.calls[0]?.[0] as string
      expect(destination).toContain('/login?')
      expect(destination).toContain('needsVerification=1')
      expect(destination).toContain('email=user%40example.com')
      expect(destination).toContain('userId=user-123')
      expect(destination).toContain('expiresAt=2024-12-31T00%3A00%3A00.000Z')
    })
  })
})

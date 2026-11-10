import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import * as registrations from '../api/registrations'
import { ApiError } from '../api/types'
import { RegisterPage } from './RegisterPage'

vi.mock('../config', () => ({ config: { apiBaseUrl: 'http://localhost:8000', useMock: true, appDownloadUrl: '' } }))

function renderPage() {
  return render(<MemoryRouter initialEntries={['/register']}><Routes>
    <Route path="/register" element={<RegisterPage />} />
    <Route path="/registered" element={<div>You're registered, Amina!</div>} />
  </Routes></MemoryRouter>)
}

function fillValid(matric = 'CHDC/0001') {
  fireEvent.change(screen.getByLabelText('First name'), { target: { value: 'Amina' } })
  fireEvent.change(screen.getByLabelText('Last name'), { target: { value: 'Bello' } })
  fireEvent.change(screen.getByLabelText('Matric number'), { target: { value: matric } })
  fireEvent.change(screen.getByLabelText('Phone number'), { target: { value: '08031234567' } })
}

describe('RegisterPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.spyOn(registrations, 'registerStudent').mockResolvedValue({
      first_name: 'Amina',
      last_name: 'Bello',
      matric_number: 'CHDC/0001',
      phone_number: '08031234567',
      created_at: new Date(0).toISOString(),
    })
  })
  it('shows required field errors without navigating', () => {
    renderPage()
    fireEvent.click(screen.getByRole('button', { name: 'Register' }))
    expect(screen.getAllByText('This field is required.')).toHaveLength(4)
    expect(screen.getByLabelText('Matric number')).toHaveAttribute('aria-invalid', 'true')
    expect(screen.getByLabelText('Phone number')).toHaveAttribute('aria-invalid', 'true')
    expect(screen.queryByText("You're registered, Amina!")).not.toBeInTheDocument()
  })
  it.each([
    ['Matric number', '12345678', 'Matric number must be exactly 9 characters.', 'matric_number-error'],
    ['Phone number', '0803123456', 'Phone number must be exactly 11 digits.', 'phone_number-error'],
  ])('shows a field-level length error for %s', async (label, value, message, errorId) => {
    renderPage()
    fillValid()
    fireEvent.change(screen.getByLabelText(label), { target: { value } })
    fireEvent.click(screen.getByRole('button', { name: 'Register' }))
    expect(await screen.findByText(message)).toBeInTheDocument()
    expect(screen.getByLabelText(label)).toHaveAttribute('aria-invalid', 'true')
    expect(screen.getByLabelText(label).getAttribute('aria-describedby')?.split(' ')).toContain(errorId)
    expect(screen.queryByText(/correct the highlighted/i)).not.toBeInTheDocument()
  })
  it('shows duplicate matric field error and alert', async () => {
    vi.spyOn(registrations, 'registerStudent').mockRejectedValueOnce(new ApiError(
      409, 'duplicate', 'Some details are already registered.',
      { matric_number: ['This matric number is already registered.'] },
    ))
    renderPage()
    fillValid('chdc/dup1')
    fireEvent.click(screen.getByRole('button', { name: 'Register' }))
    expect(await screen.findByText('This matric number is already registered.', {}, { timeout: 2000 })).toBeInTheDocument()
    expect(screen.getByLabelText('Matric number')).toHaveAttribute('aria-invalid', 'true')
    expect(screen.getByLabelText('Matric number')).toHaveAttribute('aria-describedby', 'matric_number-error')
    expect(screen.getByText('Some details are already registered.')).toBeInTheDocument()
  })
  it('shows backend phone errors on and highlights the phone field', async () => {
    vi.spyOn(registrations, 'registerStudent').mockRejectedValueOnce(new ApiError(
      409, 'duplicate', 'Some details are already registered.',
      { phone_number: ['This phone number is already registered.'] },
    ))
    renderPage()
    fillValid()
    fireEvent.change(screen.getByLabelText('Phone number'), { target: { value: '08000000001' } })
    fireEvent.click(screen.getByRole('button', { name: 'Register' }))
    expect(await screen.findByText('This phone number is already registered.')).toBeInTheDocument()
    expect(screen.getByLabelText('Phone number')).toHaveAttribute('aria-invalid', 'true')
    expect(screen.getByLabelText('Phone number')).toHaveAttribute('aria-describedby', 'phone_number-helper phone_number-error')
  })
  it('maps backend serializer errors to each matching form field', async () => {
    vi.spyOn(registrations, 'registerStudent').mockRejectedValueOnce(new ApiError(
      400,
      'validation_error',
      'Please correct the highlighted fields.',
      {
        first_name: ['Enter a valid first name.'],
        last_name: ['Enter a valid last name.'],
        matric_number: ['Matric number is already in use.'],
        phone_number: ['Phone number is already in use.'],
      },
    ))
    renderPage()
    fillValid()
    fireEvent.click(screen.getByRole('button', { name: 'Register' }))

    for (const [label, message] of [
      ['First name', 'Enter a valid first name.'],
      ['Last name', 'Enter a valid last name.'],
      ['Matric number', 'Matric number is already in use.'],
      ['Phone number', 'Phone number is already in use.'],
    ]) {
      expect(await screen.findByText(message)).toBeInTheDocument()
      expect(screen.getByLabelText(label)).toHaveAttribute('aria-invalid', 'true')
    }
    expect(screen.getByText('Please correct the highlighted fields.')).toBeInTheDocument()
  })
  it('shows the backend consent requirement after removing the checkbox', async () => {
    vi.spyOn(registrations, 'registerStudent').mockRejectedValueOnce(new ApiError(
      400,
      'validation_error',
      'Please accept the privacy consent to proceed.',
      { has_consented: ['You must accept the NDPR consent policy to proceed.'] },
    ))
    renderPage()
    fillValid()
    fireEvent.click(screen.getByRole('button', { name: 'Register' }))
    expect(await screen.findByText(/You must accept the NDPR consent policy to proceed/)).toBeInTheDocument()
  })
  it('clears corrected field errors and submits valid details', async () => {
    renderPage()
    fillValid('short')
    fireEvent.click(screen.getByRole('button', { name: 'Register' }))
    expect(await screen.findByText('Matric number must be exactly 9 characters.')).toBeInTheDocument()

    fireEvent.change(screen.getByLabelText('Matric number'), { target: { value: 'X12345678' } })
    expect(screen.getByLabelText('Matric number')).toHaveAttribute('aria-invalid', 'false')
    expect(screen.queryByText('Matric number must be exactly 9 characters.')).not.toBeInTheDocument()

    fireEvent.click(screen.getByRole('button', { name: 'Register' }))
    await waitFor(() => expect(screen.getByText("You're registered, Amina!")).toBeInTheDocument(), { timeout: 2000 })
  })
  it('navigates to confirmation after successful registration', async () => {
    renderPage()
    fillValid()
    fireEvent.click(screen.getByRole('button', { name: 'Register' }))
    await waitFor(() => expect(screen.getByText("You're registered, Amina!")).toBeInTheDocument(), { timeout: 2000 })
  })
  it('does not render a consent checkbox', () => {
    renderPage()
    expect(screen.queryByRole('checkbox')).not.toBeInTheDocument()
    expect(screen.queryByText(/I agree to the processing of my personal data/i)).not.toBeInTheDocument()
  })
})
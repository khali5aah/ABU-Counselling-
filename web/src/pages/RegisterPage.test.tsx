import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
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
  beforeEach(() => vi.clearAllMocks())
  it('shows required field errors without navigating', () => {
    renderPage()
    fireEvent.click(screen.getByRole('button', { name: 'Register' }))
    expect(screen.getAllByText('This field is required.')).toHaveLength(4)
    expect(screen.queryByText("You're registered, Amina!")).not.toBeInTheDocument()
  })
  it('shows duplicate matric field error and alert', async () => {
    renderPage()
    fillValid('chdc/dup')
    fireEvent.click(screen.getByRole('button', { name: 'Register' }))
    expect(await screen.findByText('This matric number is already registered.', {}, { timeout: 2000 })).toBeInTheDocument()
    expect(screen.getByText('Some details are already registered.')).toBeInTheDocument()
  })
  it('navigates to confirmation after successful registration', async () => {
    renderPage()
    fillValid()
    fireEvent.click(screen.getByRole('button', { name: 'Register' }))
    await waitFor(() => expect(screen.getByText("You're registered, Amina!")).toBeInTheDocument(), { timeout: 2000 })
  })
})
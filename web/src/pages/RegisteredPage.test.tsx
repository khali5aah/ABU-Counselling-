import { render, screen } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { describe, expect, it } from 'vitest'
import { RegisteredPage } from './RegisteredPage'

describe('RegisteredPage', () => {
  it('links to the app download route after registration', () => {
    render(
      <MemoryRouter initialEntries={[{
        pathname: '/registered',
        state: {
          first_name: 'Amina',
          last_name: 'Bello',
          matric_number: 'U25CO0001',
          phone_number: '08031234567',
          created_at: '2026-11-07T00:00:00Z',
          signup_code: '000042',
        },
      }]}>
        <Routes>
          <Route path="/registered" element={<RegisteredPage />} />
        </Routes>
      </MemoryRouter>,
    )

    expect(screen.getByRole('link', { name: /download app \(apk\)/i })).toHaveAttribute('href', '/download-app/')
    expect(screen.getByText('000042')).toBeInTheDocument()
    expect(screen.getByText(/expires 15 minutes after registration/i)).toBeInTheDocument()
  })
})

import { render, screen } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { DevOtpPanel } from './DevOtpPanel'
import { fetchDevOtpCodes } from '../api/devOtp'

vi.mock('../api/devOtp', () => ({ fetchDevOtpCodes: vi.fn() }))
const fetchMock = vi.mocked(fetchDevOtpCodes)

describe('DevOtpPanel', () => {
  beforeEach(() => vi.clearAllMocks())

  it('shows the latest code for the phone number', async () => {
    fetchMock.mockResolvedValue([{ phone_number: '+2348031234567', code: '357887',
      sent_at: '2026-10-22T08:28:23Z', expires_at: '2026-10-22T08:33:23Z' }])
    render(<DevOtpPanel phoneNumber="+2348031234567" />)
    expect(await screen.findByText('357887')).toBeInTheDocument()
    expect(fetchMock).toHaveBeenCalledWith('+2348031234567')
  })

  it('waits when no code has been sent yet', async () => {
    fetchMock.mockResolvedValue([])
    render(<DevOtpPanel phoneNumber="+2348031234567" />)
    expect(await screen.findByText(/Waiting for a code/)).toBeInTheDocument()
  })

  it('explains when the backend does not expose codes', async () => {
    fetchMock.mockRejectedValue(new Error('404'))
    render(<DevOtpPanel phoneNumber="+2348031234567" />)
    expect(await screen.findByText(/OTP_PROVIDER=console/)).toBeInTheDocument()
  })
})

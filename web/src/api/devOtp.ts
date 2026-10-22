import { request } from './http'

export interface DevOtpCode {
  phone_number: string
  code: string
  sent_at: string
  expires_at: string
}

// Development only: the backend answers 404 unless DJANGO_DEBUG=true and OTP_PROVIDER=console.
export async function fetchDevOtpCodes(phoneNumber: string): Promise<DevOtpCode[]> {
  const query = new URLSearchParams({ phone_number: phoneNumber })
  const response = await request<{ codes: DevOtpCode[] }>('GET', `/api/v1/dev/otp-codes/?${query}`)
  return response.codes
}

export const PHONE_ERROR = 'Phone number must be exactly 11 digits.'

export function normalizeLocalPhone(raw: string): string | null {
  const value = raw.replace(/\s/g, '')
  return /^[0-9]{11}$/.test(value) ? value : null
}

export function formatNgPhone(phone: string): string {
  return phone
}
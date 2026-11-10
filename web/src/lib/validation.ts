import type { RegistrationRequest } from '../api/types'
import { normalizeLocalPhone, PHONE_ERROR } from './phone'

export const REQUIRED = 'This field is required.'
export const MATRIC_ERROR = 'Matric number must be exactly 9 characters.'
export const NAME_ERROR = 'Enter a valid name (letters, spaces, apostrophes or hyphens; max 50).'

export function normalizeName(value: string): string {
  return value.trim().replace(/\s+/g, ' ')
}

export function normalizeMatric(value: string): string {
  return value.trim().toUpperCase()
}

export function validateRegistration(values: RegistrationRequest): Partial<Record<keyof RegistrationRequest, string | undefined>> {
  const firstName = normalizeName(values.first_name)
  const lastName = normalizeName(values.last_name)
  const matric = values.matric_number.trim()
  const phone = values.phone_number.trim()
  return {
    first_name: !firstName ? REQUIRED : /^[A-Za-z][A-Za-z' -]{0,49}$/.test(firstName) ? undefined : NAME_ERROR,
    last_name: !lastName ? REQUIRED : /^[A-Za-z][A-Za-z' -]{0,49}$/.test(lastName) ? undefined : NAME_ERROR,
    matric_number: !matric ? REQUIRED : matric.length === 9 ? undefined : MATRIC_ERROR,
    phone_number: !phone ? REQUIRED : normalizeLocalPhone(phone) ? undefined : PHONE_ERROR,
  }
}
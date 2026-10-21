import type { RegistrationRequest } from '../api/types'
import { normalizeNgPhone, PHONE_ERROR } from './phone'

export const REQUIRED = 'This field is required.'
export const MATRIC_ERROR = 'Matric number must be 3–30 characters using letters, digits, / or -.'
export const NAME_ERROR = 'Enter a valid name (letters, spaces, apostrophes or hyphens; max 50).'

export function normalizeName(value: string): string {
  return value.trim().replace(/\s+/g, ' ')
}

export function normalizeMatric(value: string): string {
  return value.trim().toUpperCase()
}

export function validateRegistration(values: RegistrationRequest): Record<keyof RegistrationRequest, string | undefined> {
  const firstName = normalizeName(values.first_name)
  const lastName = normalizeName(values.last_name)
  const matric = normalizeMatric(values.matric_number)
  const phone = values.phone_number.trim()
  return {
    first_name: !firstName ? REQUIRED : /^[A-Za-z][A-Za-z' -]{0,49}$/.test(firstName) ? undefined : NAME_ERROR,
    last_name: !lastName ? REQUIRED : /^[A-Za-z][A-Za-z' -]{0,49}$/.test(lastName) ? undefined : NAME_ERROR,
    matric_number: !matric ? REQUIRED : /^[A-Z0-9/-]{3,30}$/.test(matric) ? undefined : MATRIC_ERROR,
    phone_number: !phone ? REQUIRED : normalizeNgPhone(phone) ? undefined : PHONE_ERROR,
  }
}
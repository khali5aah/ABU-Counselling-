import { normalizeNgPhone } from '../lib/phone'
import { normalizeMatric, normalizeName, validateRegistration } from '../lib/validation'
import { ApiError, type RegistrationRequest, type RegistrationResponse } from './types'

const delay = (milliseconds: number) => new Promise((resolve) => window.setTimeout(resolve, milliseconds))

export async function registerStudentMock(req: RegistrationRequest): Promise<RegistrationResponse> {
  await delay(600)
  const errors = validateRegistration(req)
  const fields = Object.fromEntries(Object.entries(errors)
    .filter((entry): entry is [string, string] => Boolean(entry[1]))
    .map(([name, message]) => [name, [message]]))
  if (Object.keys(fields).length) {
    throw new ApiError(400, 'validation_error', 'Please correct the highlighted fields.', fields)
  }

  const phone = normalizeNgPhone(req.phone_number)!
  const matric = normalizeMatric(req.matric_number)
  if (matric === 'CHDC/DUP') {
    throw new ApiError(409, 'duplicate', 'Some details are already registered.', {
      matric_number: ['This matric number is already registered.'],
    })
  }
  if (phone === '+2348000000001') {
    throw new ApiError(409, 'duplicate', 'Some details are already registered.', {
      phone_number: ['This phone number is already registered.'],
    })
  }
  if (phone === '+2348000000500') {
    throw new ApiError(500, 'server_error', 'Something went wrong. Please try again.')
  }

  return {
    first_name: normalizeName(req.first_name),
    last_name: normalizeName(req.last_name),
    matric_number: matric,
    phone_number: phone,
    created_at: new Date().toISOString(),
  }
}
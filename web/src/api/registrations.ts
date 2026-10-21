import { config } from '../config'
import { registerStudentMock } from './mock'
import { request } from './http'
import type { RegistrationRequest, RegistrationResponse } from './types'

export function registerStudent(req: RegistrationRequest): Promise<RegistrationResponse> {
  const trimmed = {
    first_name: req.first_name.trim(),
    last_name: req.last_name.trim(),
    matric_number: req.matric_number.trim(),
    phone_number: req.phone_number.trim(),
  }
  return config.useMock ? registerStudentMock(trimmed) : request('POST', '/api/v1/registrations/', trimmed)
}
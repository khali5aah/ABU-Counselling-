import { afterEach, describe, expect, it, vi } from 'vitest'
import { registerStudentMock } from './mock'
import { ApiError } from './types'

const valid = { first_name: ' Amina ', last_name: 'Bello', matric_number: 'u25co0001', phone_number: '0803 123 4567' }

describe('registerStudentMock', () => {
  afterEach(() => vi.useRealTimers())
  it('resolves normalized registration values', async () => {
    vi.useFakeTimers()
    const pending = registerStudentMock(valid)
    await vi.advanceTimersByTimeAsync(600)
    await expect(pending).resolves.toMatchObject({ first_name: 'Amina', last_name: 'Bello', matric_number: 'U25CO0001', phone_number: '08031234567' })
  })
  it.each([
    [{ ...valid, matric_number: 'u25co9999' }, 409, 'duplicate', { matric_number: ['This matric number is already registered.'] }],
    [{ ...valid, phone_number: '08000000001' }, 409, 'duplicate', { phone_number: ['This phone number is already registered.'] }],
    [{ ...valid, phone_number: '08000000500' }, 500, 'server_error', {}],
    [{ ...valid, phone_number: 'bad' }, 400, 'validation_error', { phone_number: ['Phone number must be exactly 11 digits.'] }],
  ])('matches scenario %#', async (input, status, code, fields) => {
    vi.useFakeTimers()
    const pending = registerStudentMock(input as typeof valid).catch((error: unknown) => error)
    await vi.advanceTimersByTimeAsync(600)
    const error = await pending
    expect(error).toBeInstanceOf(ApiError)
    expect(error).toMatchObject({ status, code, fields })
  })
})
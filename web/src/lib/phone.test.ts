import { describe, expect, it } from 'vitest'
import { formatNgPhone, normalizeNgPhone } from './phone'

describe('normalizeNgPhone', () => {
  it.each(['08031234567', '0803 123 4567', '8031234567', '2348031234567', '+2348031234567'])(
    'normalizes %s', (input) => expect(normalizeNgPhone(input)).toBe('+2348031234567'),
  )
  it.each(['', '12345', '+2348031234', '+2346031234567', '08231234567', '+14155552671'])(
    'rejects %s', (input) => expect(normalizeNgPhone(input)).toBeNull(),
  )
  it('formats phone numbers', () => expect(formatNgPhone('+2348031234567')).toBe('+234 803 123 4567'))
})
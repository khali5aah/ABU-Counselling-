import { describe, expect, it } from 'vitest'
import { formatNgPhone, normalizeLocalPhone } from './phone'

describe('normalizeLocalPhone', () => {
  it.each([
    ['08031234567', '08031234567'],
    ['0803 123 4567', '08031234567'],
    [' 08031234567 ', '08031234567'],
    ['12345678901', '12345678901'],
  ])('accepts %s as an 11-digit local number', (input, expected) => {
    expect(normalizeLocalPhone(input)).toBe(expected)
  })
  it.each(['', '12345', '0803123456', '080312345678', '+2348031234', '0803 123 45a7'])(
    'rejects %s', (input) => expect(normalizeLocalPhone(input)).toBeNull(),
  )
  it('leaves local phone numbers unchanged for display', () => expect(formatNgPhone('08031234567')).toBe('08031234567'))
})
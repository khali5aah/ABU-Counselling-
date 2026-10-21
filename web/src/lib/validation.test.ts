import { describe, expect, it } from 'vitest'
import { MATRIC_ERROR, NAME_ERROR, REQUIRED, normalizeMatric, validateRegistration } from './validation'

const blank = { first_name: '', last_name: '', matric_number: '', phone_number: '' }

describe('validateRegistration', () => {
  it('returns exact required messages', () => {
    expect(Object.values(validateRegistration(blank))).toEqual([REQUIRED, REQUIRED, REQUIRED, REQUIRED])
  })
  it('normalizes and accepts matric numbers', () => {
    expect(normalizeMatric('chdc/0001')).toBe('CHDC/0001')
    expect(validateRegistration({ first_name: 'Amina', last_name: 'Bello', matric_number: 'chdc/0001', phone_number: '08031234567' }).matric_number).toBeUndefined()
  })
  it('uses exact invalid field messages', () => {
    const errors = validateRegistration({ first_name: '123', last_name: 'Bello', matric_number: 'x', phone_number: 'bad' })
    expect(errors.first_name).toBe(NAME_ERROR)
    expect(errors.matric_number).toBe(MATRIC_ERROR)
    expect(errors.phone_number).toBe('Enter a valid Nigerian mobile number, e.g. 08031234567.')
  })
})
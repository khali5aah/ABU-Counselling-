export const PHONE_ERROR = 'Enter a valid Nigerian mobile number, e.g. 08031234567.'

export function normalizeNgPhone(raw: string): string | null {
  let value = raw.replace(/[ \-().]/g, '')
  if (value.startsWith('+234')) {
    // Preserve an already internationalized number.
  } else if (value.startsWith('234')) {
    value = `+${value}`
  } else if (value.startsWith('0') && value.length === 11) {
    value = `+234${value.slice(1)}`
  } else if (/^\d{10}$/.test(value)) {
    value = `+234${value}`
  }
  return /^\+234[789][01]\d{8}$/.test(value) ? value : null
}

export function formatNgPhone(phone: string): string {
  const match = phone.match(/^\+234(\d{3})(\d{3})(\d{4})$/)
  return match ? `+234 ${match[1]} ${match[2]} ${match[3]}` : phone
}
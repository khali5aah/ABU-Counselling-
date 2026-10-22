import { useRef, useState, type FormEvent } from 'react'
import { useNavigate } from 'react-router-dom'
import { Alert } from '../components/Alert'
import { TextField } from '../components/TextField'
import { registerStudent } from '../api/registrations'
import { ApiError, type RegistrationRequest } from '../api/types'
import { validateRegistration } from '../lib/validation'

const initialValues: RegistrationRequest = {
  first_name: '',
  last_name: '',
  matric_number: '',
  phone_number: '',
}
const fieldOrder: Array<keyof RegistrationRequest> = ['first_name', 'last_name', 'matric_number', 'phone_number']

export function RegisterPage() {
  const [values, setValues] = useState(initialValues)
  const [errors, setErrors] = useState<Partial<Record<keyof RegistrationRequest, string>>>({})
  const [alert, setAlert] = useState<string>()
  const [pending, setPending] = useState(false)
  const busyRef = useRef(false)
  const navigate = useNavigate()

  function validateField(name: keyof RegistrationRequest, value: string) {
    const message = validateRegistration({ ...values, [name]: value })[name]
    setErrors((current) => ({ ...current, [name]: message }))
  }

  function updateField(name: keyof RegistrationRequest, value: string) {
    setValues((current) => ({ ...current, [name]: value }))
    setErrors((current) => ({ ...current, [name]: undefined }))
    setAlert(undefined)
  }

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (busyRef.current) return
    const nextErrors = validateRegistration(values)
    setErrors(nextErrors)
    const firstInvalid = fieldOrder.find((name) => nextErrors[name])
    if (firstInvalid) {
      document.getElementById(firstInvalid)?.focus()
      return
    }

    busyRef.current = true
    setPending(true)
    setAlert(undefined)
    try {
      const response = await registerStudent({
        first_name: values.first_name.trim(),
        last_name: values.last_name.trim(),
        matric_number: values.matric_number.trim(),
        phone_number: values.phone_number.trim(),
      })
      navigate('/registered', { state: response, replace: true })
    } catch (error) {
      if (!(error instanceof ApiError)) {
        setAlert('Something went wrong. Please try again.')
      } else if (error.code === 'validation_error' || error.code === 'duplicate') {
        const matched: Partial<Record<keyof RegistrationRequest, string>> = {}
        const extras: string[] = []
        for (const [name, messages] of Object.entries(error.fields)) {
          if (name === 'non_field_errors') continue
          if (fieldOrder.includes(name as keyof RegistrationRequest)) matched[name as keyof RegistrationRequest] = messages[0]
          else extras.push(...messages)
        }
        setErrors((current) => ({ ...current, ...matched }))
        setAlert([error.message, ...(error.fields.non_field_errors ?? []), ...extras].join(' '))
      } else if (error.code === 'rate_limited') {
        setAlert(error.retryAfter !== undefined
          ? `Too many attempts. Please try again in ${error.retryAfter} seconds.`
          : 'Too many attempts. Please try again shortly.')
      } else {
        setAlert(error.message)
      }
    } finally {
      busyRef.current = false
      setPending(false)
    }
  }

  return (
    <main className="page-shell">
      <section className="form-panel" aria-labelledby="page-title">
        <header className="brand-header">
          <div className="brand-mark" aria-hidden="true">C</div>
          <div>
            <p className="eyebrow">CHDC STUDENT PORTAL</p>
            <h1 id="page-title">CHDC E-Counselling</h1>
            <p className="subtitle">CHDC student registration</p>
          </div>
        </header>

        <div className="section-heading">
          <span className="section-index">01</span>
          <div><h2>Student details</h2><p>Register to continue in the CHDC E-Counselling mobile app.</p></div>
        </div>

        <form onSubmit={handleSubmit} noValidate>
          <div className="fields-grid">
            <TextField name="first_name" label="First name" autoComplete="given-name" value={values.first_name}
              onChange={(event) => updateField('first_name', event.target.value)}
              onBlur={(event) => validateField('first_name', event.target.value)} error={errors.first_name} />
            <TextField name="last_name" label="Last name" autoComplete="family-name" value={values.last_name}
              onChange={(event) => updateField('last_name', event.target.value)}
              onBlur={(event) => validateField('last_name', event.target.value)} error={errors.last_name} />
            <TextField name="matric_number" label="Matric number" placeholder="e.g. CHDC/0001" autoCapitalize="characters" value={values.matric_number}
              onChange={(event) => updateField('matric_number', event.target.value)}
              onBlur={(event) => validateField('matric_number', event.target.value)} error={errors.matric_number} />
            <TextField name="phone_number" label="Phone number" type="tel" inputMode="tel" autoComplete="tel"
              placeholder="e.g. 0803 123 4567" helper="You'll verify this number by SMS in the mobile app." value={values.phone_number}
              onChange={(event) => updateField('phone_number', event.target.value)}
              onBlur={(event) => validateField('phone_number', event.target.value)} error={errors.phone_number} />
          </div>
          {alert && <Alert type="error">{alert}</Alert>}
          <button className="button button-primary submit-button" type="submit" disabled={pending} aria-busy={pending}>
            {pending ? 'Registering…' : 'Register'}{!pending && <span aria-hidden="true">→</span>}
          </button>
          <p className="privacy-note"><span aria-hidden="true">●</span> Your details are used to verify your student account.</p>
        </form>
      </section>
      <aside className="side-note" aria-label="Registration information">
        <span className="side-note-rule" />
        <p>ONE PORTAL.<br />A BETTER PATH<br />TO WELLBEING.</p>
        <small>Student support starts with a secure registration.</small>
      </aside>
    </main>
  )
}
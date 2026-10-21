import type { InputHTMLAttributes } from 'react'

interface TextFieldProps extends InputHTMLAttributes<HTMLInputElement> {
  label: string
  helper?: string
  error?: string
}

export function TextField({ label, helper, error, id, ...inputProps }: TextFieldProps) {
  const inputId = id ?? inputProps.name
  const helperId = `${inputId}-helper`
  const errorId = `${inputId}-error`
  const describedBy = [helper ? helperId : undefined, error ? errorId : undefined].filter(Boolean).join(' ')
  return (
    <div className="field">
      <label htmlFor={inputId}>{label}</label>
      <input {...inputProps} id={inputId} aria-invalid={Boolean(error)} aria-describedby={describedBy || undefined} />
      {helper && <span className="field-helper" id={helperId}>{helper}</span>}
      {error && <span className="field-error" id={errorId} role="alert">{error}</span>}
    </div>
  )
}
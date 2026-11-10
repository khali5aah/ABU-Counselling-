import { Navigate, useLocation } from 'react-router-dom'
import { config } from '../config'
import { DevOtpPanel } from '../components/DevOtpPanel'
import { formatNgPhone } from '../lib/phone'
import type { RegistrationResponse } from '../api/types'

export function RegisteredPage() {
  const location = useLocation()
  const registration = location.state as RegistrationResponse | null
  if (!registration) return <Navigate to="/register" replace />

  const phone = formatNgPhone(registration.phone_number)
  return (
    <main className="page-shell confirmation-shell">
      <section className="form-panel confirmation-panel" aria-labelledby="page-title">
        <header className="brand-header compact-header">
          <div className="brand-mark" aria-hidden="true">C</div>
          <div><p className="eyebrow">CHDC STUDENT PORTAL</p><h1>CHDC E-Counselling</h1></div>
        </header>
        <div className="success-mark" aria-hidden="true">✓</div>
        <p className="eyebrow success-eyebrow">REGISTRATION COMPLETE</p>
        <h2 id="page-title">You're registered, {registration.first_name}!</h2>
        <p className="confirmation-intro">Your details are ready. Continue setup in the CHDC E-Counselling mobile app.</p>

        <dl className="summary-list">
          <div><dt>Name</dt><dd>{registration.first_name} {registration.last_name}</dd></div>
          <div><dt>Matric number</dt><dd>{registration.matric_number}</dd></div>
          <div><dt>Phone number</dt><dd>{phone}</dd></div>
        </dl>

        <section className="next-steps" aria-labelledby="steps-title">
          <div className="section-heading compact-section-heading">
            <span className="section-index">02</span>
            <div><h3 id="steps-title">Next steps</h3><p>Finish setup on your phone.</p></div>
          </div>
          <ol>
            <li>
              <a className="button button-primary download-button" href="/download-app/">Download App (APK) <span aria-hidden="true">↗</span></a>
            </li>
            <li><span>Open the app and tap “Set up my account”.</span></li>
            <li><span>Enter this phone number: <strong>{phone}</strong></span></li>
            <li>
              {registration.signup_code
                ? <span>Enter this 6-digit code in the app, then choose a username and password: <strong className="signup-code">{registration.signup_code}</strong></span>
                : <span>Enter the 6-digit SMS code, then choose a username and password.</span>}
            </li>
          </ol>
          {registration.signup_code && <p className="expiry-note">This code is one-time-use and expires 24 hours after registration. Save it before leaving this page.</p>}
          {!registration.signup_code && config.showDevOtp && !config.useMock && <DevOtpPanel phoneNumber={registration.phone_number} />}
          {!registration.signup_code && <p className="expiry-note">Keep this phone with you — the code expires in 5 minutes.</p>}
        </section>
      </section>
    </main>
  )
}
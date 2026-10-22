import { useEffect, useState } from 'react'
import { fetchDevOtpCodes, type DevOtpCode } from '../api/devOtp'

const POLL_MS = 3000

function formatTime(iso: string) {
  return new Date(iso).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' })
}

export function DevOtpPanel({ phoneNumber }: { phoneNumber: string }) {
  const [latest, setLatest] = useState<DevOtpCode | null>(null)
  const [unavailable, setUnavailable] = useState(false)

  useEffect(() => {
    let active = true
    async function poll() {
      try {
        const codes = await fetchDevOtpCodes(phoneNumber)
        if (active) { setLatest(codes[0] ?? null); setUnavailable(false) }
      } catch {
        if (active) setUnavailable(true)
      }
    }
    poll()
    const timer = window.setInterval(poll, POLL_MS)
    return () => { active = false; window.clearInterval(timer) }
  }, [phoneNumber])

  return (
    <section className="dev-otp" aria-live="polite" aria-label="Development verification code">
      <p className="dev-otp-label">Development only — verification code</p>
      {unavailable
        ? <p className="dev-otp-hint">Can't load codes. The backend must run with DJANGO_DEBUG=true and OTP_PROVIDER=console.</p>
        : latest
          ? <>
              <p className="dev-otp-code">{latest.code}</p>
              <p className="dev-otp-hint">Sent {formatTime(latest.sent_at)} · expires {formatTime(latest.expires_at)}</p>
            </>
          : <p className="dev-otp-hint">Waiting for a code… Request one in the mobile app.</p>}
    </section>
  )
}

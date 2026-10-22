# End-to-end acceptance script (live backend, mocks OFF)

Tester: ____________  Date: ____________  Backend URL: ____________  OTP provider: console / termii

## A. Web registration
- [ ] A1. Register Amina Bello, `chdc/0001`, `0803 123 4567` → confirmation page shows `CHDC/0001` and `+234 803 123 4567`.
- [ ] A2. Submit empty form → four "This field is required." messages, no request sent.
- [ ] A3. Phone `12345` → "Enter a valid Nigerian mobile number, e.g. 08031234567."
- [ ] A4. Same matric in lowercase with a new phone → 409, error under Matric number.
- [ ] A5. New matric with `+2348031234567` → 409, error under Phone number.
- [ ] A6. Register a second student (Musa Ali, `CHDC/0002`, `0812 345 6789`) for later tests.

## B. Mobile OTP
- [ ] B1. Set up → `08031234567` → generic message shown; one `[DEV OTP]` line (or SMS) received.
- [ ] B2. Wrong code → "The code is incorrect. 4 attempts left."
- [ ] B3. "Resend code" disabled with countdown for 60 s; after it, resend → new code; the OLD code is now rejected.
- [ ] B4. Unregistered `08099999999` → identical generic message; NO code in logs; any code → incorrect.
- [ ] B5. (Set `OTP_TTL_SECONDS=60` temporarily or wait 5 min) expired code → "This code has expired. Request a new one."
- [ ] B6. 5 wrong codes → "Too many incorrect attempts. Request a new code."

## C. Account setup
- [ ] C1. Correct code → Create account screen.
- [ ] C2. Password `12345678` → password error; the same screen still works afterwards.
- [ ] C3. Username `Amina_B` + strong password → Home shows "Welcome, Amina", `@amina_b`, the Sample banner and 3 sample cases.
- [ ] C4. Second student (Musa) verifies and tries username `amina_b` → "This username is taken."
- [ ] C5. Request OTP again for `08031234567` → generic message, NO code sent (one account per registration).

## D. Login / session
- [ ] D1. Log out → Welcome. Log in `AMINA_B` + password → Home (case-insensitive).
- [ ] D2. Wrong password → "Incorrect username or password."
- [ ] D3. Kill and reopen the app → goes straight to Home.
- [ ] D4. In /admin uncheck `is_active` for amina_b → login fails with the same message. Re-enable.

## E. Data and hygiene
- [ ] E1. /admin: `student_registrations` rows, `user_accounts` linked one-to-one, `phone_verifications` show no plaintext code.
- [ ] E2. `git ls-files | grep -E "(^|/)\.env$"` → empty. No real student data in the repo.
- [ ] E3. Fresh clone on another laptop following README → `/api/v1/health/` OK, web and mobile run.
- [ ] E4. CI green on main for backend, web and mobile workflows.
- [ ] E5. Tag: `git tag v0.1.0 && git push origin v0.1.0`.

## Known limitations to state in the demo
1. No password reset or phone-number change; a student who forgets their password cannot recover the account yet.
2. OTP runs in console mode unless Termii was configured and tested; console codes are visible in server logs.
3. Web registration reveals whether a matric or phone is already registered (409) — accepted for usability.
4. Demo hosting only: DEBUG on, cleartext HTTP on LAN (`usesCleartextTraffic`), ngrok URL — not production.
5. No eligibility check against an approved CHDC student list.
6. Home screen cases are synthetic placeholders.
7. After logout the access token stays valid until it expires (≤ 15 min); only the refresh token is revoked.
8. Rate limits are per IP; students behind one campus NAT share limits.

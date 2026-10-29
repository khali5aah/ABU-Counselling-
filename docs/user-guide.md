# Student user guide

This guide covers the current demo workflows. The case-management section is
prototype-only; do not enter real counselling details.

## Register on the web

1. Open the student registration portal and select **Register**.
2. Enter first name, last name, matric number, and a Nigerian mobile number.
3. Submit the form and review the confirmation page.
4. Keep the same phone number available for mobile account verification.

Phone numbers are normalized to `+234...`; matric numbers are trimmed and
uppercased. If a matric number or phone is already registered, the portal
shows a field-level duplicate error. A registration alone does not create a
mobile login account.

For a local portal, run `cd web && npm install && npm run dev`; open
`http://localhost:5173`. Mock mode is enabled by default and does not save
registrations. To exercise the live API, set `VITE_USE_MOCK=false` in
`web/.env.local` and start the backend.

## Set up the mobile account

1. Install and open CHDC E-Counselling.
2. Choose **Set up my account**.
3. Enter the phone number used for web registration and request a code.
4. Enter the received six-digit OTP.
5. Choose a username and password to create the account.
6. The app should open the signed-in area after account creation.

OTP requests deliberately use a generic response whether a number can
complete setup or not. In development with `OTP_PROVIDER=console`, the code
appears in backend logs as `[DEV OTP]`; in a configured SMS deployment, check
the phone's messages. Do not use console OTP delivery in production.

For local development, follow the [mobile setup](../mobile/README.md). Mock
mode accepts any valid Nigerian number and uses these fixed demo values:

| Scenario | Input |
|---|---|
| Successful OTP | `123456` |
| Expired OTP | `000000` |
| Attempt limit | `999999` |
| Incorrect OTP | Any other six digits |
| Successful login | `student1` / `Password123!` |
| Duplicate username | `taken_user` |

Mock data is not a real account and cannot authenticate with the live backend.

## Log in and out

Choose **I already have an account — Log in**, then enter the username and
password created during setup. Usernames are case-insensitive. Use the app's
logout action when finished; refresh credentials are stored in the device's
secure storage.

There is currently no password reset or phone-number change flow. If a
student loses access to the account, contact the system administrator rather
than attempting to create another account for the same registration.

## Counselling cases: demo only

The mobile app includes a cases tab and a form for selecting a category and
entering a description. These cases are held only in memory on that device;
they are not sent to the server, backed up, or made available to counselling
staff. They disappear when the app process is restarted.

The case detail screen currently displays a biometric-verification label, but
the feature is not a reliable security guarantee: unsupported device
authentication and some authentication errors allow access, and the label is
not tied to a verified result. Do not enter real personal, health, or
counselling information into this prototype.

## Help for testers

- API health: `GET /api/v1/health/`
- API documentation: `/api/v1/docs/`
- Common API errors and validation: [API contract](api-contract.md)
- Feature verification checklist: [acceptance tests](acceptance-test.md)
- Server troubleshooting: [deployment runbook](deployment-runbook.md)

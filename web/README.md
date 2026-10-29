# CHDC Student Registration web portal

This React + TypeScript + Vite app lets students submit their name, matric
number, and Nigerian phone number to the backend registration API. The
confirmation page can link to the mobile APK.

## Requirements

- Node.js 20+ and npm
- Django API at `http://localhost:8000` for live mode

## Run locally

```bash
cp .env.example .env.local
npm install
npm run dev
```

Vite serves the portal at `http://localhost:5173`. Mock mode is enabled in the
example configuration and simulates responses without saving anything.

To use the API, set the following values in `.env.local`:

```dotenv
VITE_USE_MOCK=false
VITE_API_BASE_URL=http://localhost:8000
```

Optional variables are `VITE_APP_DOWNLOAD_URL` (APK download URL) and
`VITE_SHOW_DEV_OTP` (development-only display for console OTP codes; keep
disabled outside local testing).

## Routes and data flow

- `/register` — registration form
- `/registered` — successful registration confirmation
- Other paths — not-found page
- Live requests use `POST /api/v1/registrations/`; the API contract defines
  normalization, validation, duplicate handling, and error responses.

The portal does not provide mobile account setup or counselling case
management. The case feature is a separate, local-only mobile prototype.

## Checks

```bash
npm test
npm run lint
npm run build
```

See the [user guide](../docs/user-guide.md),
[API contract](../docs/api-contract.md), and
[technical overview](../docs/technical-overview.md).

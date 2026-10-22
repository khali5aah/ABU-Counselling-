# Decision log — Milestone 1 (one-day build)

These decisions close the open items in docs/architecture.md. They are binding for all coding agents.

| # | Topic | Decision |
|---|---|---|
| D1 | Team | Backend split across two devs (A: foundation + registration; B: OTP + accounts + JWT). One web dev, one mobile dev. |
| D2 | Hosting for integration/demo | One laptop runs `docker compose up` (Postgres 16 + Django via gunicorn). Others reach it at `http://<LAN-IP>:8000`; fallback `ngrok http 8000` for an HTTPS URL. |
| D3 | OTP | Django generates a 6-digit code, stores only an HMAC hash, sends via a pluggable adapter. `OTP_PROVIDER=console` (default; code printed in backend logs; allowed only when `DJANGO_DEBUG=true`) or `OTP_PROVIDER=termii`. Termii's own token API is NOT used. |
| D4 | OTP limits | 6 digits, 5-minute expiry, 5 wrong attempts per code, 60 s resend cooldown per number, max 5 requests per number per hour, new code invalidates older ones. |
| D5 | Enumeration | OTP request always returns the same 200 body, registered or not. Web registration does reveal duplicates (409) — accepted for usability. |
| D6 | Setup proof | After OTP verify, server returns an opaque one-time `setup_token` (43 chars, stored as SHA-256 hash, 10-minute expiry). Consumed on successful account creation only. |
| D7 | Tokens | SimpleJWT. Access 15 min, refresh 7 days, rotation + blacklist. Logout blacklists the refresh token. `setup-account` and `login` both return tokens + user. |
| D8 | IDs | UUID primary keys for every model. |
| D9 | Phone | Nigeria only, stored as `+234XXXXXXXXXX`. Rules in api-contract.md §1.1. |
| D10 | Matric | Free format, uppercased, `^[A-Z0-9/-]{3,30}$`. Unique. |
| D11 | Username | Lowercased, `^[a-z][a-z0-9_]{2,29}$`. Unique. |
| D12 | Error format | Single envelope `{"error":{"code","message","fields"?}}` for all non-2xx. |
| D13 | Placeholder home | Hard-coded synthetic rows in Flutter labelled "Sample". No backend endpoint. |
| D14 | Account recovery | Out of scope. Known limitation: a student who forgets their password cannot recover the account in this milestone. |
| D15 | Mock modes | Web (`VITE_USE_MOCK=true`) and mobile (`--dart-define=USE_MOCK=true`) implement api-contract.md §4 exactly, so frontends never wait for the backend. |
| D16 | Download link | Web confirmation page links to `VITE_APP_DOWNLOAD_URL` (a shared-drive link to the release APK for the demo). |
| D17 | Cache | Django DatabaseCache (`createcachetable`) so throttles and cooldowns work across gunicorn workers. |
| D18 | Versions | Python 3.12, Django 5.2 LTS, DRF 3.16, SimpleJWT 5.5, Postgres 16, Node 20+, React + Vite + TypeScript, Flutter stable ≥ 3.24 / Dart ≥ 3.5. |

## File ownership (who may edit what)

| Path | Owner | Others |
|---|---|---|
| `docs/**` | Coordinator | PR only, never by agents |
| `docker-compose.yml`, `.gitignore`, `README.md`, `.github/pull_request_template.md`, `.github/workflows/backend.yml` | Backend Dev A | — |
| `backend/config/**`, `backend/apps/common/**`, `backend/requirements*.txt`, `backend/Dockerfile`, `backend/.env.example`, `backend/pytest.ini`, `backend/conftest.py` | Backend Dev A | Backend Dev B may only APPEND lines to `.env.example` and `requirements.txt` (append-only avoids merge conflicts) |
| `backend/apps/registrations/**` | Backend Dev A | — |
| `backend/apps/authentication/**` (except `migrations/0001_initial.py` and the `User` model, created by Prompt 0) | Backend Dev B | — |
| `web/**`, `.github/workflows/web.yml` | Web Dev | — |
| `mobile/**`, `.github/workflows/mobile.yml` | Mobile Dev | — |

## Environment variables (backend/.env.example)

```
DJANGO_SECRET_KEY=change-me-to-a-long-random-string
DJANGO_DEBUG=true
DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1,10.0.2.2,.ngrok-free.app
CORS_ALLOWED_ORIGINS=http://localhost:5173,http://127.0.0.1:5173
POSTGRES_DB=crownbird
POSTGRES_USER=crownbird
POSTGRES_PASSWORD=crownbird
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
JWT_ACCESS_MINUTES=15
JWT_REFRESH_DAYS=7
THROTTLE_REGISTRATION=60/hour
THROTTLE_OTP_REQUEST=30/hour
THROTTLE_OTP_VERIFY=60/hour
THROTTLE_SETUP=30/hour
THROTTLE_LOGIN=20/minute
OTP_PROVIDER=console
OTP_TTL_SECONDS=300
OTP_MAX_ATTEMPTS=5
OTP_RESEND_COOLDOWN_SECONDS=60
OTP_MAX_REQUESTS_PER_PHONE_PER_HOUR=5
SETUP_TOKEN_TTL_SECONDS=600
TERMII_API_KEY=
TERMII_SENDER_ID=
TERMII_BASE_URL=https://api.ng.termii.com
TERMII_CHANNEL=generic
```

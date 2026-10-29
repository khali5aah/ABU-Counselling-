# Technical overview

## System at a glance

```text
Student browser ── React/Vite ──┐
                                ├── Django REST API ── PostgreSQL
Student Flutter app ────────────┘
                                  └── OTP adapter: console or Termii
```

The repository is a monorepo. The API is the source of truth for web
registration, phone verification, account setup, and authentication. The
mobile counselling-case screens are a separate prototype and currently do not
call the API.

| Component | Implementation | Main paths |
|---|---|---|
| API | Python 3.12, Django 5.2, Django REST Framework, SimpleJWT | `backend/config/`, `backend/apps/` |
| Database | PostgreSQL 16; Django PostgreSQL backend | `backend/config/settings.py` |
| Web | React 19, TypeScript, Vite, React Router | `web/src/` |
| Mobile | Flutter / Dart, Provider, `http`, secure storage, `local_auth` | `mobile/lib/` |
| Local orchestration | Docker Compose: PostgreSQL and API | `docker-compose.yml` |
| Live web serving | Nginx reverse proxy; systemd Gunicorn service | Server configuration, not stored in this repository |

## Application responsibilities and flows

### Web registration

1. A student submits first name, last name, matric number, and phone number.
2. The web client validates and normalizes input for immediate feedback.
3. Live mode sends JSON to `POST /api/v1/registrations/`.
4. Django validates again, normalizes phone/matric values, checks uniqueness,
   and stores a `StudentRegistration`.
5. On success, the browser shows the confirmation page.

Mock mode is for UI development only; it does not persist data. See
`docs/api-contract.md` for exact validation and mock cases.

### Mobile account setup and authentication

1. A student first needs a registration created by the web portal.
2. The app requests an OTP for the registered phone number.
3. The server stores an OTP hash, expiration, and attempt counters. The code
   is sent by the configured provider (console for development or Termii).
4. Successful verification returns a short-lived, one-time setup token.
5. Account setup creates the username/password account and returns JWT access
   and refresh tokens.
6. The app stores tokens with secure storage, refreshes access tokens, and
   sends bearer authentication to protected API routes.

### Counselling cases (prototype)

`CaseController` creates cases in memory inside the Flutter app. No case model
or case endpoint exists on the backend. Cases do not survive an app restart,
and are not visible to counsellors or administrators. The biometric gate is
prototype behavior: unsupported authentication and an exception in the case
list handler both allow opening details; the detail screen's “Biometric
Verified” label is not an authoritative verification result. Treat this
feature as demonstration UI only, not as secure handling of counselling data.

## Backend layout and data

- `backend/config/settings.py`: Django, PostgreSQL, CORS, REST framework, JWT,
  throttling, OTP, and logging configuration.
- `backend/config/urls.py`: API URL registry, admin, health, schema, and docs.
- `backend/apps/registrations/`: public registration serializer, view, model,
  migration, admin, and seed command.
- `backend/apps/authentication/`: user and phone-verification models,
  serializers, OTP/account services, authentication views, and JWT handling.
- `backend/apps/common/`: shared phone normalization, API error handling, and
  health/error views.

Core records:

| Model | Purpose |
|---|---|
| `StudentRegistration` | Name, unique matric number, normalized unique phone |
| `User` | UUID user account linked one-to-one to a registration |
| `PhoneVerification` | OTP hash, expiration/attempt state, and hashed one-time setup token |

The active Django database engine is PostgreSQL. Django uses the `DB_*`
variables listed below. `POSTGRES_*` variables configure the PostgreSQL
container itself; they are not read by Django settings.

## API conventions

- Base path: `/api/v1/`; retain trailing slashes.
- JSON requests/responses; field names use `snake_case`.
- Protected routes use `Authorization: Bearer <access-token>`.
- Access tokens last 15 minutes; refresh tokens last 7 days and rotate.
- API errors use a consistent `error.code`, `error.message`, and optional
  `error.fields` structure.
- Clients also send `ngrok-skip-browser-warning: true` for ngrok demos.

Endpoints, schemas, payloads, status codes, and shared mock cases are
maintained in [the API contract](api-contract.md). A live development server
also serves Swagger UI at `/api/v1/docs/` and OpenAPI YAML at
`/api/v1/schema/`.

## Configuration reference

Keep actual `.env` files out of version control. `backend/.env.example` is a
development template; generate a unique secret and set production values
outside source control.

| Variable | Consumer | Purpose |
|---|---|---|
| `DJANGO_SECRET_KEY` | Django | Required signing/cryptographic secret |
| `DJANGO_DEBUG` | Django | Debug mode; must be false in production |
| `DJANGO_ALLOWED_HOSTS` | Django | Comma-separated accepted HTTP hostnames |
| `DB_NAME`, `DB_USER`, `DB_PASSWORD` | Django | PostgreSQL database and login |
| `DB_HOST`, `DB_PORT` | Django | PostgreSQL endpoint; Compose overrides host to `db` |
| `CORS_ALLOWED_ORIGINS` | Django | Exact comma-separated browser origins, including scheme and port |
| `OTP_PROVIDER` | Django | `console` for development or `termii` for SMS |
| `OTP_TTL_SECONDS`, `OTP_MAX_ATTEMPTS`, `OTP_RESEND_COOLDOWN_SECONDS`, `OTP_MAX_REQUESTS_PER_PHONE_PER_HOUR`, `SETUP_TOKEN_TTL_SECONDS` | Django | OTP/setup security and expiry limits |
| `TERMII_API_KEY`, `TERMII_SENDER_ID`, `TERMII_BASE_URL`, `TERMII_CHANNEL` | Django | Termii SMS configuration |
| `JWT_ACCESS_MINUTES`, `JWT_REFRESH_DAYS` | Django | JWT lifetimes |
| `THROTTLE_REGISTRATION`, `THROTTLE_OTP_REQUEST`, `THROTTLE_OTP_VERIFY`, `THROTTLE_SETUP`, `THROTTLE_LOGIN` | Django | DRF endpoint rate limits |
| `VITE_API_BASE_URL` | Web build | API origin, e.g. `http://localhost:8000` |
| `VITE_USE_MOCK` | Web build | Use simulated responses when `true` |
| `VITE_APP_DOWNLOAD_URL` | Web build | Optional APK download link |
| `VITE_SHOW_DEV_OTP` | Web build | Development-only console OTP display |
| `USE_MOCK` | Flutter build | Select simulated API (`true`, default) or backend (`false`) |
| `API_BASE_URL` | Flutter build | API origin plus `/api/v1/`, e.g. `http://10.0.2.2:8000/api/v1/` |
| `WEB_REGISTRATION_URL` | Flutter build | Optional registration web URL compiled into the app |

The local Compose database uses `POSTGRES_DB`, `POSTGRES_USER`, and
`POSTGRES_PASSWORD` to initialize its container. These development values
must be changed for any non-demo deployment.

## Security and release constraints

- Never commit `.env`, passwords, signing keys, OTPs, or real student data.
- Do not use `DJANGO_DEBUG=true` on a public server. It can expose internal
  details in error pages.
- Do not use the development database password, Django secret, or console OTP
  provider in production.
- Set exact production `DJANGO_ALLOWED_HOSTS` and
  `CORS_ALLOWED_ORIGINS`; avoid wildcard origins.
- Use HTTPS for public clients, and keep database/network access restricted.
- Keep the OTP-code debug endpoint disabled in public environments.
- Counselling cases are not production-ready; implement server persistence,
  authorization, auditing, and reviewed biometric UX before accepting
  sensitive case details.

## Tests and checks

```bash
# Backend
cd backend && pytest

# Web
cd web && npm test && npm run lint && npm run build

# Mobile
cd mobile && flutter analyze && flutter test
```

See also [the decision log](decisions.md) and
[the deployment runbook](deployment-runbook.md).

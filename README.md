# CHDC E-Counselling

CHDC E-Counselling is a student counselling platform with a Django REST API,
a React registration portal, and a Flutter mobile app. The API and web
registration flow are backed by PostgreSQL. The mobile counselling-case flow
is currently a local prototype; it does not persist cases to the backend.

## Repository map

| Path | Purpose |
|---|---|
| `backend/` | Django REST API, PostgreSQL models, authentication, OTP, admin |
| `web/` | React + TypeScript student registration portal |
| `mobile/` | Flutter student app for account setup, login, and prototype cases |
| `docs/api-contract.md` | Versioned API endpoints, payloads, errors, and mock scenarios |
| `docs/technical-overview.md` | System architecture, data model, configuration, and limitations |
| `docs/user-guide.md` | How students use the web portal and mobile app |
| `docs/deployment-runbook.md` | Local setup, systemd/Nginx operations, migrations, and checks |
| `docs/integration-runbook.md` | Team integration and demo workflow |

## Local development

### Backend

Prerequisites: Docker Compose, or Python 3.12 and PostgreSQL 16.

For Docker Compose:

```bash
cp backend/.env.example backend/.env
```

Replace `DJANGO_SECRET_KEY` with a generated secret before running. The example
uses development-only database credentials and debug settings; do not use
them for a public deployment.

```bash
docker compose up --build -d
docker compose exec api python manage.py createsuperuser
```

The API is at `http://localhost:8000`; health check:
`http://localhost:8000/api/v1/health/`. OpenAPI documentation is at
`http://localhost:8000/api/v1/docs/`.

To run the backend directly on the host, start only PostgreSQL with
`docker compose up -d db`, create the environment file as above, and then:

```bash
cd backend
python3.12 -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt
python manage.py migrate
python manage.py createcachetable
python manage.py runserver 127.0.0.1:8000
```

Run backend tests from `backend/` with `pytest`.

### Web portal

Prerequisites: Node.js 20+ and npm.

```bash
cd web
cp .env.example .env.local
npm install
npm run dev
```

The development server is normally at `http://localhost:5173`. Mock mode is
the default. For the live local API, set `VITE_USE_MOCK=false` and
`VITE_API_BASE_URL=http://localhost:8000` in `.env.local`.

### Mobile app

Prerequisites: Flutter stable 3.24+ / Dart 3.5+, plus an Android SDK or
macOS/Xcode for iOS.

```bash
cd mobile
flutter pub get
flutter run --dart-define=USE_MOCK=true
```

For an Android emulator talking to the API on the host computer:

```bash
flutter run \
  --dart-define=USE_MOCK=false \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1/
```

For a physical device, replace `10.0.2.2` with the backend host's reachable
LAN address. The API base URL includes `/api/v1/`. See
[the user guide](docs/user-guide.md) for student flows and important prototype
limitations.

## API and checks

All API paths are versioned below `/api/v1/` and use trailing slashes.
See the [API contract](docs/api-contract.md) before changing request/response
behavior.

```bash
# Web
cd web && npm test && npm run lint && npm run build

# Mobile
cd mobile && flutter analyze && flutter test

# Backend
cd backend && pytest
```

More complete setup and operations documentation is indexed above in
`docs/technical-overview.md` and `docs/deployment-runbook.md`.

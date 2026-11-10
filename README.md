# CHDC E-Counselling

CHDC E-Counselling monorepo for the counselling platform backend, web app, and mobile app.

## Repository structure

- backend/
- web/
- mobile/
- docs/

## Backend quick start

```bash
cp backend/.env.example backend/.env
docker compose up --build
```

API: http://localhost:8000
Docs: http://localhost:8000/api/v1/docs/

Create an admin user:

```bash
docker compose exec api python manage.py createsuperuser
```

Local development without Docker:

```bash
docker compose up db
cd backend
python3.12 -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt
python manage.py migrate
python manage.py createcachetable
python manage.py runserver 0.0.0.0:8000
pytest
```

To see console OTP codes as they are sent (Windows PowerShell):

```powershell
powershell -ExecutionPolicy Bypass -File scripts\otp.ps1
```

On macOS/Linux:

```bash
docker compose logs -f api | grep "DEV OTP"
```

## Web

See web/README.md

## Mobile

See mobile/README.md

## Backend: registration

Endpoint:

- POST /api/v1/registrations/

Example request:

```bash
curl -s -X POST http://localhost:8000/api/v1/registrations/ \
  -H "Content-Type: application/json" \
  -d '{"first_name":"Amina","last_name":"Bello","matric_number":"chdc/0001","phone_number":"08031234567"}'
```

Seed command:

```bash
python manage.py seed_registration --first-name Demo --last-name Student --matric CHDC/DEMO1 --phone 08031234567
```

## Contracts and decisions

- [docs/api-contract.md](docs/api-contract.md)
- [docs/decisions.md](docs/decisions.md)

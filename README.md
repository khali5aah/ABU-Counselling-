# Crownbird E-Counselling

Crownbird E-Counselling monorepo for the counselling platform backend, web app, and mobile app.

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

To inspect console OTP codes:

```bash
docker compose logs -f api | grep "DEV OTP"
```

## Web

See web/README.md

## Mobile

See mobile/README.md

## Contracts and decisions

- [docs/api-contract.md](docs/api-contract.md)
- [docs/decisions.md](docs/decisions.md)

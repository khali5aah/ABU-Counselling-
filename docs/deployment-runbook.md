# Deployment and operations runbook

This runbook documents the repository's Docker development deployment and
the current systemd/Nginx deployment shape. Adapt usernames, paths, hostnames,
and secrets to the target server. Never copy a live secret into this file or
Git.

## Local Docker deployment

1. Install Docker Engine and the Docker Compose plugin.
2. Create the backend environment file:

   ```bash
   cp backend/.env.example backend/.env
   ```

3. Replace `DJANGO_SECRET_KEY` with a strong random value. Set
   `DJANGO_ALLOWED_HOSTS` and `CORS_ALLOWED_ORIGINS` for the local clients.
4. Start the API and PostgreSQL:

   ```bash
   docker compose up --build -d
   docker compose ps
   docker compose logs -f api
   ```

5. Create an administrator if required:

   ```bash
   docker compose exec api python manage.py createsuperuser
   ```

Compose initializes PostgreSQL using `POSTGRES_*` variables on the database
container and overrides Django's `DB_HOST` to `db`. Do not confuse these two
variable groups. The API container runs migrations and creates the Django
database cache table at startup.

Health and docs:

```bash
curl -i http://127.0.0.1:8000/api/v1/health/
```

Expected response: HTTP 200 and `{"status":"ok"}`.

## systemd Gunicorn and Nginx deployment

The current deployment shape is:

- systemd `gunicorn.service` runs the backend from
  `/var/www/abu_v2/backend`.
- Gunicorn binds to `127.0.0.1:8000`.
- Nginx proxies web/API traffic to that loopback address.
- `gunicorn.socket` is disabled to avoid competing socket activation.

Use an environment file readable by the Gunicorn service account, but not
world-readable. The deployed service currently uses `root:www-data` ownership
and mode `640`; preserve the needed service-group access when changing users.
The repository `.gitignore` excludes `.env`, `venv/`, and `staticfiles/`.

Before switching a deployment to this service configuration, verify the
source contains the correct database credentials and the required Django
settings. Do not use a placeholder secret or assume a database password can
be recovered from PostgreSQL; obtain it from the approved secret store or
rotate it through an approved process.

Typical service unit shape (adjust the service account and paths):

```ini
[Unit]
Description=gunicorn daemon
After=network.target

[Service]
User=apex
Group=www-data
WorkingDirectory=/var/www/abu_v2/backend
EnvironmentFile=/var/www/abu_v2/backend/.env
ExecStart=/var/www/abu_v2/backend/venv/bin/gunicorn --workers 3 --bind 127.0.0.1:8000 config.wsgi:application
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

After updating a unit or installing a new release:

```bash
sudo systemctl stop gunicorn.socket
sudo systemctl disable gunicorn.socket
sudo systemctl daemon-reload
cd /var/www/abu_v2/backend
venv/bin/python manage.py check --deploy
venv/bin/python manage.py showmigrations
venv/bin/python manage.py migrate
sudo systemctl restart gunicorn
sudo systemctl status gunicorn --no-pager
```

For static assets, run `venv/bin/python manage.py collectstatic --noinput`
when the deployment serves Django static files. Review Nginx configuration
and reload only after `sudo nginx -t` succeeds.

## Verification commands

```bash
# Django through Gunicorn
curl -i http://127.0.0.1:8000/api/v1/health/

# Through Nginx (supply the expected Host header for a named virtual host)
curl -i -H 'Host: <configured-host>' http://127.0.0.1/api/v1/health/

# Route and migration state
cd /var/www/abu_v2/backend
venv/bin/python manage.py showmigrations

# Service and logs
sudo systemctl status gunicorn --no-pager
sudo journalctl -u gunicorn -n 100 --no-pager
sudo tail -n 50 /var/log/nginx/error.log
```

Do not use `/api/` as a health check: it is not a defined route. The health
endpoint is `/api/v1/health/`. To test registration routing without creating
data, POST `{}` to `/api/v1/registrations/`; a healthy application should
return a validation response (400), not a 500. A full valid POST creates a
real registration and should only be used with approved test data.

## Troubleshooting

| Symptom | Likely cause | Check |
|---|---|---|
| Gunicorn fails at start | Missing env file, unreadable file, invalid settings, or missing venv executable | `systemctl status gunicorn`; `journalctl -u gunicorn -n 100 --no-pager` |
| Database password authentication fails | `DB_*` credentials do not match the PostgreSQL role/database | Check variable names and approved secret source; test via Django; never print passwords |
| `showmigrations` cannot connect | Wrong DB host/port, unavailable PostgreSQL, or authentication failure | `systemctl status postgresql`; `pg_lsclusters`; inspect sanitized application logs |
| Nginx returns 502 | Gunicorn not listening or proxy target/socket mismatch | Compare `ss -ltn` with Nginx `proxy_pass`, then check Gunicorn |
| Nginx reaches a stale Unix socket | Old proxy config still points at `/run/gunicorn.sock` | Update to the selected upstream and validate with `nginx -t` |
| API returns 404 at `/api/` | Root API route is not defined | Use `/api/v1/health/`, `/api/v1/registrations/`, or another documented endpoint |
| API returns host 400 | Request hostname missing from `DJANGO_ALLOWED_HOSTS` | Add only expected hostnames |
| Browser reports CORS failure | Origin missing from `CORS_ALLOWED_ORIGINS` | Add exact scheme/host/port; do not set wildcard for production |

## Production checklist

- Set `DJANGO_DEBUG=false`, a unique Django secret, valid database credentials,
  exact host allowlists, and HTTPS.
- Configure and verify the production SMS provider; do not run console OTP
  publicly.
- Restrict database access to the backend and use least-privilege database
  roles.
- Back up PostgreSQL and test restore procedures before migrations.
- Keep `.env`, credentials, OTPs, student records, and backups out of Git and
  public logs.
- Do not accept sensitive counselling data until the mobile case flow is
  server-backed, access-controlled, persisted safely, and reviewed.

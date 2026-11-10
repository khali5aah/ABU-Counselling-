# Integration runbook (14:30 onwards)

## 1. Merge order
1. Prompt 0 (`chore/bootstrap`) — first, before anything else in backend/.
2. B1 and B2 in either order. The second one runs `git pull --rebase origin main`, then `pytest` again before merging.
3. Web and Mobile PRs (they touch only their own folders, so they never conflict with backend).
After every merge, everyone runs `git pull --rebase origin main` on their branch.

## 2. Host the backend (Backend Dev A's laptop)
1. `git switch main && git pull`
2. `cp backend/.env.example backend/.env`, then edit:
   - `DJANGO_SECRET_KEY` = output of `python -c "import secrets; print(secrets.token_urlsafe(50))"`
   - Find the LAN IP: Windows `ipconfig` (IPv4 Address) · macOS `ipconfig getifaddr en0` · Linux `hostname -I`
   - `DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1,10.0.2.2,.ngrok-free.app,<LAN-IP>`
   - `CORS_ALLOWED_ORIGINS=http://localhost:5173,http://127.0.0.1:5173` (add `http://<web-dev-LAN-IP>:5173` only if the web app is opened from another device)
3. `docker compose up -d --build` then `docker compose exec api python manage.py createsuperuser`
4. Keep a terminal on `docker compose logs -f api` — console OTP codes appear as `[DEV OTP] phone=... code=...`.
5. From ANOTHER laptop: `curl http://<LAN-IP>:8000/api/v1/health/` → `{"status":"ok"}`. From the phone's browser open the same URL. If either fails, see Troubleshooting.
6. Network: all devices on the same Wi-Fi. A phone hotspot is the most reliable. Campus/guest Wi-Fi often blocks device-to-device traffic → use ngrok (step 3).
7. After ANY change to backend/.env: `docker compose up -d --force-recreate api`.

## 3. ngrok fallback (HTTPS, works across networks)
1. Install ngrok, `ngrok config add-authtoken <token>`, then `ngrok http 8000`.
2. Use the `https://xxxx.ngrok-free.app` URL as API base URL in web and mobile (`.ngrok-free.app` is already in ALLOWED_HOSTS; both clients already send `ngrok-skip-browser-warning`).
3. Keep ngrok running for the whole demo — the free URL changes on restart, and the APK has the URL baked in (you would have to rebuild it).

## 4. Switch the web app to live
`web/.env.local`: `VITE_USE_MOCK=false`, `VITE_API_BASE_URL=http://<LAN-IP>:8000` (or the ngrok URL), `VITE_APP_DOWNLOAD_URL=<shared-drive link to APK>`. Restart `npm run dev`. Register one student and confirm it appears in `/admin/`.

## 5. Switch the mobile app to live
1. Emulator: `flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=http://10.0.2.2:8000` (only if the backend is on the same machine).
2. Real phone: `flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=http://<LAN-IP>:8000`.
3. Demo APK: `flutter build apk --release --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=<url> --dart-define=WEB_REGISTRATION_URL=<web url>`; upload `build/app/outputs/flutter-apk/app-release.apk` to a shared drive; put that link in `VITE_APP_DOWNLOAD_URL`.

## 6. Turn on real SMS (Termii) — only if the key and sender ID are approved
1. Test the key first (from any laptop):
   `curl -X POST "<TERMII_BASE_URL>/api/sms/send" -H "Content-Type: application/json" -d '{"api_key":"<key>","to":"234803XXXXXXX","from":"<sender_id>","sms":"CHDC test","type":"plain","channel":"generic"}'`
   Expect JSON containing `message_id`, and the SMS on the phone. If numbers on DND do not receive it, retry with `"channel":"dnd"`. Use the base URL shown in your Termii dashboard.
2. In backend/.env: `OTP_PROVIDER=termii`, `TERMII_API_KEY`, `TERMII_SENDER_ID`, `TERMII_BASE_URL`, `TERMII_CHANNEL`. Recreate the api container.
3. If delivery is unreliable on the day, switch back to `OTP_PROVIDER=console` and record it as a known limitation.

## 7. Troubleshooting
| Symptom | Likely cause | Fix |
|---|---|---|
| App shows "Can't reach the server" | Wrong IP, firewall, different Wi-Fi, release APK without INTERNET permission | Open `/api/v1/health/` in the phone browser; allow TCP 8000 in the host firewall; use hotspot or ngrok |
| HTML "Bad Request (400)" | Host not in `DJANGO_ALLOWED_HOSTS` | Add the IP/host, recreate api |
| Browser console shows a CORS error | Web origin not in `CORS_ALLOWED_ORIGINS` | Add exact origin (scheme + host + port), recreate api |
| 404 or 301 on an API call | Missing trailing slash | Paths must end with `/` |
| No OTP code anywhere | Console mode prints to logs; only registered numbers WITHOUT an account get codes | `docker compose logs api \| grep "DEV OTP"` |
| 429 while testing | Cooldown / throttles | Wait `retry_after` seconds or raise THROTTLE_* in .env temporarily |
| `ImproperlyConfigured: Console OTP provider...` | `DJANGO_DEBUG=false` with console OTP | Set `DJANGO_DEBUG=true` or configure Termii |
| Two `0002_*.py` migrations in authentication | Someone ran makemigrations outside their app | Only B2 owns authentication migrations — delete the stray one, regenerate |
| ngrok HTML warning page instead of JSON | Client didn't send `ngrok-skip-browser-warning` | Fix the client header |

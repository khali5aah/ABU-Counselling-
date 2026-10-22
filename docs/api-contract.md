# CHDC E-Counselling — API Contract v1 (FROZEN)

Status: FROZEN for Milestone 1. This file is the single source of truth for backend, web and mobile.
Any change requires a pull request that edits this file FIRST, approved by one backend dev and one frontend dev.
Coding agents: if your code disagrees with this file, your code is wrong.

## 0. Global conventions

| Item | Rule |
|---|---|
| Base path | `/api/v1/` — every path below is relative to `{API_BASE_URL}` and starts with `/api/v1/` |
| Trailing slash | Every path ends with `/` exactly as written. Requests without it are a bug. |
| Format | JSON only. Request header `Content-Type: application/json`. Responses are `application/json` (except 204). |
| Field naming | `snake_case` everywhere, in requests and responses. |
| IDs | UUID v4 strings. |
| Timestamps | ISO 8601 UTC with `Z`, e.g. `2026-10-21T09:30:00Z`. |
| Auth | `Authorization: Bearer <access_token>` on protected endpoints. No cookies, no sessions, no CSRF. |
| Extra header | Clients send `ngrok-skip-browser-warning: true` on EVERY request (harmless locally, required behind ngrok free tier). |
| Access token lifetime | 15 minutes |
| Refresh token lifetime | 7 days, rotated on every refresh; the old refresh token is blacklisted. |

## 1. Input normalization rules (server is authoritative; clients mirror them for instant feedback)

### 1.1 Phone number (Nigeria only)
1. Remove spaces, `-`, `(`, `)` and `.`.
2. If it starts with `+234` → keep. Else if it starts with `234` → prefix `+`. Else if it starts with `0` and has 11 digits → replace the leading `0` with `+234`. Else if it has exactly 10 digits → prefix `+234`.
3. The result MUST match `^\+234[789][01]\d{8}$`. Otherwise invalid.
4. Stored and returned format: `+234XXXXXXXXXX` (14 characters).
Examples: `08031234567`, `0803 123 4567`, `8031234567`, `2348031234567`, `+2348031234567` → `+2348031234567`.
Invalid message (exact): `Enter a valid Nigerian mobile number, e.g. 08031234567.`

### 1.2 Matric number
Trim, convert to UPPERCASE. Must match `^[A-Z0-9/-]{3,30}$`.
Invalid message: `Matric number must be 3–30 characters using letters, digits, / or -.`

### 1.3 First name / last name
Trim, collapse internal runs of spaces to one space. Must match `^[A-Za-z][A-Za-z' -]{0,49}$` (1–50 chars).
Invalid message: `Enter a valid name (letters, spaces, apostrophes or hyphens; max 50).`

### 1.4 Username
Trim, convert to lowercase. Must match `^[a-z][a-z0-9_]{2,29}$` (3–30 chars, starts with a letter). Unique (case-insensitive because it is stored lowercase).
Invalid message: `Username must be 3–30 characters: lowercase letters, digits or underscore, starting with a letter.`

### 1.5 Password
Minimum 8 characters, not entirely numeric, not a common password, not too similar to the username (Django validators). Client mirrors only: length ≥ 8 and not all digits. Passwords are NOT required to be unique.

## 2. Error envelope (every non-2xx response)

```json
{
  "error": {
    "code": "validation_error",
    "message": "Please correct the highlighted fields.",
    "fields": {
      "phone_number": ["Enter a valid Nigerian mobile number, e.g. 08031234567."]
    }
  }
}
```

- `code` (string, always present) — clients branch on this, never on `message`.
- `message` (string, always present) — safe to show to the user.
- `fields` (object, optional) — field name → list of strings. Non-field problems use the key `non_field_errors`.
- Extra keys appear only where listed below: `retry_after` (int seconds, with `rate_limited`), `attempts_remaining` (int, with `invalid_otp`).

| HTTP | `code` | When |
|---|---|---|
| 400 | `validation_error` | Missing/invalid fields or malformed JSON |
| 400 | `invalid_otp` | Wrong code, or unknown/consumed `request_id` |
| 400 | `otp_expired` | Code older than 5 minutes |
| 400 | `otp_attempts_exceeded` | 5 wrong attempts on this `request_id` |
| 400 | `setup_token_invalid` | Setup token missing, unknown, expired, already used, or the registration already has an account |
| 401 | `invalid_credentials` | Wrong username/password OR inactive account (same response for both) |
| 401 | `not_authenticated` | No `Authorization` header on a protected endpoint |
| 401 | `token_invalid` | Access or refresh token invalid, expired or blacklisted |
| 403 | `permission_denied` | Authenticated but not allowed |
| 404 | `not_found` | Unknown URL or object |
| 405 | `method_not_allowed` | Wrong HTTP method |
| 409 | `duplicate` | Unique value already taken (`fields` names which) |
| 429 | `rate_limited` | Throttle or resend cooldown hit (`retry_after` present) |
| 500 | `server_error` | Unhandled error. Message: `Something went wrong. Please try again.` |

Client-only synthetic code (never sent by server): `network_error` — request failed to reach the server or timed out (15 s). Message: `Can't reach the server. Check your connection and try again.`

## 3. Endpoints

### 3.1 GET /api/v1/health/ — public
200 → `{"status": "ok"}`

### 3.2 POST /api/v1/registrations/ — public (web)
Request:
```json
{"first_name": "Amina", "last_name": "Bello", "matric_number": "chdc/0001", "phone_number": "0803 123 4567"}
```
201 Created:
```json
{"first_name": "Amina", "last_name": "Bello", "matric_number": "CHDC/0001", "phone_number": "+2348031234567", "created_at": "2026-10-21T09:30:00Z"}
```
400 `validation_error` (any field). 409 `duplicate`, one or both of:
```json
{"error": {"code": "duplicate", "message": "Some details are already registered.", "fields": {"matric_number": ["This matric number is already registered."], "phone_number": ["This phone number is already registered."]}}}
```
429 `rate_limited`.

### 3.3 POST /api/v1/auth/otp/request/ — public (mobile)
Request: `{"phone_number": "08031234567"}`
200 OK — IDENTICAL shape whether or not the number is registered or already has an account (anti-enumeration):
```json
{"request_id": "6f1c2a7e-3b9d-4c51-a0e2-9f7d1e2b3c4d", "message": "If this number is registered and not yet set up, a verification code has been sent by SMS.", "expires_in": 300, "resend_after": 60}
```
400 `validation_error` (bad phone format only). 429 `rate_limited` with `retry_after` — applies to every number equally (60 s cooldown per number; max 5 requests per number per hour; per-IP throttle).
Requesting a new code invalidates all earlier unused codes for that registration.

### 3.4 POST /api/v1/auth/otp/verify/ — public (mobile)
Request: `{"phone_number": "08031234567", "request_id": "6f1c2a7e-...", "code": "123456"}`  (`code` = exactly 6 digits)
200 OK:
```json
{"setup_token": "x7Qm...43-char-opaque-string", "expires_in": 600}
```
400 `invalid_otp` (`attempts_remaining` included when the request_id is valid and live), 400 `otp_expired`, 400 `otp_attempts_exceeded`, 400 `validation_error`, 429 `rate_limited`.
A verified code cannot be verified again (second attempt → `invalid_otp`).

### 3.5 POST /api/v1/auth/setup-account/ — public, needs setup token (mobile)
Request: `{"setup_token": "x7Qm...", "username": "amina_b", "password": "S3cure!pass"}`
201 Created (user is logged in immediately):
```json
{"access": "<jwt>", "refresh": "<jwt>", "user": {"id": "1b9e...", "username": "amina_b", "phone_number": "+2348031234567", "date_joined": "2026-10-21T09:41:00Z"}}
```
400 `validation_error` (username/password rules — token NOT consumed, user may retry), 409 `duplicate` with `fields.username` = `["This username is taken."]` (token NOT consumed), 400 `setup_token_invalid` (message: `Your verification has expired. Please verify your phone number again.`), 429 `rate_limited`.

### 3.6 POST /api/v1/auth/login/ — public (mobile)
Request: `{"username": "Amina_B", "password": "S3cure!pass"}` (username is lowercased by the server)
200 OK: same body as 3.5 (`access`, `refresh`, `user`).
401 `invalid_credentials` (message: `Incorrect username or password.`), 400 `validation_error`, 429 `rate_limited`.

### 3.7 POST /api/v1/auth/refresh/ — public (mobile)
Request: `{"refresh": "<jwt>"}`
200 OK: `{"access": "<jwt>", "refresh": "<new jwt>"}` — client MUST replace both stored tokens.
401 `token_invalid`.

### 3.8 GET /api/v1/auth/me/ — Bearer (mobile)
200 OK: `{"id": "1b9e...", "username": "amina_b", "phone_number": "+2348031234567", "date_joined": "2026-10-21T09:41:00Z"}`
401 `not_authenticated` / `token_invalid`.

### 3.9 POST /api/v1/auth/logout/ — Bearer (mobile)
Request: `{"refresh": "<jwt>"}`
204 No Content (always, even if the refresh token was already invalid — idempotent). 401 only if the access token is missing/invalid; clients treat that as logged out too.

### 3.10 Developer endpoints (backend only, not used by apps)
`GET /api/v1/schema/` (OpenAPI YAML) and `GET /api/v1/docs/` (Swagger UI). `/admin/` Django admin.

## 4. Shared mock scenarios (web and mobile mock modes MUST implement exactly these)

Mock latency: 600 ms on every call. Any input not listed → success path.

| Endpoint | Trigger (after normalization) | Mock response |
|---|---|---|
| registrations | `matric_number == "CHDC/DUP"` | 409 duplicate on `matric_number` |
| registrations | `phone_number == "+2348000000001"` | 409 duplicate on `phone_number` |
| registrations | `phone_number == "+2348000000500"` | 500 server_error |
| otp/request | `phone_number == "+2348000000429"` | 429 rate_limited, `retry_after: 42` |
| otp/request | anything valid | 200, `request_id: "00000000-0000-4000-8000-000000000001"`, `expires_in: 300`, `resend_after: 60` |
| otp/verify | `code == "123456"` | 200, `setup_token: "mock-setup-token"`, `expires_in: 600` |
| otp/verify | `code == "000000"` | 400 otp_expired |
| otp/verify | `code == "999999"` | 400 otp_attempts_exceeded |
| otp/verify | any other code | 400 invalid_otp, `attempts_remaining: 4` |
| setup-account | `username == "taken_user"` | 409 duplicate on `username` |
| setup-account | `setup_token != "mock-setup-token"` | 400 setup_token_invalid |
| setup-account | otherwise valid | 201, `access: "mock-access-token"`, `refresh: "mock-refresh-token"`, user below |
| login | `username == "student1"` and `password == "Password123!"` | 200 with mock tokens + user |
| login | anything else | 401 invalid_credentials |
| refresh | `refresh == "mock-refresh-token"` | 200 same mock tokens |
| me | access token `mock-access-token` | 200 mock user |
| logout | any | 204 |

Mock user: `{"id": "00000000-0000-4000-8000-0000000000aa", "username": "student1", "phone_number": "+2348031234567", "date_joined": "2026-10-21T09:00:00Z"}` (on setup-account, `username` echoes the submitted username).

## 5. User-facing copy shared by both apps
- OTP sent (always, generic): `If this number is registered and not yet set up, a verification code has been sent by SMS.`
- Not registered hint (mobile, always visible on phone screen): `Haven't registered yet? Register on the web portal first.`
- Home placeholder banner: `Sample data — real case features arrive in a later milestone.`
- SMS text (backend): `Your CHDC E-Counselling verification code is {code}. It expires in 5 minutes. Do not share it with anyone.`

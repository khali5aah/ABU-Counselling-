# CHDC E-Counselling mobile app

The Flutter app provides student account setup (phone OTP), login, session
handling, and an in-memory counselling-case prototype. The case prototype is
not connected to the API and must not be used for real counselling records.

## Requirements and install

- Flutter stable 3.24+ and Dart 3.5+
- Android Studio / Android SDK for Android, or macOS with Xcode for iOS

```sh
flutter pub get
```

## Run in mock mode

```sh
flutter run --dart-define=USE_MOCK=true
```

Mock mode persists mock session tokens in secure storage so restarting the app
exercises the normal session restore flow. The app uses the live backend unless
mock mode is explicitly enabled.

| Flow | Mock input |
|---|---|
| Request OTP | Any valid phone number receives the generic response |
| Verify mock OTP | `+2348031234567` with code `123456` (registered mock student) |
| Rate limit | `08000000429` |
| Expired OTP | `000000` |
| Too many OTP attempts | `999999` |
| Incorrect OTP | Any other six-digit code |
| Duplicate username | `taken_user` |
| Successful login | `student1` / `Password123!` |

For local mock mode, `123456` only verifies the mock student
`+2348031234567`. The development backend accepts `123456` only for web
registrations explicitly listed in `OTP_DEV_TEST_PHONES`, with
`DJANGO_DEBUG=true` and `OTP_PROVIDER=console`. Other registered numbers use
their generated development code; unregistered numbers are rejected before
the OTP screen. List allowlisted numbers in E.164 format (for example,
`+2348031234567`). The public demo uses `OTP_PROVIDER=demo` with
`DEMO_SIGNUP_CODES_ENABLED=true` and `DJANGO_DEBUG=false`; it returns a
server-generated, one-time registration code to the web confirmation page.
The app verifies that same code against the API. This mode does not send SMS
and is only for synthetic demo data.

## Run against the live backend

Start the backend first. The API base URL must include `/api/v1/`:

```sh
# Android emulator talking to a backend on this computer
flutter run \
  --dart-define=USE_MOCK=false \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1/
```

For a physical Android device on the backend's network, replace `10.0.2.2`
with the backend host's LAN IP. The backend must allow the requested host in
`DJANGO_ALLOWED_HOSTS` and, for web clients, the web origin in
`CORS_ALLOWED_ORIGINS`.

With `OTP_PROVIDER=console`, OTP codes are written to backend logs as
`[DEV OTP]`; this provider is for development only. Use the approved Termii
provider for a real SMS integration.

## Build a release APK

```sh
flutter build apk --release \
  --dart-define=USE_MOCK=false \
  --dart-define=API_BASE_URL=https://<api-host>/api/v1/ \
  --dart-define=WEB_REGISTRATION_URL=https://<web-host>/register
```

The output is `build/app/outputs/flutter-apk/app-release.apk`. API and
registration URLs are compiled into the app; rebuild if they change.

## Current feature/security limits

- Cases are held only in app memory and disappear when the app restarts.
- There is no backend case endpoint, counsellor workflow, or server-side case
  access control yet.
- Biometric case access is prototype UI, not a security boundary. Do not enter
  real sensitive counselling details until case storage and access control are
  implemented and reviewed.

## Publish a signed Android release

Create and push a version tag matching `mobile/pubspec.yaml` (for example,
`v1.0.1`). The Android Release workflow builds a signed APK and AAB and attaches
both to a GitHub Release. Configure these GitHub Actions settings first:

- Repository secret `ANDROID_KEYSTORE_BASE64`: base64-encoded upload keystore
- Repository secrets `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, and
  `ANDROID_KEY_PASSWORD`
- Repository variables `API_BASE_URL` and `WEB_REGISTRATION_URL`, both HTTPS
  URLs for the production services

The Android release build requires `mobile/android/key.properties`; it does not
fall back to the debug signing key. Keep the keystore and passwords private.

## Checks

```sh
flutter analyze
flutter test
```

See the [user guide](../docs/user-guide.md) and
[technical overview](../docs/technical-overview.md).

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

## Run with mock authentication

```sh
flutter run --dart-define=USE_MOCK=true
```

Mock mode is enabled by default and is marked by a `MOCK API` banner. Mock
session tokens are stored using secure storage to exercise session restore.

| Flow | Mock input |
|---|---|
| Request OTP | Any valid Nigerian mobile number |
| Rate limit | `08000000429` |
| Expired OTP | `000000` |
| Too many OTP attempts | `999999` |
| Successful OTP | `123456` |
| Incorrect OTP | Any other six-digit code |
| Duplicate username | `taken_user` |
| Successful login | `student1` / `Password123!` |

## Run against the backend

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

## Checks

```sh
flutter analyze
flutter test
```

See the [user guide](../docs/user-guide.md) and
[technical overview](../docs/technical-overview.md).

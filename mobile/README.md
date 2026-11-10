# CHDC E-Counselling mobile app

## Prerequisites

- Flutter stable 3.24 or newer (Dart 3.5 or newer)
- Android Studio with the Android SDK and an emulator, or an Android phone
- For iOS builds, macOS with Xcode

## Install dependencies

From this directory:

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
`+2348031234567`). Production backends continue generating random OTPs.

## Run against the live backend

Start the backend with Docker Compose first.

Android emulator on the same computer:

```sh
flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Android phone on the same Wi-Fi as the backend:

```sh
flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=http://<backend-LAN-IP>:8000
```

The backend must allow the device IP in `DJANGO_ALLOWED_HOSTS`. When the
backend is running with `DJANGO_DEBUG=true` and `OTP_PROVIDER=console`, enter
`123456` for a phone number registered on the web. Unregistered numbers cannot
verify, even though the OTP request response is generic. Production backends
continue generating random OTPs.

## Build a demo APK

```sh
flutter build apk --release --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=<url> --dart-define=WEB_REGISTRATION_URL=<web-url>
```

The APK is written to
`build/app/outputs/flutter-apk/app-release.apk`. The URL is compiled into the
app, so rebuild the APK if the backend URL changes.

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
flutter pub get
flutter analyze
flutter test
```

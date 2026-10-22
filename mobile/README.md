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

Mock mode is enabled by default. It persists mock session tokens in secure
storage so restarting the app exercises the normal session restore flow.

| Flow | Mock input |
|---|---|
| Send OTP | Any valid Nigerian mobile number |
| Rate limit | `08000000429` |
| Expired OTP | `000000` |
| Too many OTP attempts | `999999` |
| Successful OTP | `123456` |
| Incorrect OTP | Any other six-digit code |
| Duplicate username | `taken_user` |
| Successful login | `student1` / `Password123!` |

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

The backend must allow the device IP in `DJANGO_ALLOWED_HOSTS`. For the
development OTP code, run `scripts\otp.ps1` from the repository root (it prints
each `[DEV OTP]` line from the API logs as phone and code).

## Build a demo APK

```sh
flutter build apk --release --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=<url> --dart-define=WEB_REGISTRATION_URL=<web-url>
```

The APK is written to
`build/app/outputs/flutter-apk/app-release.apk`. The URL is compiled into the
app, so rebuild the APK if the backend URL changes.

## Checks

```sh
flutter pub get
flutter analyze
flutter test
```

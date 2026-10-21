# Crownbird E-Counselling Mobile App

This Flutter app implements the mobile interface for phone verification, OTP validation, account setup, login, and the authenticated home screen.

## Run locally

```bash
flutter pub get
flutter run
```

## Mock mode

The app starts in mock mode by default. Use the following demo flows:

- Phone number: any valid Nigerian number
- OTP: `123456` for success
- Login: `student1` / `Password123!`

## Switch to live backend mode

Set the environment variable before running:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Or change the default value in `lib/config/env.dart`.

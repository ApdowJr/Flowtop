# flowTop

Premium, modern task management application for personal and team productivity, built with **Flutter + Firebase** for Android.

## Tech Stack

- Flutter & Dart (stable)
- [Riverpod](https://riverpod.dev/) — state management
- [GoRouter](https://pub.dev/packages/go_router) — navigation
- **Firebase Authentication** — email/password, Google Sign-In, password reset
- **Cloud Firestore** — primary database (offline persistence enabled)
- **Firebase Storage** — profile images, task attachments, project files
- **Firebase Cloud Messaging (FCM)** — push notifications
- **Firebase Cloud Functions** — trusted server-side operations (TypeScript)
- **Firebase App Check** — app protection
- Clean feature-based architecture

## Brand

- Primary: `#7C3AED` (violet-600)
- Secondary: `#8B5CF6` (violet-500)
- Light + dark themes, English UI copy

## Features

1. Splash + onboarding
2. Email registration & login
3. Google Sign-In
4. Password reset
5. Personal dashboard with task progress
6. Tasks: create, edit, delete, search, filter, complete (priorities Low/Medium/High, due dates, reminders, overdue)
7. Projects & progress
8. Calendar (daily/weekly)
9. Team workspaces, invitations, membership & roles (owner/admin/manager/member/viewer)
10. Task assignment & collaboration
11. Statistics & productivity charts
12. Profile & preferences
13. Dark/light theme
14. Push notifications
15. Offline-friendly (Firestore persistence)
16. Loading, error, success, empty states

## Project Structure (feature-based)

```
lib/
  core/           constants, theme, di, network, utils, widgets, router
  features/
    auth/         sign in, sign up, reset password, Google
    onboarding/
    tasks/        CRUD, search, filter, priorities, subtasks
    projects/
    calendar/
    workspaces/   members, invitations, roles
    notifications/
    statistics/
    profile/
firebase/
  firestore.rules
  storage.rules
  emulators.json
  functions/      TypeScript Cloud Functions
android/ ios/
test/             unit, widget, integration, rules tests
```

## Prerequisites

- Flutter SDK (stable) — https://docs.flutter.dev/get-started/install
- Android Studio / Android SDK (for Android builds)
- A Firebase project (Spark plan is sufficient; no billing required)

## Firebase Setup

See **FIREBASE_SETUP.md** for step-by-step instructions (create project, enable Auth/Firestore/Storage/FCM/App Check, register Android app, download `google-services.json`).

> **Important:** Never commit `google-services.json`, service account keys, or `.env` files. They are listed in `.gitignore`. A configuration example is provided.

## Local Development (Firebase Emulator Suite)

1. Install the Firebase CLI: `npm install -g firebase-tools`
2. Log in: `firebase login`
3. From the project root, start emulators:
   ```
   firebase emulators:start
   ```
4. Emulator ports (see `emulators.json`):
   - Auth: 9099, Firestore: 8080, Storage: 9199, Functions: 5001, UI: 4000

### Security Rules Tests

Install the rules unit testing dependency and run:

```bash
npm install @firebase/rules-unit-testing
node test/firestore_rules.test.js
```

> These tests run against the Firestore emulator and assert production-minded access control (role enforcement, protected fields, deny-by-default).

## Android Build

Local Android builds require the Android SDK + Java (not present in this sandbox). See **ANDROID_BUILD.md**.

For remote builds, a GitHub Actions workflow is provided at `.github/workflows/android-build.yml` that builds a debug APK and a release AAB.

## Cloud Functions

Trusted server-side operations live in `firebase/functions/` (TypeScript):

- Creating & validating team invitations
- Accepting invitations (transactional)
- Assigning/changing workspace roles
- Sending task assignment notifications
- Sending scheduled task reminders
- Cleaning expired invitations

Deploy:
```bash
cd firebase/functions
npm install
npm run build
firebase deploy --only functions
```

## Testing

```bash
# Analyze
flutter analyze

# Format
dart format lib/ test/

# Unit + widget tests
flutter test

# Integration tests (requires a connected device/emulator)
flutter test integration_test/
```

## Security

- All access control enforced by Firebase Auth + Firestore Security Rules.
- Client-supplied roles/ownership are never trusted.
- Privileged Admin SDK operations run only in Cloud Functions.
- Firebase App Check protects API endpoints where supported.

See **SECURITY.md**.

## License

MIT

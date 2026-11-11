# Firebase Setup — flowTop

This guide walks you through connecting the Flutter app to a Firebase project. No real credentials are included in this repository.

## 1. Create a Firebase project

1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. **Add project** → enter `flowtop` → disable Google Analytics (optional) → Create.
3. Stay on the Spark plan (no billing required for this app).

## 2. Enable Firebase services

In the Firebase Console, enable:

- **Authentication**: Sign-in method → Email/Password (enable), Google (enable, configure OAuth consent screen).
- **Cloud Firestore**: Create database → Start in test mode (you will replace rules with `firestore.rules`) → choose a location.
- **Storage**: Get started → default bucket → you will replace rules with `storage.rules`.
- **Cloud Messaging**: Enable FCM (Android).
- **App Check**: Enable → register Android app with Play Integrity (optional but recommended).

## 3. Register the Android app

1. In Project settings > General > Your apps, **Add app** → Android.
2. Package name: `com.flowtop.app` (matches `android/app/build.gradle` `applicationId`).
3. Register app → download **`google-services.json`**.
4. Place `google-services.json` at: `android/app/google-services.json`

> `google-services.json` is gitignored. Never commit it.

For iOS (optional): add an iOS app and download `GoogleService-Info.plist` to `ios/Runner/`.

## 4. Configure the Flutter app

1. Add Firebase dependencies (already in `pubspec.yaml`):
   - firebase_core, firebase_auth, google_sign_in, cloud_firestore,
   - firebase_storage, firebase_messaging, firebase_app_check
2. Replace `firebase_options.dart` with your real config values from the Firebase Console (Project settings > General > Your apps > Android > config file snippet).

Example `firebase_options.dart`:

```dart
static FirebaseOptions get currentPlatform => const FirebaseOptions(
  apiKey: 'AIzaSy...',
  appId: '1:123456789:android:...',
  messagingSenderId: '123456789',
  projectId: 'flowtop-abc123',
  storageBucket: 'flowtop-abc123.appspot.com',
);
```

3. Initialize Firebase in `main.dart` (already done):
   ```dart
   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
   ```

## 5. Deploy Firestore & Storage rules

From the project root:

```bash
firebase deploy --only firestore:rules,storage:rules,firestore:indexes
```

This deploys `firestore.rules`, `storage.rules`, and `firestore.indexes.json`.

## 6. Deploy Cloud Functions

```bash
cd firebase/functions
npm install
npm run build
firebase deploy --only functions
```

## 7. Enable Firestore offline persistence

In the app, Cloud Firestore persistence is enabled by default on Flutter (cached data + pending writes). No extra client configuration is required for the default `(local)` persistence. See `lib/features/tasks/data/repositories/task_repository_impl.dart` for reads that work offline.

## 8. FCM (push notifications)

1. Add your Android app's SHA-1/SHA-256 certificate fingerprint to Firebase Console (Project settings > Your apps > Android > Certificate fingerprint) — required for Google Sign-In and FCM on real devices.
2. The app registers an FCM token on startup and stores it in `users/{uid}/fcm_tokens/{token}` (see `lib/features/notifications/`).
3. Cloud Functions dispatch notifications server-side using Admin SDK — clients never send arbitrary privileged notifications.

## Directory & file checklist

| File | Purpose |
|------|---------|
| `firebase.json` | Emulator + hosting + functions config |
| `firestore.rules` | Production Firestore security rules |
| `storage.rules` | Production Storage security rules |
| `firestore.indexes.json` | Required composite indexes |
| `emulators.json` | Local emulator ports |
| `firebase/functions/` | TypeScript Cloud Functions |
| `test/firestore_rules.test.js` | Security rules tests (emulator) |

## Troubleshooting

- `firebase_options.dart` placeholder values → replace with real config or Firestore/Auth will fail to initialize.
- Google Sign-In fails → add SHA-1 fingerprint, enable Google provider, configure OAuth consent screen.
- Rules rejected → ensure `firestore.rules` starts with `rules_version = '2';`.

### Google Sign-In: Android ApiException 10

Error 10 usually indicates an OAuth configuration or signing-certificate mismatch;
changing Dart code alone cannot register a certificate. For the **exact APK installed
on the device**:

1. In Firebase project `flowtop-e68b6`, enable Authentication > Sign-in method > Google.
2. In Project settings > Your apps, select Android app `com.flowtop.app` and add
   the SHA-1 and SHA-256 fingerprints of the certificate that signed that APK.
   For a CI debug APK, download `debug-signing-fingerprints.txt` from the same
   workflow run as the APK. For a local debug build run:
   `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android`.
   For Play-distributed builds use the **app signing** certificate in Play Console;
   upload-key fingerprints may be different.
3. Download a fresh `google-services.json` after enabling Google and adding the
   fingerprints. Replace `android/app/google-services.json` locally or update the
   base64-encoded `GOOGLE_SERVICES_JSON` GitHub Actions secret for CI. Check that
   it includes the correct package and a web OAuth client (`client_type: 3`).
4. Rebuild, install the newly signed APK and try again. A fingerprint from another
   machine, another CI run with a different signing key, or another release key
   will not fix the installed APK. CI prints warnings if its current fingerprint
   is missing from the supplied configuration.

### Notifications and security validation

The Android app registers a device token after the notification permission is
requested. Signing out removes this device's token before the Firebase session
ends; other devices remain signed in. In-app notifications written by trusted
server code are forwarded to active tokens by the `deliverNotification` Cloud
Function. Scheduled reminders currently run hourly; foreground display,
notification-tap navigation and delivery under retry conditions still require
real-device verification.

Before deploying, run the Firestore rules tests and build the functions:

```bash
npm ci
npx firebase emulators:exec --project demo-flowtop --only firestore 'node --test test/rules/*.test.js'
(cd firebase/functions && npm ci && npm run build)
```

Deploy the matching rules and functions together to the intended Firebase
project only after reviewing the tests and configuration. The new notification
rules allow clients to update read state but not create notification content.
Deployment requires Firebase project access and is not performed by the app build.

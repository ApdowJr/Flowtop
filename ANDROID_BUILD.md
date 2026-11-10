# Android Build — flowTop

flowTop is a Flutter Android application. This repository does **not** contain prebuilt APK/AAB artifacts or signing credentials.

## Local build requirements

To build Android locally you need:

- Flutter SDK (stable)
- Android SDK (cmdline-tools, platform-tools, a platform, build-tools)
- Java Development Kit (JDK) 17
- Gradle (wrapped via Flutter)

Verify with:
```bash
flutter doctor
```

## Debug APK

```bash
cd /path/to/Flowtop
flutter pub get
flutter build apk --debug
```

Output: `build/app/outputs/flutter-apk/app-debug.apk`

## Release APK (requires signing)

1. Create a keystore (never commit it):
   ```bash
   keytool -genkey -v -keystore ~/flowtop-upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Create `android/key.properties` (gitignored):
   ```
   storePassword=<your-store-password>
   keyPassword=<your-key-password>
   keyAlias=upload
   storeFile=/home/user/flowtop-upload-keystore.jks
   ```
3. Enable signing in `android/app/build.gradle` (referencing `key.properties`).
4. Build:
   ```bash
   flutter build apk --release
   ```

Output: `build/app/outputs/flutter-apk/app-release.apk`

## Android App Bundle (AAB)

For Google Play Store publishing:

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

> Do not publish to Google Play without explicit approval.

## GitHub Actions (remote builds)

If local Android tooling is unavailable, use the provided workflow:

`.github/workflows/android-build.yml`

It builds a debug APK and release AAB on every push/PR using the `mc-roberts/setup-flutter` action (or similar), caching the Flutter SDK and Gradle.

Secrets to add to GitHub (Settings > Secrets and variables > Actions):
- `RELEASE_STORE_PASSWORD`, `RELEASE_KEY_PASSWORD` (optional, for release builds)

Never add secrets to the workflow file itself.

## Signing configuration (summary)

| Item | Location | Notes |
|------|----------|-------|
| Keystore | `~/flowtop-upload-keystore.jks` (example) | Never commit |
| `key.properties` | `android/key.properties` | Gitignored |
| Signing config | `android/app/build.gradle` | References `key.properties` |

## Why no APK/AAB in this repo

The sandbox used to prepare this project has no Java, Android SDK, Gradle, or Dart SDK binary available (network policy blocks the Dart SDK download from `storage.googleapis.com`). The source is complete and buildable in any environment with Flutter + Android SDK installed.

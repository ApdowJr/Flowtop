# Flowtop — Progress Checklist

## Phase 0 — Environment Inspection (DONE — verified)
- [x] Git, gh, Node.js/npm available
- [x] Flutter SDK source cloned from GitHub
- [x] Dart SDK binary BLOCKED (storage.googleapis.com not in allowed hosts) — cannot run flutter analyze/test or build APK
- [x] Java/Android SDK/Gradle NOT installed — no local Android build
- [x] Firebase CLI / FlutterFire CLI NOT installed
- [x] Limitations documented honestly

## Phase 1 — Flutter UI Prototype (DONE — source written)
- [x] Flutter project structure (pubspec, android/ios, lib)
- [x] Premium purple design system (#7C3AED / #8B5CF6, light + dark themes, system font)
- [x] Splash + onboarding screens
- [x] Login / register / password reset screens
- [x] Personal dashboard with task progress
- [x] Task list, details, creation, edit screens
- [x] Projects + calendar screens
- [x] Team workspace screens
- [x] Profile + settings screens
- [x] Reusable widgets + responsive layouts + light/dark themes
- [x] GoRouter navigation (auth redirect + bottom-nav shell) + Riverpod providers
- [x] Notifications page with real-time list
- [x] Removed invalid Inter font declarations (fonts not downloadable in this environment)

## Phase 2 — Firebase Setup & Integration (DONE — source written, config boundary documented)
- [x] pubspec Firebase dependencies
- [x] firebase.json + firestore.indexes.json + emulators.json
- [x] Firestore data models + repositories (offline-first, workspace-scoped)
- [x] Firebase Auth integration (email/pass, Google, reset, sign out)
- [x] Cloud Firestore integration (offline persistence)
- [x] Firebase Storage integration with user-scoped paths + secure Storage rules
- [x] FCM device token registration, refresh, removal service
- [x] Firebase App Check structure (documented)
- [x] FIREBASE_SETUP.md (no invented credentials)

## Phase 3 — Core Functionality (DONE — source written)
- [x] Auth state + protected routing
- [x] User profile management
- [x] Tasks CRUD + search/filter/priority
- [x] Due dates, reminders, overdue status
- [x] Projects + progress tracking (recalculateProgress)
- [x] Calendar daily/weekly views (table_calendar)
- [x] Error/loading/empty states
- [x] Subtask CRUD (create/update/delete)

## Phase 4 — Team Collaboration (DONE — source written + rules)
- [x] Workspace CRUD (fully implemented)
- [x] Team invitations (secure expiration + acceptance workflow)
- [x] Membership + roles (owner/admin/manager/member/viewer)
- [x] Task assignment
- [x] Activity logs (append-only)
- [x] Firestore Security Rules enforcement (firestore.rules)
- [x] Storage Security Rules with user-scoped paths (storage.rules)

## Phase 5 — Notifications (DONE — source written)
- [x] FCM device token management (save/remove/deactivateAll)
- [x] FCM messaging service (initialize, token refresh, auth state listener)
- [x] Foreground/background notification handling
- [x] Task reminder + assignment + invitation notifications
- [x] Notification list page with mark-as-read
- [x] Cloud Functions secure dispatch (TypeScript)

## Phase 6 — Testing & Quality (WRITTEN — not runnable locally)
- [x] Unit tests (task entity, auth notifier, workspace entity, project entity, fcm token entity)
- [x] Widget tests (task list)
- [x] Integration tests (app launch, task flow)
- [x] Firestore Security Rules tests (emulator JS — comprehensive)
- [ ] dart format / flutter analyze / flutter test — BLOCKED (no Dart SDK)

## Phase 7 — Android Build (DOCUMENTED — not buildable locally)
- [x] GitHub Actions workflow (APK + AAB)
- [x] Real Gradle wrapper (gradlew + gradlew.bat + gradle-wrapper.properties)
- [x] ANDROID_BUILD.md + signing instructions
- [ ] APK/AAB artifact — BLOCKED (no Java/Android SDK); will not claim

## Phase 8 — Documentation & Delivery (DONE)
- [x] README.md
- [x] FIREBASE_SETUP.md
- [x] ANDROID_BUILD.md
- [x] SECURITY.md
- [x] .gitignore (secrets excluded)
- [x] Complete project delivered as source files

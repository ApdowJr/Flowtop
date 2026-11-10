# Security — flowTop

## Principles

- **Never trust the client.** Client-supplied user IDs, roles, and ownership are ignored or validated server-side.
- **Access control in the database layer.** Firestore Security Rules and Storage Security Rules enforce authorization; Flutter UI never bypasses them.
- **Privileged operations in Cloud Functions.** Admin SDK usage is confined to Cloud Functions (TypeScript), never in the Flutter client.
- **Secrets never committed.** `google-services.json`, service account keys, `.env`, and keystore files are gitignored.

## Authentication

- Email/password and Google Sign-In via Firebase Authentication.
- Firebase Auth UID is the canonical user identifier.
- Auth state persists across sessions; routes are protected by GoRouter redirects.
- Password reset emails sent via Firebase Auth (client never handles reset tokens).

## Firestore Security Rules (`firestore.rules`)

Key guarantees:

- Users read/write only their own `users/{uid}` document.
- Workspace data accessible only to members of that workspace.
- Roles enforced: `owner`, `admin`, `manager`, `member`, `viewer`.
- Only `owner`/`admin` can invite members or change roles.
- Members cannot promote themselves.
- Protected fields (`ownerId`, role) cannot be changed by non-privileged clients.
- Required fields and types validated.
- Default: deny all (`allow read, write: if false` for unmatched documents).

## Storage Security Rules (`storage.rules`)

- Authenticated users only.
- Profile images scoped to the owning user (`userId == request.auth.uid`).
- File size limit: 10 MB.
- Allowed MIME types: images, PDF, plain text.
- Unauthorized access and deletion denied.

## Cloud Functions

Trusted operations (TypeScript, Admin SDK):

- Invitations: create with server-side expiration, accept via transaction.
- Role changes: owner/admin only; self-promotion blocked.
- Notifications: task assignment, task reminders, workspace invitations — dispatched server-side via FCM.
- Expired invitation cleanup.

## App Check

Enable Firebase App Check (Play Integrity for Android) to protect Firestore, Storage, and Functions endpoints from abuse. Configured via `FirebaseAppCheck` in the app's initialization.

## Testing security rules

```bash
firebase emulators:start
node test/firestore_rules.test.js
```

Tests assert member-only access, role enforcement, protected-field protection, expiration validation, and deny-by-default.

## Reporting

Do not create paid resources or enable billing without approval. Do not hardcode credentials.

# SpendWise release setup

Prepared for Android package `com.bytesforges.spendwise`, Firebase project `emergio-f2ef7`, and support contact `bytesforges@gmail.com`.

## Implemented locally

- AI provider key is no longer bundled in Flutter assets. AI, friend lookup, reports and deletion use an authenticated Firebase HTTPS function.
- AI consent and email discovery are off by default. Camera/contacts are feature-specific; daily reminder notification permission is requested when enabled.
- Location tracking and exact-alarm permissions removed. Unused Firebase Messaging and native RAG dependencies removed.
- QR scanner upgraded to `mobile_scanner ^7.4.2` after the old native barcode/CameraX libraries failed 16 KB ELF alignment checks.
- More > Privacy & Account includes consent, discovery, reminders, verification and account deletion. Privacy information is available before sign-in.
- AI responses have an in-app report action; reports are stored for developer review.
- Firestore rules isolate profiles and financial subcollections by authenticated UID. Client profile enumeration is denied; opted-in friend lookup returns only name, email, photo and ID.
- Deletion uses recent authentication, blocks concurrent writes, recursively removes user subcollections and usage counters, then deletes Firebase Auth. A temporary marker blocks stale tokens.
- Release builds use an upload keystore; there is no debug-signing fallback.
- Data providers are recreated when accounts change; unmanaged financial streams are cancelled on disposal.

## Signing files: back up securely now

`android/upload-keystore.jks` and `android/key.properties` were generated locally. Both are ignored by Git. Back them up together in secure storage. Do not commit or share the properties file; it contains the keystore password. Play App Signing manages the store signing key; this local key is the upload key.

## Firebase access and Android registration

Access was restored on October 17, 2026 using `imdeepakdeepu01@gmail.com`. The Android app is registered as `1:325788297793:android:cab278cb7c9a4e1f3274c0`, package `com.bytesforges.spendwise`. Upload and local debug SHA-1/SHA-256 certificates have been registered, and `android/app/google-services.json` has been refreshed. Email/password and Google sign-in providers are enabled.

To check access later:

```powershell
firebase login --reauth
firebase apps:list ANDROID --project emergio-f2ef7
```

The **Play app-signing SHA-1/SHA-256** from Play Console must still be added once available. It differs from the local upload certificate.

`main.dart` now uses native Firebase configuration so the old generated `firebase_options.dart` is not used by Android. Its generated binding was removed from firebase.json to avoid pointing at the old Android app.

## Backend deployment

Billing is disabled, and Cloud Functions is disabled. You chose to keep Functions undeployed for now. No billing changes or Functions/Hosting deployment were performed; only the separately approved security rules were deployed. When ready, enable a suitable Firebase billing plan yourself, set a rotated provider key privately, and review the deployment commands below.

```powershell
cd functions
npm ci
cd ..
firebase functions:secrets:set DEEPSEEK_API_KEY --project emergio-f2ef7
firebase deploy --only functions:spendwise --project emergio-f2ef7
```

Use a newly rotated DeepSeek key. Previously distributed builds may contain the old key. Enter the new key through the secret prompt; never add it to Flutter assets or Dart defines. The function limits each account to 50 AI requests, 20 email lookups and 20 reports per UTC day, with bounded input and output sizes. Configure billing alerts, quotas and abuse monitoring; per-account limits do not prevent abuse through many newly created accounts. Consider Firebase App Check before a broad rollout.

In Firestore, enable TTL for `expiresAt` on the `account_lifecycle`, `actions`, and `ai_reports` collection groups. Report TTL is 90 days; completed-deletion marker TTL is 24 hours. TTL deletion is asynchronous. Incomplete deletions retain a durable pending marker without an expiry. The `retryAccountDeletions` scheduled function runs hourly and retries up to 50 pending deletions older than five minutes; monitor failures and queue backlogs. Cloud Scheduler is included in the backend deployment and can incur charges. Review AI reports regularly in the Firebase console; the reporting button alone does not provide moderation operations.

## Security rules: preserve other apps in a shared project

The previous deployed rules allowed every authenticated user to read and write the entire database. A backup is saved in `firebase-backups/firestore-before-spendwise-2026-10-17.rules`. The merged `firestore.rules` restricts SpendWise and its backend paths while preserving the previous policy for unrelated top-level collections. Emulator tests passed for isolation and preservation. **The merged rules were deployed on October 17, 2026 with your approval.** Functions and Hosting remain undeployed. Other app collections still need a separate security review.

After reviewing the merged rules and checking for any intervening cloud edits, deploy:

```powershell
firebase deploy --only firestore:rules --project emergio-f2ef7
```

Never deploy the new app to testers while the old permissive profile-read rules remain active. New rules intentionally block older clients' direct email lookup; migrate clients together.

## Policy pages

Review `public/privacy.html` and `public/account-deletion.html` against actual operations and provider retention practices. In particular, configure TTL before publishing retention promises. Monitor the support mailbox and establish a verified process for web/email deletion requests.

```powershell
firebase deploy --only hosting --project emergio-f2ef7
```

Expected URLs, once the default Firebase Hosting site is enabled:

- `https://emergio-f2ef7.web.app/privacy.html`
- `https://emergio-f2ef7.web.app/account-deletion.html`

Hosting configuration serves `public/`. If the project already hosts another site, use a separate Hosting target or merge the hosting configuration instead of replacing its site.

## Build and verification

After deploying, use the function URL reported by Firebase (expected `https://asia-south1-emergio-f2ef7.cloudfunctions.net/spendwiseApi`):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/build-play-release.ps1 -ApiUrl 'https://asia-south1-emergio-f2ef7.cloudfunctions.net/spendwiseApi' -PrivacyPolicyUrl 'https://emergio-f2ef7.web.app/privacy.html'
```

The script rejects missing signing configuration, non-HTTPS URLs and mismatched Firebase package registration. Output: `build/app/outputs/bundle/release/app-release.aab`. A verification bundle built before deployment must not be published: the URLs point to services/pages that are not yet deployed. Increase `version: 1.0.0+1` in pubspec.yaml for each subsequent upload.

```powershell
flutter analyze --no-fatal-infos
flutter test
cd functions
npm test
cd ..
firebase emulators:exec --only firestore --project demo-spendwise "npm.cmd --prefix functions run test:rules"
firebase emulators:exec --only auth,firestore,functions --project demo-spendwise "npm.cmd --prefix functions run test:integration"
```

Integration tests use only the demo project and an ignored `functions/.secret.local` with an emulator placeholder, never a real provider key. They do not exercise paid AI calls.

Verify the final merged manifest targets API 36+, contains no location/exact-alarm permissions or unexpected SDK permissions, and inspect its native libraries for 16 KB page alignment. Test the Play-installed build on a 16 KB emulator/device. Removing unused native packages reduces risk but does not establish compatibility for the remaining Flutter, ML Kit and scanner libraries.

Run the repeatable local artifact checks after building:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/verify-play-bundle.ps1
```

Test registration, Google sign-in using Play's certificate, email verification, denied permissions, offline writes/reconnection, account switching, monetary rounding, reminder behavior after reboot, AI consent and failures, report submission, and deletion with nested data. Sign out/in immediately before deleting; a token refresh does not satisfy recent authentication. Clearing app storage removes remaining device caches. Deletion does not erase independent records owned by other users or provider-retained AI data automatically.

## Play Console work still required

- Developer identity/account verification and production-access requirements.
- Privacy policy and external deletion URLs, Data safety, app access/reviewer credentials, content rating, target audience, ads and financial features declarations.
- Accurately disclose account identifiers, financial records, selected friend/contact data, AI submissions and reports; review all SDKs and provider guidance. Do not claim that no data is collected or sent off-device.
- Accurate icon, screenshots, feature graphic, support email and store descriptions. Remove location-reminder and push-notification claims from store copy.
- Internal testing and Play pre-launch report; if applicable, 12 closed testers continuously opted in for 14 days before applying for production access.
- Review AI safety behavior with adversarial prompts and a report-handling process. General guidance disclaimer and system instructions are not a guarantee of policy compliance.

The existing app-wide deprecation/style lints are separate from these release fixes. A fresh signed bundle, native-page verification and real-device acceptance test remain necessary before publication.

## Local validation on October 17, 2026

- Flutter tests: 2 passed (pre-sign-in privacy disclosure and subscription/session disposal).
- Flutter analysis: no errors or warnings; 138 informational lint notices remain.
- Backend validation tests: 4 passed.
- Firestore emulator rules test: passed (cross-user isolation, profile enumeration, protected paths and deletion lock).
- Auth/Firestore/Functions emulator integration test: passed (authentication, request limits, reporting, recursive deletion, caller isolation, stale tokens and interrupted-deletion recovery).
- JavaScript syntax check and backend module loading: passed.
- Firebase continuation: approved Android package registered, upload/debug fingerprints added, native config refreshed, Google/email providers verified, and merged Firestore rules deployed and read back successfully. Billing remains disabled; Functions and Hosting remain undeployed by request.
- Signed verification bundle built successfully: `build/app/outputs/bundle/release/app-release.aab` (80.1 MB). Signature matches the upload certificate, target API is 36, and the merged manifest has no location/exact-alarm permissions. No `.env` is bundled.
- All 14 inspected 64-bit native libraries pass 16 KB ELF load-segment alignment after the scanner upgrade. Generated APK ZIP alignment and on-device runtime tests remain pending.
- **Do not publish this verification bundle yet.** Its configured backend and privacy URLs are not deployed, so account deletion, AI, server friend lookup and public policy access are not ready for production.

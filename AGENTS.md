# Repository Guidelines

## Project Structure & Module Organization
SpendWise is a Flutter expense tracker backed by Firebase and a Node.js 22 Functions service.
- `lib/core/`: shared services, themes, constants, and utilities.
- `lib/data/`: models, repositories, OCR, and QR processing.
- `lib/providers/`: Provider-based state and session management.
- `lib/presentation/`: feature screens and reusable widgets; `lib/main.dart` initializes the app.
- `test/`: Dart unit and widget tests; `functions/test/`: backend validation, rules, and API tests.
- `assets/`: fonts and app icons; platform directories contain native configuration.
- `functions/`, `firestore.rules`, and `public/`: backend code, database access rules, and hosted policy pages. `tools/` contains PowerShell release utilities.

## Build, Test, and Development Commands
Run from the repository root unless stated otherwise. Use a Flutter SDK supporting Dart `^3.10.0`.
- `flutter pub get`: install Flutter dependencies.
- `flutter run`: launch on a connected device or emulator.
- `dart format lib test`: format Dart sources and tests.
- `flutter analyze`: check code with the configured `flutter_lints` rules.
- `flutter test`: run the Flutter suite.
- `npm ci --prefix functions`: install locked backend dependencies.
- `npm test --prefix functions`: run backend validation tests.
- `flutter build apk --debug`: build a development APK. For signed bundles, follow `PLAY_STORE_RELEASE.md` and `tools/build-play-release.ps1`.

## Coding Style & Naming Conventions
Use two-space indentation and Dart formatter output. Name files `snake_case.dart`, classes `UpperCamelCase`, and members `lowerCamelCase`. Follow existing suffixes such as `_screen`, `_provider`, `_repository`, and `_model`. Keep persistence in repositories, state in providers, and reusable UI in widgets. Match existing CommonJS conventions in backend JavaScript.

## Testing Guidelines
Use `flutter_test` and `fake_cloud_firestore`; name Dart tests `*_test.dart` and backend tests `*.test.js`. Cover changed financial logic, account isolation, and UI behavior. No numeric coverage threshold is configured.

Run rules tests with `firebase emulators:exec --only firestore --project demo-spendwise "npm.cmd --prefix functions run test:rules"`. API tests use `--only auth,firestore,functions` and `test:integration`; see the release guide for emulator secret setup. Never target production with these tests.

## Commit & Pull Request Guidelines
History mixes free-form messages with `feat:` and `docs:` prefixes; prefer concise Conventional Commit subjects. Keep commits focused. PRs should describe behavior changes, link relevant issues, report validation, and include screenshots for UI changes. Document configuration or deployment changes.

## Security & Configuration
Keep AI keys server-side. Never commit signing credentials, keystores, or emulator secrets. Preserve user-scoped Firestore access and account-switch cleanup when changing repositories or providers.

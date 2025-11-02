# Travel Wizards

Material 3 Flutter app for planning trips with an Explore ideas flow, localization, and a backend-enabled data source (optional).

## Quick Start

1. **Clone the repository**
2. **Set up Firebase configuration** (see [Firebase Setup](#firebase-setup))
3. **Copy sample configuration files:**

   ```bash
   cp .env.sample .env
   cp lib/firebase_options.dart.sample lib/firebase_options.dart
   cp web/index.html.sample web/index.html
   cp web/firebase-messaging-sw.js.sample web/firebase-messaging-sw.js
   ```

4. **Configure your Firebase project** and update the configuration files
5. **Run the app:**

   ```bash
   flutter pub get
   flutter run
   ```

## Configuration Files

This project uses sample configuration files to protect sensitive data:

- `.env.sample` → `.env` (environment variables)
- `lib/firebase_options.dart.sample` → `lib/firebase_options.dart` (Firebase config)
- `web/index.html.sample` → `web/index.html` (web Firebase config)
- `web/firebase-messaging-sw.js.sample` → `web/firebase-messaging-sw.js` (web messaging)
- `android/app/google-services.template.json` → `android/app/google-services.json` (Android config)

⚠️ **Never commit the actual configuration files to git** - they contain sensitive API keys.

## Architecture Snapshot

- **Entry & shell**: `lib/main.dart` bootstraps the app and defers to `src/core/app/app.dart` for theme, router, and accessibility scaling.
- **Design system**: `src/core/app/theme.dart` plus the tokens under `src/ui/design_tokens/` drive colors, typography, spacing, and component styles.
- **Routing**: `src/core/routing/router.dart` centralizes all `go_router` routes; `nav_shell.dart` hosts bottom navigation and adaptive drawers.
- **State & DI**: `src/shared/services` contains singleton services registered via `dependency_management_service.dart`; view logic lives in `src/features/.../controllers` following MVVM.
- **Feature UI**: Screens sit under `src/features/<domain>/views/screens`; shared widgets reside in `src/shared/widgets` (e.g., `travel_components/`).
- **Data layer**: Firestore/back-end facades live in `src/shared/services` and `src/shared/repositories`; mocks for tests live in `test/mocks`.
- **Testing utilities**: `test/test_helpers.dart` provides `wrapWithApp`, while `test/accessibility_baseline_test.dart` and golden suites guard visual/a11y regressions.

## Run locally

Default (local in-memory ideas, no backend needed):

```bash
flutter run
```

Building APK's:

```bash
flutter build apk --debug
```

## Remote ideas (optional)

Enable a backend ideas source using build-time flags. The app will gracefully fall back to local in-memory ideas on errors.

Web:

```bash
flutter run -d chrome \
  --dart-define=USE_REMOTE_IDEAS=true \
  --dart-define=BACKEND_BASE_URL=http://localhost:8080
```

Android emulator:

```bash
flutter run -d android \
  --dart-define=USE_REMOTE_IDEAS=true \
  --dart-define=BACKEND_BASE_URL=http://10.0.2.2:8080
```

### Backend contract

- Endpoint: `GET {BASE_URL}/ideas[?q=<query>]`
- Response: JSON array of objects with shape:
  - `id: string`
  - `title: string`
  - `subtitle: string`
  - `tags: string[]`
  - `durationDays: number`
  - `budget: 'low'|'medium'|'high'`

## Payments & Backend quickstart

Use the included FastAPI backend for payments/subscriptions/bookings/notifications and ADK proxy.

Backend:

```bash
cd ../backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
# Optional: concierge (ADK) proxy config
export ADK_BASE_URL=http://127.0.0.1:8000
export ADK_APP_NAME=travel_concierge
# Optional: FCM keys for real push; else sends are simulated
# export FCM_PROJECT_ID=...
# export GOOGLE_APPLICATION_CREDENTIALS=/abs/path/service_account.json
uvicorn app.main:app --reload --host 0.0.0.0 --port 8080
```

Flutter (web):

```bash
flutter run -d chrome \
  --dart-define=BACKEND_BASE_URL=http://localhost:8080
```

Flutter (Android emulator):

```bash
flutter run -d android \
  --dart-define=BACKEND_BASE_URL=http://10.0.2.2:8080
```

Payments config:

- `STRIPE_PUBLISHABLE_KEY` (optional; for real Stripe flows)
- `STRIPE_BACKEND_URL` or `BACKEND_BASE_URL` point to the FastAPI backend.
- Optional dev: `--dart-define MOCK_PAYMENTS=true` to bypass PaymentSheet in demos.

### Competition Sandbox Integrations

For the Google competition build we keep all third-party services in cost-free sandbox mode:

- **EaseMyTrip & vendor bookings**: `BookingIntegrationService` simulates reservations when `kBackendBaseUrl` is unset. Tests stay deterministic while real APIs remain a drop-in swap once credentials are allowed.
- **Local transport (Uber/Rapido)**: transport legs are generated from mocked catalogs in the same service so no paid rides are invoked.
- **Stripe / Google Pay**: payment flows default to sandbox tokens. Launch with `--dart-define MOCK_PAYMENTS=true` to bypass PaymentSheet during the competition.

Once the event concludes, supply real credentials (backend URL, vendor keys, production Stripe keys) and disable the mock flag to enable live traffic without code changes. Review the API key restriction checklist in [Firebase Setup](#firebase-setup) before turning on production access.

Examples:

```bash
flutter run -d android \
  --dart-define=STRIPE_BACKEND_URL=http://10.0.2.2:8080 \
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_xxx \
  --dart-define=MOCK_PAYMENTS=true
```

## Firebase Setup

### Configuration files

- `lib/firebase_options.dart` (generated by FlutterFire) for multi-platform options
- `android/app/google-services.json` for Android
- `web/index.html` & `web/firebase-messaging-sw.js` for web builds

Generate them via FlutterFire:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Or copy the `*.sample` templates listed above and paste credentials from the Firebase console.

### Service enablement checklist

Turn on Authentication (Email/Password + Google), Firestore, Cloud Storage, Cloud Messaging, and Analytics (optional). Keep rules locked down (`firestore.rules`, `storage.rules`) before shipping.

### People API consent & verification

If you prefill onboarding data, add the following scopes to your Google Cloud OAuth consent screen and submit verification before launch:

- `https://www.googleapis.com/auth/user.birthday.read`
- `https://www.googleapis.com/auth/user.gender.read`
- `profile`
- `email`

Use the consent copy: “Used to prefill profile details during onboarding so the user can confirm or edit the data.” Store consent timestamps in `users/{uid}/consents/peopleApi` (already implemented) for audits.

### API key restrictions

- **Maps & Places**: Restrict to `com.travelwizards.app` + release SHA-1 on Android and to `https://*.travelwizards.app/*` (plus localhost during dev) on web.
- **Firebase Cloud Messaging**: Keep the server key secret; Cloud Functions use service accounts instead.
- **Stripe / Google Pay**: Client uses publishable test keys plus `MOCK_PAYMENTS=true`; keep secret keys on the backend until the competition ends.

### Validation & troubleshooting

```bash
flutter clean
flutter pub get
flutter run
```

If initialization fails, double-check that `Firebase.initializeApp()` runs in `main.dart` and that the generated files are present. Web builds require the scripts injected in `web/index.html` and a matching service worker configuration.

## Concierge (ADK) streaming chat

Start the ADK sample server separately (see `backend/README.md`):

```bash
git clone https://github.com/google/adk-samples.git
cd adk-samples/python/agents/travel-concierge
poetry install
poetry run adk api_server travel_concierge
```

Confirm backend→ADK connectivity:

```bash
curl http://localhost:8080/adk/health
curl http://localhost:8080/adk/config
```

Run app with backend and open Settings → Concierge (ADK) to start a streaming session that renders train options and road‑trip summaries as cards.

## Localization

- Source ARB files live in `lib/src/l10n/*.arb`
- Generate localizations:

```bash
flutter gen-l10n
```

## Development & Testing

### Static analysis

```bash
flutter analyze
dart format --set-exit-if-changed .
```

### Unit & widget tests

```bash
flutter test
flutter test test/accessibility_baseline_test.dart
```

### Golden tests

```bash
flutter test --update-goldens test/goldens/   # refresh baselines when UI changes intentionally
flutter test test/goldens/
```

### Integration tests with Firebase emulators

```bash
firebase emulators:start --only auth,firestore
export FIREBASE_AUTH_EMULATOR_HOST=localhost:9099
export FIRESTORE_EMULATOR_HOST=localhost:8080
flutter test integration_test/
```

The emulator configuration lives in `firebase.json`; the UI dashboard (if enabled) runs on port 9090. For GitHub Actions, provide `FIREBASE_PROJECT_ID` and `FIREBASE_TOKEN` secrets so the workflow can deploy rules and run integration suites.

## Accessibility Expectations

Travel Wizards targets **WCAG 2.1 AA** compliance. Key checkpoints:

- Maintain contrast ratios ≥4.5:1 for body text and ≥3:1 for large text; high-contrast and dark themes stay in sync with design tokens.
- Apply meaningful semantics to all interactive controls (labels, hints, headings, live regions). `PlacesAutocompleteField` announces list changes; the trip planner stepper exposes progress labels.
- Guarantee keyboard reachability and focus order across screens; modals trap focus and show visible indicators.
- Respect text scaling (up to 200%), touch targets ≥48dp, and provide gesture alternatives for swipe actions.
- Run `test/accessibility_baseline_test.dart` alongside manual TalkBack/VoiceOver spot checks before releases.

## Push Notifications (FCM)

The app saves device/web FCM tokens to Firestore under `users/{uid}/fcmTokens`. If a backend is configured using `--dart-define BACKEND_BASE_URL=...` (or `STRIPE_BACKEND_URL`), the app will also best-effort POST the token to `{BASE_URL}/notifications/register` with JSON body:

```json
{ "token": "<fcm-token>", "platform": "android|ios|web" }
```

This enables your backend to send targeted push messages. Failures are ignored in dev; Firestore remains the source of truth.

### Firebase Functions Sender

If you prefer to keep notification sending inside Firebase, deploy the included callable function:

```bash
cd firebase/functions
npm install
npm run deploy -- --only functions:sendTargetedNotification
```

The callable `sendTargetedNotification` function lives in `firebase/functions/src/notifications/sendTargetedNotification.ts` and:

- Validates the caller has either the `admin` custom claim or the `notification-operator` role.
- Pulls FCM tokens from `users/{uid}/fcmTokens` and sends a multicast payload.
- Cleans up invalid tokens on delivery failures.

From trusted backend services you can invoke it using the Firebase Admin SDK or callable HTTPS endpoint. When calling directly via HTTPS, include a Firebase Auth ID token from a privileged service account user in the `Authorization: Bearer <token>` header.

## Firebase Firestore Indexes

If you use Firebase for Bookings/Tickets, deploy the composite indexes defined in `firestore.indexes.json`:

```bash
firebase login
firebase use <your-project-id>
firebase firestore:indexes -P <your-project-id> -R firestore.indexes.json
```

Alternatively, open the Firebase console when Firestore suggests an index for a failing query and accept the prompt.

## Firebase Security Rules

Deploy the security rules to restrict access to user-owned documents only:

```bash
firebase login
firebase use <your-project-id>
firebase deploy --only firestore:rules
```

The rules file is `firestore.rules` and enforces that `users/{uid}/**` documents are readable/writable only by that user, and collection group reads require `resource.data.uid == request.auth.uid`.

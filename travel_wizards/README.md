# Travel Wizards

Material 3 Flutter app for planning trips with an Explore ideas flow, localization, and a backend-enabled data source (optional).

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

Examples:

```bash
flutter run -d android \
  --dart-define=STRIPE_BACKEND_URL=http://10.0.2.2:8080 \
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_xxx \
  --dart-define=MOCK_PAYMENTS=true
```

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

## Development

Analyze and run tests:

```bash
flutter analyze && flutter test
```

## Push Notifications (FCM)

The app saves device/web FCM tokens to Firestore under `users/{uid}/fcmTokens`. If a backend is configured using `--dart-define BACKEND_BASE_URL=...` (or `STRIPE_BACKEND_URL`), the app will also best-effort POST the token to `{BASE_URL}/notifications/register` with JSON body:

```json
{ "token": "<fcm-token>", "platform": "android|ios|web" }
```

This enables your backend to send targeted push messages. Failures are ignored in dev; Firestore remains the source of truth. See the dummy FastAPI backend under `../backend` for a reference implementation of `/notifications/register`.

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

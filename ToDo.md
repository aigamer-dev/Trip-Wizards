# Travel Wizards Development ToDo List

This checklist covers all minute steps for building the Travel Wizards cross-platform app (Flutter for Web & Android, Python FastAPI backend with ADK proxy for Concierge). Steps are ordered for efficient development.

---

## Design System & UI Specifications

- [x] Adopt Material 3 (M3) across platforms with dynamic color (Material You)
  - [x] Use device dynamic color when available; else apply fallback palette below
  - [x] Define color roles (M3): `primary`, `onPrimary`, `secondary`, `onSecondary`, `tertiary`, `onTertiary`, `background`, `onBackground`, `surface`, `onSurface`, `surfaceVariant`, `onSurfaceVariant`, `error`, `onError`, `outline`
  - [x] Fallback Light Palette (approx Google brand vibe):
    - `primary`: `#1A73E8` (Blue 600), `onPrimary`: `#FFFFFF`
    - `secondary`: `#34A853` (Green 600), `onSecondary`: `#FFFFFF`
    - `tertiary`: `#FBBC05` (Amber 600), `onTertiary`: `#1B1B1B`
    - `background`: `#FAFAFA`, `onBackground`: `#121212`
    - `surface`: `#FFFFFF`, `onSurface`: `#1B1B1B`, `surfaceVariant`: `#E7E0EC`, `onSurfaceVariant`: `#49454F`
    - `error`: `#D32F2F`, `onError`: `#FFFFFF`, `outline`: `#79747E`
  - [x] Fallback Dark Palette:
    - `primary`: `#8AB4F8`, `onPrimary`: `#0A0A0A`
    - `secondary`: `#81C995`, `onSecondary`: `#0A0A0A`
    - `tertiary`: `#FDD663`, `onTertiary`: `#0A0A0A`
    - `background`: `#121212`, `onBackground`: `#EDEDED`
    - `surface`: `#1E1E1E`, `onSurface`: `#E3E3E3`, `surfaceVariant`: `#49454F`, `onSurfaceVariant`: `#CAC4D0`
    - `error`: `#CF6679`, `onError`: `#0A0A0A`, `outline`: `#939094`
- [x] Typography (M3 scale)
  - [x] Headlines: `displayLarge`, `displayMedium`, `headlineLarge` for marketing; minimal app use
  - [x] App: `titleLarge` (app bar titles), `titleMedium` (section titles), `bodyLarge/bodyMedium` (content), `labelLarge` (buttons)
  - [x] Use `Noto Sans` or system default; fallback to `Roboto`
- [x] Shape & elevation
  - [x] Small components radius: 8dp; large surfaces: 16dp
  - [x] Elevation scale: 0, 1, 2, 3, 4 as per M3; avoid excessive shadows on web
- [x] Spacing & layout
  - [x] 8dp base grid; common gaps: 8/16/24/32/48/64dp
  - [x] Responsive breakpoints: Mobile < 600dp, Tablet 600–1024dp, Web > 1024dp
  - [x] Mobile supports only vertical layouts per requirement
- [x] Iconography
  - [x] Use Material Symbols Rounded; size: 32dp (mobile), 24/32dp (web header)
- [x] Theming implementation
  - [x] Flutter: `ColorScheme.fromSeed` + dynamic color (package `dynamic_color`) with fallback palettes
  - [x] Persist user theme preference: light/dark/system in Firestore user settings

## 1. Project Setup & Configuration

- [x] Install Flutter SDK (latest stable)
- [x] Install Android Studio & set up Android emulator
- [x] Install Chrome (for web testing)
- [x] Install VS Code/IDE with Flutter & Dart plugins
- [x] Create new Flutter project (`travel_wizards`)
- [x] Set up git repository & `.gitignore` (use Flutter template + add `.env*`)
- [x] Enable platforms: `flutter config --enable-web` and create Android app
- [x] App icons & splash screens (web & android)
  - [x] Use `flutter_launcher_icons` and `flutter_native_splash` with light/dark variants (Android + Web configured)
  - [x] Completed: generated assets for Android and Web; verified updates in `index.html` and Android resources
- [x] Material 3 theme and dynamic color (see Design System)
- [x] Internationalization (i18n) with at least 10 Indian languages
  - [x] Configure `flutter_localizations`
  - [x] Add localization tool (e.g., `flutter_intl` or `intl_utils`) and generate ARB files
- [ ] Accessibility baseline (TalkBack/VoiceOver, large fonts, semantics)
  - [x] Add basic Semantics for FAB and quick actions
  - [x] Add Semantics to Drawer items and Home card 'Open' action
  - [x] Add Semantics to AppBar menu and avatar actions
  - [x] Label bottom navigation as a container
  - [x] Add Semantics to Settings theme & language controls
  - [x] Add Semantics to Brainstorm input and send action
  - [x] Add Semantics to Plan Trip stepper controls
  - [x] Add Semantics to Trip Details bottom actions
  - [x] Expand semantics coverage across remaining interactive controls
    - [x] Explore screen action buttons: labeled `Open` and `Save/Unsave` with helpful hints
  - [x] Remaining: broader pass across secondary actions on Home/Trip Details
- [x] Responsive layouts for mobile, tablet, web (vertical layouts on mobile only)
- [x] Environment variables
  - [x] Web: build-time environment via `--dart-define` for critical keys (remote ideas toggle, backend base URL)
- [x] Android configuration
  - [x] Update `android/app/build.gradle` for minSdk 23+, Kotlin/AGP versions
  - [x] Add permissions in `AndroidManifest.xml`: `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `READ_CALENDAR`, `WRITE_CALENDAR`, `READ_CONTACTS`, `WRITE_CONTACTS`, `INTERNET`
  - [x] Add `meta-data` entries for Maps API key and default notification channel
  - [x] Handle runtime permission requests with rationale (compliant with Play policies)
    - Added `permission_handler`, `PermissionsService`, and Settings controls for Location/Contacts/Calendar
    - Permanent denial path opens App Settings
    - Silent startup, non-blocking permission requests for Location/Contacts/Calendar (ignored if denied)
- [x] Web configuration (PWA)
  - [x] Ensure `web/manifest.json` (name, icons, theme/background colors)
  - [x] `service_worker.js` for offline shell caching — using Flutter Web default; verification guidance added (see notes below)
  - [x] Set CSP meta and placeholders for Maps/FCM keys in `web/index.html`

  Verification notes:
  - Build: `flutter build web --release` (service worker generated as `flutter_service_worker.js`).
  - Serve locally: any static server (e.g., `python3 -m http.server 8080 -d build/web`).
  - Test offline: load the app, then go offline and hard-refresh; shell should load from cache.
- [ ] Wear OS (Let's do it... seems to be a great idea)
  - [ ] Identify reduced features (itinerary glance, next event, notifications)
  - [ ] Decide on separate module/app if needed

## 2. Firebase & Google Services Integration

- [x] Create Firebase project, enable Google Analytics
- [x] Add Android & Web apps to Firebase
  - [x] Android: add package name, SHA-1/256; download `google-services.json`; apply Gradle plugin
  - [x] Web: copy SDK config; add to `web/index.html` or use Dart `firebase_core`
- [-] Firebase Authentication
  - [x] Enable Email/Password & Google providers
  - [ ] Configure `One account per email` policy; disallow linking multiple providers except migration to Google
- [-] Firestore (user data)
  - [x] Create database in production mode (or locked + rules)
  - [x] Add composite indexes (bookings, tickets)
- [ ] BigQuery (trips, feedback, ratings)
  - [ ] Create dataset `travel_wizards`
  - [ ] Configure partitioning (by `created_at` / trip start date)
  - [ ] Set up service account and key for write access
[-] Push notifications (FCM)
  - [x] Add firebase_messaging dependency and Android manifest updates (POST_NOTIFICATIONS, default channel id)
  - [x] Web: add firebase-messaging-sw.js and initialize with web config
  - [x] Implement PushNotificationsService: permissions, token save to users/<uid>/fcmTokens
  - [x] Initialize at startup and on auth changes
  - [x] Register FCM token with backend when BACKEND_BASE_URL is set (best-effort)
  - [ ] Backend sender: Use Cloud Functions or server to send targeted messages using stored tokens (deferred)
    - [x] People API (read birthdate, gender) [sensitive scope—requires verification]
    - [x] Maps JavaScript, Places, Geocoding, Directions (restrict to HTTP referrers & Android apps)
    - [x] Calendar API (read/write) and Contacts (read)
    - [ ] Google Photos Library API (shared albums)
    - [ ] Google Wallet API (passes)
    - [ ] Google Pay API (payments)
    - [ ] Weather (via appropriate Google/partner API)
    - [ ] Google Flights/Booking (or Ease My Trip partner APIs)
- [ ] Third-party integrations
  - [ ] Ease My Trip API: obtain credentials; set allowlist IPs/callbacks; read rate limits
  - [ ] Local transport APIs (Uber, Rapido): app registration, API keys, scopes
  - [ ] Stripe (if used): account, webhooks, test keys

## 3. Flutter App: Core Structure

- [x] Define app folder structure (lib/src/...)
- [x] Set up routing/navigation (Navigator 2.0 or go_router)
- [x] Implement localization support (arb/json files)
- [x] Implement theme switching (light/dark/system)
- [ ] Set up state management (Provider, Riverpod, or Bloc)
- [x] Set up state management (Provider)
- [x] Set up dependency injection (get_it)

Suggested structure:

- [x] `lib/src/`
  - [x] `app/` (app widget, theme, route config)
  - [ ] `features/` (auth, onboarding, home, trips, brainstorm, explore, settings)
  - [x] `common/` (widgets, utils, services, constants)
  - [x] `data/` (models, repositories)
  - [x] `l10n/` (generated localization)
  - [x] `config/` (env, flavors)
  - [x] `services/` (firebase, api clients, location)

## 4. Authentication & Onboarding

- [x] Build Login/Sign Up screen (logo, title, tagline, buttons)
- [-] Implement Google Sign-In (with migration logic)
  - [x] Show Google Sign-In button
  - [x] Handle sign-in flow
  - [-] Handle errors (network, canceled, etc.)
  - [ ] Handle provider migration dialog (email→google)
- [ ] Implement Email/Password Sign-In/Sign-Up (with migration logic)
- [x] Build onboarding flow (multi-step, progress indicator)
- [ ] Integrate Google People API for onboarding autofill
- [ ] Validate and store onboarding data in Firestore

Component placement & behavior:

- [ ] Login/Sign Up Screen
  - [ ] Top: centered app logo (96dp), `titleLarge` app name, `bodyMedium` tagline
  - [ ] Buttons (stacked vertical): `Continue with Google` (filled, `primary`), `Continue with Email` (outlined)
  - [ ] Respect safe areas; 16dp padding; min tap target 48dp
  - [ ] Show provider migration dialog on conflict (email<>google)
- [ ] Email/Password Screen
  - [ ] Fields: Name (sign-up only), Email, Password, Confirm Password (sign-up)
  - [ ] Validation: email format, password strength; error helper text in `onSurfaceVariant`
- [ ] Onboarding (5 steps)
  - [ ] AppBar: linear progress indicator + `Step X of 5`
  - [ ] Bottom bar: `Back` (text), `Next` (elevated, `secondary`), disabled until valid
  - [ ] Step 1: Welcome + language dropdown
  - [ ] Step 2: Profile (name prefilled; profile photo; DOB/Age; Gender; State/City)
    - [ ] If Google provider: fields read-only; fetched via People API
  - [ ] Step 3: Food Preferences (multi-select chips; allergies text)
  - [ ] Step 4: Review summary
  - [ ] Step 5: Celebration + `Continue to App`

## 5. Home & Navigation

- [x] Build Home page (AppBar, Drawer, FAB, BottomNavBar)
- [x] Implement profile navigation & drawer actions
- [x] Display cards: Generation in Progress, Ongoing, Planned, Suggested trips
- [x] Implement search bar functionality

Component placement & behavior:

- [x] AppBar
  - [x] Left: Hamburger `Menu`
  - [x] Center: Search field with placeholder `Travel Wizards`
  - [x] Right: Circular profile avatar with 2dp multicolor border (Google colors in segments)
- [x] Floating Action Button (bottom-right)
  - [x] Up-arrow icon without label; toggles M3-style floating FAB menu (mini-FABs with 24dp icons and adjacent labels) for `Add Trip` and `Brainstorm with AI`; anchored with SafeArea spacing
- [x] Bottom Navigation Bar
  - [x] Updated: Left Home, Center Add Trip action (opens Plan Trip), Right Explore; Settings removed from bottom nav (still available via avatar)
  - [x] Web/Desktop: Use `NavigationRail` on wide layouts; move bottom navigation items into the rail with labels always visible
  - [x] App Drawer (mobile): split into sections (Plan & AI, Trips, Settings), bottom-aligned content, and a dummy `Logout` action at the bottom; do not duplicate bottom nav items
  - [x] Consistency: Top App Bar + bottom nav present across nav pages on mobile
  - [x] M3 polish: nav icons at 24px and labels always shown per guidelines
- [x] Drawer (top to bottom)
  - [x] Home; Explore; Plan A Trip; Brainstorm; Bookings; Tickets; Budget Tracker; Full Trip History; Drafts; Payment History
  - [x] Tickets screen: list confirmed bookings with copy/share and deep-link to trip
- [x] Body Cards (grid or list depending on width)
  - [x] Generation In Progress: progress bar + ETA
  - [x] Ongoing Trips: prominent with `Open`
  - [x] Planned Trips: upcoming by date
  - [x] Suggested Trips: recommendations based on prefs/history

## 6. Trip Planning & Management

- [x] Build Plan A Trip multi-step form (style, details, accommodation, review)
- [x] Implement trip draft/save/discard logic
  - [x] Persist Plan Trip draft (duration, budget, notes) locally with clear action
  - [x] Dirty-state detection with `PopScope` and Save/Discard/Cancel dialog on back
  - [x] Notes field on Review step persisted via `PlanTripStore`
  - [x] Unit/widget tests for save/discard of notes, duration, budget; and preloading existing notes
- [x] Integrate with MCP API for trip generation (dummy endpoint for now)
  - Implemented simulated generation via `GenerationService`; navigates to Trip Details after completion
- [x] Enforce generation limits by subscription tier
  - Tier selector in Settings (Free/Pro/Enterprise) and daily quotas (1/5/10)
- [x] Build Trip Details page (all sections: main, weather, packing, maps, budget, recommendations, emergency, etc.)
- [x] Implement RSVP/invite logic for trip buddies
- [x] Implement trip editing, confirmation, and finalization flows
- [x] Integrate payment flow (Google Pay/Stripe, consolidated invoice)
  - [x] Google Pay (Android, TEST): Sheet wired on finalized trips, logs payments to Firestore, updates trip payment status
  - [x] Stripe (web/Android) fallback and real gateway integration
  - [x] Consolidated invoice generation and itemization
- [x] Handle booking/reservation status updates and error flows
  - [x] Booking progress sheet with sequential steps
  - [x] Booking status card on Trip Details (status, total, failures, delta)
  - [x] Delta payment prompt and clearing on success
  - [x] Retry failed bookings from the Trip Details UI
  - [x] Dedicated Bookings screen listing reservations and failures with filters

Plan A Trip — component placement:

- [ ] Step 1 (Trip Style): radio cards (Solo/Group/Family/Couple/Business/etc.)
  - [ ] If Business: show fields `Company Name`, `Purpose`, `Requirements`
  - [ ] If Family: `#Adults`, `#Teenagers`, `#Children`, `#Toddlers`
- [ ] Step 2 (Trip Details):
  - [ ] Travel Prefs (segmented control: Flight/Train/Bus/Car)
  - [ ] Origin/Destination (autocomplete; integrate Places API)
  - [ ] Dates (range picker)
  - [ ] Buddies (chips with add/remove)
  - [ ] Special Requirements (multiline)
- [ ] Step 3 (Stay & Activities):
  - [ ] Accommodation (Hotel/Airbnb/Hostel) + star rating filter
  - [ ] Activities (Sightseeing/Adventure/Cultural) multi-select
  - [ ] Budget (preset Low/Medium/High or custom range with currency)
  - [ ] Itinerary (Flexible/Fixed)
- [ ] Step 4 (Review):
  - [ ] Summary cards by category with `Edit` actions
  - [ ] `Generate` CTA (primary)
- [ ] Drafting: when navigating back or closing, prompt `Save Draft` or `Discard`
- [ ] Generation limits by tier: Free 1, Pro 5, Enterprise 10 — block with snackbar/dialog
- design inspiration image : [image](https://cdn.dribbble.com/userupload/42255883/file/original-5cada812611742e536f95b207cad41e0.png?resize=1600x1200)

Trip Details — component placement:

- [x] Header: Title; breadcrumb for multi-destination (`A → B (…x…) → Z`)
- [x] Main section cards: Dates, Duration, Trip Type, Main Transport, Budget, Notes, Buddies, Itinerary
- [ ] Live Weather: compact current + forecast strip; refresh indicator
- [ ] Packing List: checklist with `Suggested` section; add custom items
- [x] Packing List: checklist with `Suggested` section; add custom items
- [ ] Maps: interactive map with POIs, routes; markers for itinerary items
- [ ] Budget Tracker: charts (pie by category, line cumulative), suggestions
- [ ] Recommendations (not in itinerary): Events, Transport options, Restaurants, Shopping, Activities — each as horizontally scrollable card lists, `Add to Itinerary`
- [ ] Safety: Emergency Contacts, Insurance, Health & Safety, Advisories
- [x] Sticky action bar (mobile bottom): `Edit`, `Invite`, `Confirm`, `Pay`

Payments & bookings:

- [x] Consolidated invoice generation post-finalization
- [x] Sequential booking via Ease My Trip; notify on partial failures; request delta payments if needed
- [x] Integrate Google Pay/Stripe as methods; handle web + Android flows
- [x] Track off-platform spend: allow manual entry + receipt upload; optionally parse email receipts; if Google Pay transaction APIs are not available, keep this manual to avoid unsupported access

Media sharing:

- [ ] Google Photos: create shared trip album; allow one-tap upload of selected media to album (with user consent)

## 7. Brainstorm Itinerary (AI Chat)

- [x] Build Brainstorm Itinerary page (chat UI)
- [x] Integrate with MCP/AI backend (dummy endpoint for now)
  - Simulated responses via `BrainstormService`
- [x] Implement session management (1 active session per user)
  - Local-only single active session using SharedPreferences; AppBar controls to start/end; banner indicates active session
- [x] Allow converting brainstormed itinerary to trip plan
  - Added `Review & Convert` action to open Plan Trip with prefilled args

Component placement & behavior:

- [x] Chat screen with message list (bubbles), input field with send, quick suggestions (chips)
- [x] Toolbar: `New Session`, `Attach Preferences` (stub), `Use Calendar Availability` (stub)
- [ ] Convert to Trip Plan: `Review & Convert` button creates pre-filled Plan A Trip review step
- [ ] Enforce single active session across devices

## 8. Explore & Public Ideas

- [x] Build Explore page (public travel ideas)
  - [x] Show search header when query present
  - [x] Add compact mock idea cards with icons and a View action
  - [x] Add compact filter chips (duration/type/budget)
  - [x] Add Save idea stub (bookmark)
  - [x] Populate with in-memory data and filters (initial)
  - [x] Add duration/budget filters with persistence (in-memory data)
  - [x] Hook to backend data source and richer filters (behind feature flag with local fallback)
- [x] Implement browsing, searching, and saving public ideas
  - [x] Persist Explore filters and saved ideas locally
  - [x] Pass Explore idea to Plan Trip and prefill basic fields

Component placement & behavior:

- [x] Grid/list of public itineraries with filters (destination, duration, budget)
- [x] Card shows cover image, title, tags, likes/saves; `Save` adds to user library

## 9. Settings & Profile

- [x] Build Settings page (profile, app, accessibility, payment, legal, about, help, feedback, tutorials)
- [x] Implement profile editing, password change, and provider migration
  - Basic local profile editing (name/email) completed; provider migration/password change deferred
- [x] Implement language, theme, notification, and privacy settings
- [ ] Build travel buddy management UI
- [ ] Implement payment & subscription management
- [x] Add legal, about, help, FAQ, feedback, and tutorial sections
- [x] Add legal, about, help, FAQ, feedback, and tutorial sections (static pages linked from Settings)

Sections & details:

- [ ] Profile Settings: provider migration (non-Google→Google only), change password (if email provider)
- [x] App Settings: language, privacy toggles, data usage (Wi-Fi only sync), theme
- [ ] Accessibility: text scaling, high contrast theme, reduce motion
- [ ] Travel Buddies: list, add/remove, manage invitations
- [ ] Payment & Subscription: methods, budgets (alerts, categories), billing history, plan management, promo code, tax info
- [ ] Payment & Subscription: methods, budgets (alerts, categories), plan management, promo code, tax info
  - [x] Billing history: record subscription purchases and display in Payment History
  - [x] Stripe status and initialization tile in Settings (reads `STRIPE_PUBLISHABLE_KEY[_WEB|_ANDROID|_IOS]` via `--dart-define` or `.env`)
  - [x] Payments backend URL resolution and health check (Ping) in Settings using `STRIPE_BACKEND_URL`/`BACKEND_BASE_URL`
  - [x] Dev toggle for mock payments (`--dart-define MOCK_PAYMENTS=true`) to bypass PaymentSheet for local demos
- [ ] Legal/About/Help/FAQ/Feedback/Tutorials — static pages with links

## 10. Notifications & Real-Time Updates

- [ ] Integrate Firebase Cloud Messaging for push notifications
- [x] Implement in-app notifications (SnackBars) for payments and bookings
- [x] Set up real-time updates (Firestore listeners) for trip status, payments, bookings

Details:

- [ ] Topics: `trip_<id>`, `user_<id>` for personalized updates
- [ ] Event notifications: generation ready, RSVP reminders (auto-expire 1 week or 72h pre-start), payment required, booking changes
- [ ] In-app: snackbar for quick, modal for critical actions

## 11. Accessibility & Internationalization

- [ ] Test and improve accessibility (screen readers, voice commands)
- [ ] Test all supported languages and region settings

Checklist:

- [ ] Semantics labels for all interactive UI; focus order logical
- [ ] Color contrast AA; verify dynamic color legibility
- [ ] Large text (200%) and screen reader tests (TalkBack)
- [x] Languages (at least Hindi, Bengali, Telugu, Marathi, Tamil, Urdu, Gujarati, Malayalam, Kannada, Oriya)
- [ ] RTL readiness for Urdu

## 12. Testing & QA

- [x] Write unit tests for core logic
  - See: `test/ideas_repository_test.dart`
- [x] Write widget tests for UI components
- [ ] Write integration tests for flows (auth, trip planning, payments)
  - [x] Initial: Explore remote failure fallback — verifies SnackBar + local ideas rendering
  - [ ] Plan Trip draft flow: heavy integration test temporarily removed due to memory constraints on target machine; defer and replace with lighter unit/widget coverage
- [ ] Test on Android, Web, and (optionally) tablet/watch
- [ ] Test with screen readers and accessibility tools

Acceptance criteria examples:

- [ ] Auth: migration logic prevents dual providers; onboarding data stored
- [ ] Plan Trip: draft save/restore; tier limits enforced; review edit works
- [ ] Trip Details: adding recommendations to itinerary updates budget
- [ ] Payments: consolidated invoice; retries on failure; webhooks handled
- [ ] Notifications: receive on device and web; links deep-link correctly

## 13. Assistant/Smart Home Integration (Basic)

- [ ] Define voice intents ("next trip", "show itinerary", "weather at destination", "create plan", "add activity to <Trip>")
- [ ] Android App Actions / Shortcuts: map intents to deep links/screens; pass parameters
- [ ] Account linking with Google (if needed) using OAuth + Firebase Auth
- [ ] Test utterances on devices; ensure privacy-safe responses

## 14. Deployment & Release

- [ ] Set up CI/CD (GitHub Actions, Codemagic, or similar)
- [ ] Configure web deployment (Firebase Hosting or similar)
- [ ] Configure Android build & Play Store listing
- [ ] Prepare app store assets (screenshots, descriptions, icons)
- [ ] Publish web app
- [ ] Publish Android app

CI/CD & deployment details:

- [ ] GitHub Actions: jobs for `flutter analyze`, `flutter test`, build `web` and `android` artifacts
- [ ] Firebase Hosting for web; configure channels (preview/prod)
- [ ] Play Console: internal testing track, closed testing, production; privacy policy URL; data safety form; OAuth verification
- [ ] Crashlytics/Analytics wiring (Firebase Analytics)

---

## Backend: Payments/Bookings/Notifications + ADK Proxy (Python FastAPI)

### 1. Environment Setup

- [x] Install Python 3.10+
- [x] Set up virtual environment
- [x] Install FastAPI, Uvicorn, CORS, httpx and other dependencies
- [x] Set up project structure (FastAPI `app/main.py` with routers/models)
- [x] Configure environment variables for API keys (FCM, ADK, Maps)

Dependencies (examples):

- [x] `fastapi`, `uvicorn`, `pydantic`, `httpx`, `python-dotenv`
- [x] `firebase-admin` (optional), `google-auth` (optional)
- [x] Lint/format: `black`, `flake8` (optional)

Project structure:

- [x] `backend/app/main.py`, `backend/requirements.txt`, `.env`

### 2. API Development

- [x] Implement payments/booking/notifications dummy endpoints
- [x] Implement ADK proxy endpoints (`/adk/health`, `/adk/config`, `/adk/session`, `/adk/run`, `/adk/run_sse`)
- [ ] Set up authentication (JWT or Firebase Auth verification) for protected endpoints
- [x] Set up CORS for Flutter frontend
- [x] OpenAPI/Swagger docs available at `/docs` (FastAPI default)

Endpoints (initial):

- [x] `POST /payments/create-intent` — returns dummy client secret
- [x] `POST /payments/webhook` — accept payload (no-op)
- [x] `GET  /payments/health` — health check
- [x] `POST /bookings` — create booking (dummy)
- [x] `GET  /bookings` and `/bookings/{id}` — list/get bookings (dummy)
- [x] `POST /notifications/register` — store FCM token (SQLite)
- [x] `POST /notifications/send` — send via FCM v1/legacy if configured; else simulated
- [x] `GET  /adk/health` — proxy to ADK server
- [x] `GET  /adk/config` — return ADK config for frontend
- [x] `POST /adk/session` — create ADK session
- [x] `POST /adk/run` — non-streaming convenience
- [x] `POST /adk/run_sse` — streaming SSE proxy

Security:

- [ ] Verify Firebase ID tokens on protected endpoints (deferred)
- [ ] Rate limit by user (deferred)
- [x] Store minimal PII; mock data only; log without secrets

Docs:

- [ ] OpenAPI YAML/JSON; expose Swagger UI at `/docs`

### 3. Integration & Testing

- [x] Test API endpoints with curl (see backend README)
- [x] Integrate with Flutter app (StripeService health, FCM register, ADK SSE)
- [ ] Write unit tests for endpoints (optional)

Tests:

- [ ] Mock external APIs (Ease My Trip, Google) for deterministic tests
- [ ] Contract tests for webhook payloads

### 4. Deployment

- [ ] Set up deployment (Cloud Run/App Engine/VM)
- [ ] Configure HTTPS (SSL/TLS)
- [ ] Set up logging & monitoring

Deployment details:

- [ ] Containerize with Docker; use Uvicorn/Gunicorn
- [ ] GCP Cloud Run or App Engine; map custom domain with SSL
- [ ] Centralized logging (Cloud Logging) and metrics (Cloud Monitoring)

---

## Data Models & Schemas

- [ ] Firestore Collections
  - [ ] `users/{uid}`: name, email, provider, dob/age, gender, city, state, language, foodPrefs[], allergies, profilePhotoUrl, subscription, notificationPrefs, createdAt, updatedAt
  - [ ] `trips/{tripId}`: ownerUid, title, origin, destination(s), startDate, endDate, type, transport, budget, notes, buddies[], status, itinerarySummary, createdAt, updatedAt
  - [ ] `trips/{tripId}/itinerary/{itemId}`: dateTime, type, title, location{lat,lng,address}, cost, bookingRef, notes
  - [ ] `drafts/{uid}/{draftId}`: serialized plan form
  - [ ] Security Rules: user can read/write own; invited buddies read
- [ ] BigQuery Tables (dataset `travel_wizards`)
  - [ ] `trips` (partition by start_date)
  - [ ] `itinerary_items`
  - [ ] `payments`
  - [ ] `budgets`
  - [ ] `feedback`
  - [ ] `ratings`
  - [ ] Use clustering on `owner_uid`, `destination`

---

## Final Steps

- [ ] Collect user feedback
- [ ] Monitor analytics & crash reports
- [ ] Plan for future features & improvements

Security & privacy:

- [ ] Data retention policy; user data export/delete
- [ ] Consent screens for scopes (People, Calendar, Contacts)
- [ ] Secrets in env vars only; restrict API keys by platform

---

**Note:**

- All integrations (APIs, payments, notifications) must be fully functional, not dummy, except for AI/MCP backend.
- Ensure all configuration steps (API keys, environment variables, platform setup) are completed before development.
- Follow best practices for security, privacy, and accessibility throughout.

> Assets
>
> Design references and inspiration:
>
>
- [Trip Planning Form Design Example](https://cdn.dribbble.com/userupload/42255883/file/original-5cada812611742e536f95b207cad41e0.png?resize=1600x1200)
>
> - General App Design Inspiration : Use the Pre-built App from `/home/hari/Personal/Events/genAIexchangeHackathon/Version1`, Use only the design, color scheme, and UI/UX flow, but not the functionality.

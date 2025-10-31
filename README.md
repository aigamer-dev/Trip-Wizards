# Travel Wizards - AI-Powered Trip Planning App

A comprehensive Flutter application for AI-powered travel planning with real-time collaboration, offline support, emergency assistance, and advanced trip management features.

While AI assists throughout the experience, the core of Travel Wizards stays focused on dependable trip orchestration, with the assistant acting as an enhancer rather than the main interface.

## 🌟 Features

### Core Travel Planning

- **AI-Powered Trip Planning**: Intelligent destination recommendations and itinerary generation
- **Real-time Collaboration**: Multi-user trip planning with role-based permissions
- **Offline Support**: Full offline functionality with automatic sync
- **Emergency Assistance**: SOS features with emergency contact management
- **Enhanced Maps Integration**: Advanced Google Maps integration with trip visualization
- **Multi-language Support**: 50+ languages with Google Translate integration
- **Trip Sharing**: Multiple sharing methods including QR codes and shareable links

### Advanced Features

- **Trip Execution**: Real-time trip tracking with check-in/check-out system
- **Notifications**: Firebase Cloud Messaging for real-time updates
- **Payment Integration**: Stripe and Google Pay support
- **Performance Optimization**: Advanced caching and performance monitoring
- **Material 3 Design**: Modern UI with comprehensive theming

### Wear OS Companion Experience

- **Itinerary Glance Tile**: Lightweight tile surfaces the next upcoming trip segment, gate info, and countdown at a glance.
- **Actionable Notifications**: Mirrored push notifications provide quick actions for check-in, share ETA, or acknowledge alerts directly from the watch.
- **Trip Progress Peek**: Swipeable card lists current day agenda and travel checklist items optimized for the circular UI.
- **Offline Snapshot**: Automatically syncs the next 24 hours of itinerary details when the watch reconnects, keeping essentials available without the phone.
- **Implementation Plan**: Deliver as a dedicated Flutter module (`wear_companion/`) that shares core services via a federated package while keeping the phone app as the primary hub.

## 🚀 Quick Start

### Prerequisites

- Flutter SDK (3.24.0 or later)
- Dart SDK (3.5.0 or later)
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/aigamer-dev/Trip-Wizards.git
   cd Trip-Wizards
   cd travel_wizards
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Set up environment variables**

   ```bash
   cp ../.env.template ../.env
   # Edit .env file with your actual credentials
   ```

4. **Configure Firebase** (See [Firebase Setup](#firebase-setup))

5. **Configure Google Services** (See [Google Services Setup](#google-services-setup))

6. **Run the app**

  ```bash
  flutter run
  ```

## 📦 Deployment

This section contains the minimal steps and artifact locations to publish or test the Travel Wizards app (web + Android). It intentionally contains no secrets — store keys in CI secrets or local `.env` files as described below.

### Artifacts (already produced)

- Web release bundle: `travel_wizards/build/web`
- Android debug APK: `travel_wizards/build/app/outputs/flutter-apk/app-debug.apk`

If you need a release APK / AAB, run the production build steps described below.

### Quick local checks

#### Serve web artifact locally

```bash
# from repo root
python3 -m http.server 8080 -d travel_wizards/build/web
# then open http://localhost:8080
```

#### Install Android debug APK on device/emulator

```bash
# from repo root
adb install -r travel_wizards/build/app/outputs/flutter-apk/app-debug.apk
```

#### Run app in debug mode

```bash
cd travel_wizards
flutter run
```

### Production Android (AAB) build

1. Ensure keystore and signing config available locally or in CI. Add keystore to `android/app` or configure CI secrets (`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEYSTORE_ALIAS`, `ANDROID_KEYSTORE_ALIAS_PASSWORD`).
2. Build AAB:

  ```bash
  cd travel_wizards
  flutter build appbundle --release -t lib/main.dart
  ```

1. Upload AAB to Google Play Console (internal testing first). Fill Play Store listing, upload screenshots and privacy policy URL.

### Production Web deployment (Firebase Hosting)

1. Install Firebase CLI and log in:

```bash
npm install -g firebase-tools
firebase login
```

2. Deploy to preview channel or production:

  ```bash
  cd travel_wizards
  # preview channel
  firebase hosting:channel:deploy preview --only hosting
  # or production
  firebase deploy --only hosting
  ```

> Note: keep `firebase.json` and hosting config updated. For first-time deploy, run `firebase init hosting` and follow prompts.

### CI secrets (add these to GitHub Actions repository secrets)

- FIREBASE_TOKEN — token for `firebase deploy` (or set up GH Firebase action with service account)
- ANDROID_KEYSTORE_BASE64 — base64-encoded keystore for signing releases (or use Google Play App Signing)
- ANDROID_KEYSTORE_PASSWORD
- ANDROID_KEY_ALIAS
- ANDROID_KEY_ALIAS_PASSWORD
- BACKEND_BASE_URL — URL for backend (if any) used by the app in CI builds

Do NOT commit any secrets or service account keys to source control.

### Tests and verification

- Run unit & widget tests locally:

```bash
cd travel_wizards
flutter test
```

- Run static analysis:

```bash
flutter analyze
```

- Golden tests: ensure the `test/goldens/` baselines are present and updated only intentionally. CI will run golden comparisons.

### Notes & troubleshooting

- Web build warnings about WASM compatibility for some JS-interop packages are informational; they don't block normal web deployment to modern browsers.
- If Firebase Hosting deploy fails due to missing config, double-check `travel_wizards/lib/firebase_options.dart` and `travel_wizards/web/index.html` placeholders.
- For Play Console privacy & sensitive scope verification (People API), ensure your OAuth consent screen is configured before requesting sensitive scopes in production.

## 🔧 Configuration

### Firebase Setup

1. **Create Firebase Project**

   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project or use existing one
   - Enable Authentication, Firestore, Storage, and Cloud Messaging

2. **Download Configuration Files**

   - **Android**: Download `google-services.json`

     ```bash
     # Place in: travel_wizards/android/app/google-services.json OR
     cp travel_wizards/android/app/google-services.template.json travel_wizards/android/app/google-services.json
     # Edit with your actual configuration
     ```

   - **Web**: Get Firebase config object

     ```bash
     # Edit web files with your Firebase configuration
     cp travel_wizards/web/index.template.html travel_wizards/web/index.html
     cp travel_wizards/web/firebase-messaging-sw.template.js travel_wizards/web/firebase-messaging-sw.js
     # Replace placeholders with your actual Firebase config
     ```

3. **Configure Firebase Options**

   ```bash
   cp travel_wizards/lib/firebase_options.template.dart travel_wizards/lib/firebase_options.dart
   # Edit with your Firebase configuration
   ```

4. **Update .env file**

   ```env
   FIREBASE_PROJECT_ID=your-project-id
   FIREBASE_WEB_API_KEY=your-web-api-key
   FIREBASE_ANDROID_API_KEY=your-android-api-key
   FIREBASE_MESSAGING_SENDER_ID=your-sender-id
   FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
   FIREBASE_STORAGE_BUCKET=your-project.firebasestorage.app
   FIREBASE_WEB_APP_ID=your-web-app-id
   FIREBASE_ANDROID_APP_ID=your-android-app-id
   ```

### Google Services Setup

1. **Google Maps API**

   - Enable Maps SDK for Android/iOS in Google Cloud Console
   - Create API key and restrict to your app
   - Update `.env`:

     ```env
     GOOGLE_MAPS_API_KEY=your-maps-api-key
     GOOGLE_MAPS_WEB_API_KEY=your-web-maps-api-key
     ```

   - Update Android strings:

     ```bash
     cp travel_wizards/android/app/src/main/res/values/strings.template.xml travel_wizards/android/app/src/main/res/values/strings.xml
     # Replace YOUR_GOOGLE_MAPS_API_KEY with your actual key
     ```

   - Update web index.html:

     ```bash
     # In travel_wizards/web/index.html, replace YOUR_GOOGLE_MAPS_API_KEY
     ```

### Places Autocomplete — Manual Test Checklist

Use this checklist to manually verify the Places Autocomplete feature on emulator or physical device. Do not commit API keys to source control.

1. Create a Google Cloud API key

- In Google Cloud Console, enable the following APIs:
  - Places API
  - Maps JavaScript API (for web)
  - Maps SDK for Android (if using Android)
- Create an API key and restrict it to the required APIs.

2. Restrict the API key for safety

- For Android: Restrict by package name and SHA-1 (recommended for production).
- For Web: Restrict by HTTP referrers (your hosting domain or `localhost` for dev).
- Keep a separate unrestricted dev key only if absolutely necessary and never commit it.

3. Provide the key to the app for local testing

- Preferred (safe): use `--dart-define` at build/run time:

    ```bash
    # Web (dev):
    flutter run -d chrome --dart-define=PLACES_API_KEY=YOUR_KEY

    # Android (debug):
    flutter run -d emulator-5554 --dart-define=PLACES_API_KEY=YOUR_KEY

    # Build web release with key:
    flutter build web --dart-define=PLACES_API_KEY=YOUR_KEY
    ```

- Or set environment variables and load them in `lib/main.dart` (local dev only).
- Do NOT commit keys into source files.

4. Android manifest (optional local debug)

- For native plugins that read `strings.xml`, you can add the key to `android/app/src/main/res/values/strings.xml` in your local copy (do not commit) and reference it in the manifest.

5. Test on emulator/device

- Launch the app and open a screen with the Places Autocomplete input.
- Type a place name (e.g., "Mumbai" or "MG Road") and confirm suggestions appear.
- Tap a suggestion — verify the returned place has useful fields (place_id, name, lat/lng, formatted address).
- Verify the app gracefully handles:
  - No network (shows an inline message)
  - API quota exceeded / invalid key (user-facing error and a log entry)
  - Permission denied (location-based suggestions require location permission — handle gracefully)

6. Web checks

- If testing web, ensure Maps JS is loaded with the same key and the referrer restriction allows localhost or your test domain.
- Test CORS and ensure JS console has no API key errors.

7. Verification steps

- Verify that suggestions match expected region biasing (if configured).
- Confirm lat/lng accuracy by opening the place marker on the map view (if present).
- Confirm autocomplete latency is acceptable (<300ms median on local network) and that debouncing is applied while typing.

8. Security & compliance notes

- For production, restrict keys by platform and rotate keys if you suspect compromise.
- For People API or additional sensitive scopes, ensure OAuth consent verification is completed before requesting scopes at scale.

9. Troubleshooting

- Common errors: `API key not authorized`, `RefererNotAllowedMapError`, `REQUEST_DENIED` — check key restrictions and enabled APIs.
- If the emulator can't reach Google APIs, test with a physical device on the same network or check emulator network settings.

---

This checklist is intentionally conservative for the hackathon—prefer sandboxing and mocked services for automated tests; run manual checks with real keys on a private dev environment only.

2. **Google Translate API**

   - Enable Cloud Translation API in Google Cloud Console
   - Create service account and download JSON key OR use API key
   - Update `.env`:

     ```env
     GOOGLE_TRANSLATE_API_KEY=your-translate-api-key
     ```

### BigQuery Setup

The app streams analytics and trip-feedback events into a time-partitioned BigQuery table. Provision the dataset and service account with the included automation script (requires the Google Cloud SDK):

```bash
cd travel_wizards/scripts/data
./setup_bigquery.sh -p <your-gcp-project> --key-output ~/.config/travel_wizards/bq-writer.json
```

The script performs the following:

- Creates (or reuses) the `travel_wizards` dataset in the chosen region (`us-central1` by default).
- Provisions a partitioned `trip_events` table using `created_at` as the partition key with schema defined in `scripts/data/schemas/trip_events_schema.json`.
- Creates a dedicated service account (`travel-wizards-bq-writer`) with `roles/bigquery.dataEditor` and `roles/bigquery.jobUser` permissions.
- Optionally generates a JSON key (store securely outside of version control; the example above writes to `~/.config/travel_wizards/bq-writer.json`).

After generating a key, expose it to the app via environment configuration (for example `BIGQUERY_SERVICE_ACCOUNT_KEY_PATH`) so the backend ingestion layer can authenticate when writing analytics batches.

### Payment Setup (Stripe)

1. **Stripe Configuration**
   - Create Stripe account at [stripe.com](https://stripe.com)
   - Get publishable and secret keys from Dashboard > Developers > API keys
   - Update `.env`:

     ```env
     STRIPE_PUBLISHABLE_KEY=pk_test_your-publishable-key
     STRIPE_SECRET_KEY=sk_test_your-secret-key
     ```

### Environment Variables

Copy `.env.template` to `.env` and configure all required variables:

```env
# Firebase Configuration
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_STORAGE_BUCKET=your-firebase-project-id.firebasestorage.app
FIREBASE_MESSAGING_SENDER_ID=your-messaging-sender-id
FIREBASE_AUTH_DOMAIN=your-firebase-project-id.firebaseapp.com

# Firebase Platform-Specific Keys
FIREBASE_WEB_API_KEY=your-web-api-key
FIREBASE_WEB_APP_ID=your-web-app-id
FIREBASE_MEASUREMENT_ID=your-measurement-id
FIREBASE_ANDROID_API_KEY=your-android-api-key
FIREBASE_ANDROID_APP_ID=your-android-app-id

# Google Services
GOOGLE_MAPS_API_KEY=your-google-maps-api-key
GOOGLE_MAPS_WEB_API_KEY=your-google-maps-web-api-key
GOOGLE_TRANSLATE_API_KEY=your-google-translate-api-key

# Payment Processing
STRIPE_PUBLISHABLE_KEY=pk_test_your-stripe-publishable-key
STRIPE_SECRET_KEY=sk_test_your-stripe-secret-key

# Development Settings
DEBUG_MODE=true
LOG_LEVEL=debug

# Optional External APIs
WEATHER_API_KEY=your-weather-api-key
PLACES_API_KEY=your-places-api-key
```

## 🏗️ Project Structure

```tree
travel_wizards/
├── lib/
│   ├── src/
│   │   ├── data/              # Data controllers and state management
│   │   ├── models/            # Data models and entities
│   │   ├── screens/           # UI screens and pages
│   │   ├── services/          # Business logic and external APIs
│   │   ├── widgets/           # Reusable UI components
│   │   ├── routing/           # Navigation and routing
│   │   └── common/            # Shared utilities and constants
│   ├── firebase_options.dart  # Firebase configuration (create from template)
│   └── main.dart             # App entry point
├── android/                   # Android platform code
├── ios/                      # iOS platform code  
├── web/                      # Web platform code
├── assets/                   # App assets (images, fonts, etc.)
└── test/                     # Tests
```

## 🔒 Security Configuration

### Files to Configure (DO NOT COMMIT THESE)

The following files contain sensitive information and should be created from their templates:

1. **`.env`** - Environment variables (root directory)
2. **`travel_wizards/lib/firebase_options.dart`** - Firebase configuration
3. **`travel_wizards/android/app/google-services.json`** - Android Firebase config
4. **`travel_wizards/android/app/src/main/res/values/strings.xml`** - Android Maps API key
5. **`travel_wizards/web/index.html`** - Web Firebase config and Maps API key
6. **`travel_wizards/web/firebase-messaging-sw.js`** - Web Firebase messaging

### Template Files (Safe to Commit)

Template files are provided for all sensitive configurations:

- `.env.template`
- `travel_wizards/lib/firebase_options.template.dart`
- `travel_wizards/android/app/google-services.template.json`
- `travel_wizards/android/app/src/main/res/values/strings.template.xml`
- `travel_wizards/web/index.template.html`
- `travel_wizards/web/firebase-messaging-sw.template.js`

### Firebase Security Rules

Configure Firestore security rules in Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Trip access based on collaboration rules
    match /trips/{tripId} {
      allow read, write: if request.auth != null && 
        (resource.data.createdBy == request.auth.uid ||
         request.auth.uid in resource.data.collaborators);
    }
    
    // Emergency contacts - user-specific
    match /emergency_contacts/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage
```

## 🔨 Building

### Development Build

```bash
flutter run --debug
```

### Production Build

**Android APK:**

```bash
flutter build apk --release
```

**Android App Bundle:**

```bash
flutter build appbundle --release
```

**Web:**

```bash
flutter build web --release
```

### Build with Environment Variables

```bash
flutter build apk --release \
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_live_xxx \
  --dart-define=FIREBASE_PROJECT_ID=production-project \
  --dart-define=GOOGLE_MAPS_API_KEY=production-maps-key
```

## 🚀 Deployment

### Firebase Hosting (Web)

```bash
npm install -g firebase-tools
firebase login
firebase init hosting
flutter build web --release
firebase deploy
```

### Google Play Store (Android)

1. Create signed AAB: `flutter build appbundle --release`
2. Upload to Google Play Console
3. Configure store listing and metadata

### App Store (iOS)

1. Build in Xcode with release configuration
2. Archive and upload to App Store Connect
3. Configure app metadata and submit for review

## 🆘 Troubleshooting

### Common Issues

**Build Errors:**

- Ensure all environment variables are set in `.env`
- Check Flutter doctor: `flutter doctor`
- Clean and rebuild: `flutter clean && flutter pub get`

**Firebase Issues:**

- Verify configuration files are in correct locations
- Check Firebase project settings match your `.env` values
- Ensure all required services are enabled in Firebase Console

**Maps Not Loading:**

- Verify Google Maps API key is correct and unrestricted for development
- Check API key restrictions in Google Cloud Console for production
- Ensure Maps SDK is enabled for your platform

**Permission Errors:**

- Check Android permissions in `android/app/src/main/AndroidManifest.xml`
- Verify iOS permissions in `ios/Runner/Info.plist`

### Getting Help

- Create an issue on GitHub with detailed error information
- Check existing issues for solutions
- Review Flutter and Firebase documentation

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## 📊 Performance Features

The app includes comprehensive performance monitoring:

- Widget caching for improved rendering
- Image optimization and lazy loading
- Efficient state management with proper disposal
- Network request optimization and caching
- Memory usage monitoring and optimization

---

### Built with ❤️ using Flutter

For questions or support, please create an issue on GitHub.

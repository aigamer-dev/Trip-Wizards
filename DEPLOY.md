# Deployment & Release Quick Guide

This file summarizes the minimal steps and artifact locations to publish or test the Travel Wizards app (web + Android). It intentionally contains no secrets — store keys in CI secrets or local `.env` files as described below.

## Artifacts (already produced)
- Web release bundle: `travel_wizards/build/web`
- Android debug APK: `travel_wizards/build/app/outputs/flutter-apk/app-debug.apk`

If you need a release APK / AAB, run the production build steps described below.

## Quick local checks

### Serve web artifact locally

```bash
# from repo root
python3 -m http.server 8080 -d travel_wizards/build/web
# then open http://localhost:8080
```

### Install Android debug APK on device/emulator

```bash
# from repo root
adb install -r travel_wizards/build/app/outputs/flutter-apk/app-debug.apk
```

### Run app in debug mode

```bash
cd travel_wizards
flutter run
```

## Production Android (AAB) build

1. Ensure keystore and signing config available locally or in CI. Add keystore to `android/app` or configure CI secrets (`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEYSTORE_ALIAS`, `ANDROID_KEYSTORE_ALIAS_PASSWORD`).
2. Build AAB:

```bash
cd travel_wizards
flutter build appbundle --release -t lib/main.dart
```

3. Upload AAB to Google Play Console (internal testing first). Fill Play Store listing, upload screenshots and privacy policy URL.

## Production Web deployment (Firebase Hosting)

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

## CI secrets (add these to GitHub Actions repository secrets)
- FIREBASE_TOKEN — token for `firebase deploy` (or set up GH Firebase action with service account)
- ANDROID_KEYSTORE_BASE64 — base64-encoded keystore for signing releases (or use Google Play App Signing)
- ANDROID_KEYSTORE_PASSWORD
- ANDROID_KEY_ALIAS
- ANDROID_KEY_ALIAS_PASSWORD
- BACKEND_BASE_URL — URL for backend (if any) used by the app in CI builds

Do NOT commit any secrets or service account keys to source control.

## Tests and verification
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

## Notes & troubleshooting
- Web build warnings about WASM compatibility for some JS-interop packages are informational; they don't block normal web deployment to modern browsers.
- If Firebase Hosting deploy fails due to missing config, double-check `travel_wizards/lib/firebase_options.dart` and `travel_wizards/web/index.html` placeholders.
- For Play Console privacy & sensitive scope verification (People API), ensure your OAuth consent screen is configured before requesting sensitive scopes in production.

---

Created as a quick reference to get artifacts deployed and to document CI secrets needed for release flows.

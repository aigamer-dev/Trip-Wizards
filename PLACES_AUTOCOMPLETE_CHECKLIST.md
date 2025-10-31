# Places Autocomplete — Manual Test Checklist

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

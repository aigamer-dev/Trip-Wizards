# Firebase Configuration Setup Guide

This guide helps you set up Firebase configuration for the Travel Wizards Flutter app.

## Overview

The following files contain sensitive Firebase configuration data and are excluded from git:

- `lib/firebase_options.dart` - Flutter Firebase configuration
- `android/app/google-services.json` - Android Firebase configuration  
- `web/index.html` - Web Firebase configuration
- `web/firebase-messaging-sw.js` - Web Push Messaging configuration

## Setup Instructions

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Follow the setup wizard to create your project
4. Enable the following services:
   - Authentication (Email/Password, Google Sign-in)
   - Cloud Firestore
   - Cloud Storage
   - Cloud Messaging (FCM)
   - Analytics (optional)

### 2. Configure Flutter App

Install the FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
```

Configure Firebase for your project:

```bash
flutterfire configure
```

This will automatically generate the required configuration files.

### 3. Manual Configuration (Alternative)

If you prefer manual setup, use the sample files as templates:

#### For lib/firebase_options.dart

1. Copy `lib/firebase_options.dart.sample` to `lib/firebase_options.dart`
2. Replace the placeholder values with your actual Firebase configuration:
   - `YOUR_WEB_API_KEY` - Web API key from Firebase Console
   - `YOUR_ANDROID_API_KEY` - Android API key
   - `YOUR_PROJECT_ID` - Your Firebase project ID
   - `YOUR_APP_ID` - App ID for each platform
   - `YOUR_MESSAGING_SENDER_ID` - Messaging sender ID
   - `YOUR_MEASUREMENT_ID` - Analytics measurement ID (optional)

#### For android/app/google-services.json

1. Download `google-services.json` from Firebase Console:
   - Go to Project Settings → General → Your apps
   - Click on Android app → Download google-services.json
2. Place the file in `android/app/google-services.json`

#### For web/index.html

1. Copy `web/index.html.sample` to `web/index.html`
2. Replace the Firebase configuration object with your actual values
3. Get these values from Firebase Console → Project Settings → General → Web apps

#### For web/firebase-messaging-sw.js

1. Copy `web/firebase-messaging-sw.js.sample` to `web/firebase-messaging-sw.js`
2. Replace the Firebase configuration with your actual values
3. This is required for web push notifications

### 4. Required Firebase Settings

#### Authentication

- Enable Email/Password authentication
- Enable Google Sign-in (optional)
- Configure authorized domains for web

#### Firestore Database

- Create database in production mode
- Set up security rules (see `firestore.rules` if available)

#### Storage

- Enable Cloud Storage
- Configure storage rules for user uploads

#### Cloud Messaging (FCM)

- Enable Cloud Messaging for push notifications
- Configure FCM for web (add web app in Firebase Console)

### 5. Verification

After setup, run the following to verify configuration:

```bash
flutter clean
flutter pub get
flutter run
```

The app should start without Firebase configuration errors.

### Google API scopes & consent

To prefill onboarding data we request Google People API profile information. Configure the OAuth consent screen with the following:

- **Scopes**: `https://www.googleapis.com/auth/user.birthday.read`, `https://www.googleapis.com/auth/user.gender.read`, `profile`, `email`.
- **Justification**: "Used to prefill profile details during onboarding so the user can confirm or edit the data." Include this text in the OAuth consent description.
- **Verification**: Google marks the birthday/gender scopes as sensitive. Submit the verification form with a short demo video (showing the consent prompt and how the data is used) before launching publicly.

Store the consent timestamp in `users/{uid}/consents/peopleApi` (already handled in the app) so you can audit requests.

### API key restrictions

Lock down your API keys before shipping:

- **Maps / Places**: In Google Cloud Console → Credentials, restrict keys to the Android package (`com.travelwizards.app`) with the release SHA-1 fingerprints and HTTPS referrers for web builds (`https://*.travelwizards.app/*`, localhost for dev if required).
- **Firebase Cloud Messaging**: Keep the server key private and use service account credentials for the new Cloud Function; do not embed it in the client app.
- **Stripe**: Use restricted publishable keys on the client. Keep secret keys server-side and, for the competition build, rely on test keys only.
- **Google Pay**: If you later enable live payments, switch the API to production and add the app's signature to the Google Pay console.

Document these settings in your deployment checklist so every environment (dev, staging, prod) stays compliant.

## Security Notes

- **Never commit actual Firebase configuration files to git**
- API keys in Firebase configuration are not secret keys - they identify your project
- Real security comes from Firestore security rules and Authentication
- For production apps, consider using Firebase App Check for additional security

## Troubleshooting

### Common Issues

1. **"No Firebase App '[DEFAULT]' has been created"**
   - Ensure `Firebase.initializeApp()` is called in `main.dart`
   - Verify `firebase_options.dart` exists and has correct configuration

2. **Android build fails with google-services plugin**
   - Ensure `google-services.json` is in `android/app/` directory
   - Check that `google-services` plugin is applied in `android/app/build.gradle`

3. **Web app can't connect to Firebase**
   - Verify Firebase configuration in `web/index.html`
   - Check that your domain is in Firebase authorized domains
   - Ensure Firebase SDK scripts are loading correctly

4. **Push notifications not working on web**
   - Verify `firebase-messaging-sw.js` configuration
   - Check that FCM is enabled in Firebase Console
   - Ensure VAPID key is configured (if using custom implementation)

### Getting Help

- Check [FlutterFire documentation](https://firebase.flutter.dev/)
- Visit [Firebase documentation](https://firebase.google.com/docs)
- Check the Flutter Firebase samples on GitHub

## Sample Environment Variables

If you're using environment variables instead of direct configuration, create a `.env` file:

```env
FIREBASE_API_KEY=your_api_key_here
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_APP_ID=your_app_id
```

Remember to add `.env` to your `.gitignore` (already included).

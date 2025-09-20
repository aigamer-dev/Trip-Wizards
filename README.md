# Travel Wizards - AI-Powered Trip Planning App

A comprehensive Flutter application for AI-powered travel planning with real-time collaboration, offline support, emergency assistance, and advanced trip management features.

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

## 🔧 Configuration

### Firebase Setup

1. **Create Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project or use existing one
   - Enable Authentication, Firestore, Storage, and Cloud Messaging

2. **Download Configuration Files**
   - **Android**: Download `google-services.json`
     ```bash
     # Place in: travel_wizards/android/app/google-services.json
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

2. **Google Translate API**
   - Enable Cloud Translation API in Google Cloud Console
   - Create service account and download JSON key OR use API key
   - Update `.env`:
     ```env
     GOOGLE_TRANSLATE_API_KEY=your-translate-api-key
     ```

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

```
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

**Built with ❤️ using Flutter**

For questions or support, please create an issue on GitHub.
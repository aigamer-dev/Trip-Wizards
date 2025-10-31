# Testing Guide

This document provides comprehensive guidance for running tests locally and in CI for the Travel Wizards Flutter application.

## Test Types

### Unit Tests

Unit tests verify individual functions, classes, and components in isolation.

```bash
# Run all unit tests
flutter test

# Run specific test file
flutter test test/design_tokens_test.dart

# Run with coverage
flutter test --coverage
```

### Widget Tests

Widget tests verify UI components and their interactions.

```bash
# Run widget tests
flutter test test/

# Run specific widget test
flutter test test/components_demo_accessibility_test.dart
```

### Golden Tests

Golden tests verify visual regressions by comparing screenshots.

```bash
# Update golden baselines (when UI changes are intentional)
flutter test --update-goldens test/goldens/

# Run golden tests
flutter test test/goldens/
```

### Integration Tests

Integration tests verify end-to-end functionality including Firebase services.

## Firebase Emulator Setup

For integration tests and development, use Firebase emulators to avoid hitting production services.

### Prerequisites

1. Install Firebase CLI:

   ```bash
   npm install -g firebase-tools
   ```

2. Login to Firebase:

   ```bash
   firebase login
   ```

### Running Emulators Locally

1. Start Firebase emulators:

   ```bash
   cd travel_wizards
   firebase emulators:start --only=auth,firestore
   ```

   This starts:
   - Authentication emulator on `localhost:9099`
   - Firestore emulator on `localhost:8080`

2. Set environment variables for Flutter tests:

   ```bash
   export FIRESTORE_EMULATOR_HOST=localhost:8080
   export FIREBASE_AUTH_EMULATOR_HOST=localhost:9099
   ```

3. Run integration tests:

   ```bash
   flutter test integration_test/
   ```

### Emulator Configuration

The emulators use the configuration in `firebase.json`:

```json
{
  "emulators": {
    "auth": {
      "port": 9099
    },
    "firestore": {
      "port": 8080
    },
    "ui": {
      "enabled": true,
      "port": 4000
    }
  }
}
```

Access the emulator UI at `http://localhost:4000` to inspect data and authentication state.

## CI/CD Testing

### GitHub Actions

The CI pipeline runs the following test suites:

1. **Unit Tests**: Basic functionality tests
2. **Static Analysis**: `flutter analyze` and formatting checks
3. **Golden Tests**: Visual regression tests (PRs only)
4. **Integration Tests**: Full end-to-end tests with emulators (PRs only)

### Required Secrets

Add these secrets to your GitHub repository:

- `FIREBASE_PROJECT_ID`: Your Firebase project ID
- `FIREBASE_TOKEN`: Firebase CI token (`firebase login:ci`)

### Local CI Simulation

To simulate the CI environment locally:

```bash
# Run static analysis
flutter analyze

# Check formatting
dart format --set-exit-if-changed .

# Run tests with coverage
flutter test --coverage

# Generate coverage report
genhtml coverage/lcov.info -o coverage/html
```

## Test Organization

### Directory Structure

```plaintext
test/
├── mocks/                    # Mock implementations
│   └── firebase_mocks.dart
├── goldens/                  # Golden test baselines
│   └── auth_onboarding/
├── design_tokens_test.dart   # Design system tests
├── contrast_verification_test.dart
├── tap_target_verification_test.dart
├── spacing_validation_test.dart
├── components_demo_accessibility_test.dart
├── email_auth_test.dart
├── tier_limits_test.dart
└── firebase_mocking_examples_test.dart

integration_test/
├── app_test.dart
├── basic_navigation_test.dart
├── profile_test.dart
└── helpers/
```

### Test Categories

- **Design System Tests**: Verify tokens, contrast, spacing, accessibility
- **Authentication Tests**: Login, signup, provider migration flows
- **Component Tests**: Widget behavior and interactions
- **Integration Tests**: Full user journeys with Firebase

## Mocking Strategy

### Firebase Services

Use `firebase_auth_mocks` and `fake_cloud_firestore` for unit tests:

```dart
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    fakeFirestore = FakeFirebaseFirestore();
  });

  test('example test', () async {
    // Test implementation
  });
}
```

### HTTP Services

Mock HTTP calls using `mockito`:

```dart
import 'package:mockito/mockito.dart';

class MockHttpClient extends Mock implements http.Client {}

setUp(() {
  mockHttpClient = MockHttpClient();
  // Configure mock responses
});
```

## Debugging Tests

### Common Issues

1. **Firebase Initialization**: Ensure Firebase is initialized before tests
2. **Async Operations**: Use `await` and `pump()` for widget tests
3. **Golden Test Failures**: Update baselines with `--update-goldens`
4. **Emulator Connection**: Verify emulator ports and environment variables

### Test Debugging

```bash
# Run tests with verbose output
flutter test -v

# Run single test
flutter test --plain-name "test name"

# Debug integration test
flutter test integration_test/app_test.dart --debug
```

## Coverage Reporting

### Local Coverage

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### CI Coverage

Coverage reports are automatically uploaded to Codecov via GitHub Actions.

## Best Practices

1. **Test Isolation**: Each test should be independent
2. **Descriptive Names**: Use clear, descriptive test names
3. **Arrange-Act-Assert**: Structure tests clearly
4. **Mock External Dependencies**: Avoid hitting real APIs in unit tests
5. **Golden Test Updates**: Only update golden baselines for intentional UI changes
6. **Integration Test Stability**: Use emulators to ensure consistent test environments

## Troubleshooting

### Emulator Issues

- Ensure Firebase CLI is installed and authenticated
- Check that ports 9099 (auth) and 8080 (firestore) are available
- Verify `firebase.json` configuration

### Test Failures

- Check for async operations that need `await`
- Verify widget tree structure in widget tests
- Ensure proper mock setup for external dependencies

### CI Failures

- Review GitHub Actions logs for detailed error messages
- Check that all required secrets are configured
- Verify Flutter version compatibility

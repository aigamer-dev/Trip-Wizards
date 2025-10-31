# Flaky Tests Tracker

This document tracks tests that are known to be unstable or flaky, along with mitigation strategies and retry configurations.

## Current Flaky Tests

### None Currently Identified

All tests in the current test suite are stable. This section will be updated as flaky tests are identified.

## Test Retry Configuration

### CI/CD Retries

GitHub Actions is configured to retry failed jobs up to 2 times for the following scenarios:

- Network timeouts
- Firebase emulator startup delays
- Race conditions in async operations

### Local Development

For local development, use the following retry strategies:

```bash
# Retry a specific test multiple times
for i in {1..3}; do flutter test test/specific_test.dart && break; done

# Run tests with timeout and retry
timeout 300 flutter test --timeout 30s
```

## Identifying Flaky Tests

### Symptoms of Flaky Tests

- Tests that pass locally but fail in CI
- Tests that fail intermittently
- Tests that fail due to timing issues
- Tests that fail due to external dependencies

### Debugging Flaky Tests

1. **Check for Race Conditions**: Ensure async operations complete before assertions
2. **Mock External Dependencies**: Use mocks for network calls, Firebase, etc.
3. **Add Timeouts**: Use appropriate timeouts for async operations
4. **Isolate Tests**: Ensure tests don't depend on each other
5. **Use Deterministic Data**: Avoid random data in tests

## Mitigation Strategies

### For Async Operations

```dart
test('async operation', () async {
  // Use completers or proper await patterns
  final completer = Completer<void>();
  // ... test logic
  await completer.future.timeout(Duration(seconds: 5));
});
```

### For Firebase Operations

```dart
setUp(() async {
  // Ensure Firebase is properly initialized
  await Firebase.initializeApp();
  // Wait for auth state to settle
  await Future.delayed(Duration(milliseconds: 100));
});
```

### For Widget Tests

```dart
testWidgets('widget test', (WidgetTester tester) async {
  await tester.pumpWidget(MyApp());
  await tester.pumpAndSettle(); // Wait for all animations to complete
  // ... assertions
});
```

## Coverage Targets

### Unit Test Coverage

- **Target**: 80% overall code coverage
- **Critical Paths**: 90% coverage for authentication, payment, and booking flows
- **Measurement**: `flutter test --coverage` with lcov reporting

### Widget Test Coverage

- **Target**: All user-facing components have widget tests
- **Critical Components**: Authentication screens, trip planning, booking flows
- **Measurement**: Manual verification of test existence

### Integration Test Coverage

- **Target**: All major user journeys covered
- **Critical Flows**: Complete booking flow, authentication flow
- **Measurement**: End-to-end test scenarios

## Monitoring and Maintenance

### Regular Review

- Review flaky test status weekly
- Update this document when tests are fixed or new flaky tests identified
- Monitor CI failure rates and investigate patterns

### Test Health Metrics

- **Target Failure Rate**: < 5% in CI
- **Average Test Duration**: < 30 seconds per test
- **Coverage Trend**: Maintain or improve coverage over time

## Adding New Flaky Tests

When a flaky test is identified, add it to this document with:

1. Test name and location
2. Failure symptoms
3. Root cause (if known)
4. Mitigation strategy
5. Status (Active, Investigating, Fixed)

### Template

```markdown
### TestName (file: path/to/test.dart)

**Status**: Active
**Symptoms**: Intermittent failures in CI
**Root Cause**: Race condition with Firebase auth state
**Mitigation**: Added retry logic, increased timeout
**Last Updated**: YYYY-MM-DD
```

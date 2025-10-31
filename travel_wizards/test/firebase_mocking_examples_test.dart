import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_helpers.dart';

void main() {
  group('Firebase Mocking Test Examples', () {
    testWidgets('wrapWithApp provides basic app scaffolding', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        TestHelpers.wrapWithApp(
          child: const Scaffold(body: Center(child: Text('Test Widget'))),
        ),
      );

      expect(find.text('Test Widget'), findsOneWidget);
    });

    testWidgets('wrapWithRouter provides router context', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        TestHelpers.wrapWithRouter(
          child: const Scaffold(body: Center(child: Text('Router Test'))),
        ),
      );

      expect(find.text('Router Test'), findsOneWidget);
    });

    testWidgets('createMockAuthWithUser creates signed-in user', (
      WidgetTester tester,
    ) async {
      final mockAuth = TestHelpers.createMockAuthWithUser(
        email: 'test@example.com',
        displayName: 'Test User',
      );

      expect(mockAuth.currentUser, isNotNull);
      expect(mockAuth.currentUser!.email, 'test@example.com');
      expect(mockAuth.currentUser!.displayName, 'Test User');
      expect(mockAuth.currentUser!.emailVerified, true);
    });

    testWidgets('createMockFirestoreWithData creates test data', (
      WidgetTester tester,
    ) async {
      final mockFirestore = TestHelpers.createMockFirestoreWithData(
        userData: {'name': 'Test User', 'email': 'test@example.com'},
        userId: 'test-user-id',
      );

      final doc = await mockFirestore
          .collection('users')
          .doc('test-user-id')
          .get();

      expect(doc.exists, true);
      expect(doc.data()!['name'], 'Test User');
      expect(doc.data()!['email'], 'test@example.com');
    });
  });
}

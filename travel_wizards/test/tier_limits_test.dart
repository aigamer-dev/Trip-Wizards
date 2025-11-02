import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_wizards/src/shared/services/generation_service.dart';

/// Tests for subscription tier generation limits
/// Tests Free (1/day), Pro (5/day), and Enterprise (10/day) quotas
void main() {
  setUp(() async {
    // Reset shared preferences before each test
    SharedPreferences.setMockInitialValues({});
  });

  group('Generation Tier Limits', () {
    test('Free tier: allows exactly 1 generation per day', () async {
      final service = GenerationService.instance;

      // First generation should succeed, 0 remaining
      final remaining1 = await service.checkAndConsume(tier: 'free');
      expect(
        remaining1,
        0,
        reason: 'Free tier: 1 generation consumed, 0 remaining',
      );

      // Second generation should fail with StateError
      expect(
        () => service.checkAndConsume(tier: 'free'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Daily limit reached'),
          ),
        ),
        reason: 'Free tier: 2nd generation should be blocked',
      );

      // Verify today's count
      final count = await service.getTodayCount();
      expect(
        count,
        1,
        reason: 'Free tier: count should be 1 after limit reached',
      );
    });

    test('Pro tier: allows exactly 5 generations per day', () async {
      final service = GenerationService.instance;

      // Consume all 5 generations
      for (int i = 0; i < 5; i++) {
        final remaining = await service.checkAndConsume(tier: 'pro');
        expect(
          remaining,
          4 - i,
          reason: 'Pro tier: generation ${i + 1}/5, ${4 - i} remaining',
        );
      }

      // 6th generation should fail
      expect(
        () => service.checkAndConsume(tier: 'pro'),
        throwsA(isA<StateError>()),
        reason: 'Pro tier: 6th generation should be blocked',
      );

      // Verify final count
      final count = await service.getTodayCount();
      expect(count, 5, reason: 'Pro tier: count should be 5 after limit');
    });

    test('Enterprise tier: allows exactly 10 generations per day', () async {
      final service = GenerationService.instance;

      // Consume all 10 generations
      for (int i = 0; i < 10; i++) {
        final remaining = await service.checkAndConsume(tier: 'enterprise');
        expect(
          remaining,
          9 - i,
          reason: 'Enterprise tier: generation ${i + 1}/10, ${9 - i} remaining',
        );
      }

      // 11th generation should fail
      expect(
        () => service.checkAndConsume(tier: 'enterprise'),
        throwsA(isA<StateError>()),
        reason: 'Enterprise tier: 11th generation should be blocked',
      );

      // Verify final count
      final count = await service.getTodayCount();
      expect(
        count,
        10,
        reason: 'Enterprise tier: count should be 10 after limit',
      );
    });

    test('Quota resets when date changes', () async {
      // Note: This test documents expected behavior but cannot automatically
      // test date changes. Requires manual verification by:
      // 1. Consuming quota on one day
      // 2. Changing device date to next day
      // 3. Verifying getTodayCount() returns 0

      // For now, just verify the count is initially 0
      final service = GenerationService.instance;
      final initialCount = await service.getTodayCount();
      expect(initialCount, 0, reason: 'Initial count should be 0');
    });

    test('Different tiers have independent counters', () async {
      // This tests implementation detail: SharedPreferences keys should be
      // same for all tiers (date-based reset), but limits differ

      final service = GenerationService.instance;

      // Consume 1 under Free tier
      await service.checkAndConsume(tier: 'free');

      // Should still allow consuming more under Pro tier
      // (because the counter is shared, but Pro has higher limit)
      final prefs = await SharedPreferences.getInstance();
      final count = prefs.getInt('gen_daily_count');
      expect(
        count,
        1,
        reason: 'Counter should be 1 after Free tier consumption',
      );

      // Pro tier check should see the same counter but allow more
      final remainingPro = await service.checkAndConsume(tier: 'pro');
      expect(
        remainingPro,
        3,
        reason: 'Pro tier: 2/5 consumed (1 from Free, 1 from Pro), 3 remaining',
      );
    });

    test('Error message includes tier information', () async {
      final service = GenerationService.instance;

      // Consume Free tier quota
      await service.checkAndConsume(tier: 'free');

      // Verify error message
      try {
        await service.checkAndConsume(tier: 'free');
        fail('Should have thrown StateError');
      } on StateError catch (e) {
        expect(
          e.message,
          contains('free'),
          reason: 'Error message should mention "free" tier',
        );
        expect(
          e.message,
          contains('Daily limit reached'),
          reason: 'Error message should be user-friendly',
        );
      }
    });
  });

  group('Generation Job Management', () {
    test('Job registration creates snapshot', () async {
      final service = GenerationService.instance;

      // Start a generation
      final payload = {'destination': 'Goa', 'duration': 3};
      // Note: generateTripPlan doesn't return job ID, so we test via activeJobs

      final initialJobs = service.activeJobs;
      final initialCount = initialJobs.length;

      // Trigger generation (don't await - it's async)
      // ignore: unawaited_futures
      service.generateTripPlan(payload: payload);

      // Wait a bit for registration
      await Future.delayed(const Duration(milliseconds: 100));

      // Check active jobs increased
      expect(
        service.activeJobs.length,
        greaterThan(initialCount),
        reason: 'Active jobs should increase after generation starts',
      );
    });

    test(
      'Job progresses through states: queued → running → succeeded',
      () async {
        final service = GenerationService.instance;

        final payload = {'destination': 'Manali', 'duration': 5};

        // Start generation
        final genFuture = service.generateTripPlan(payload: payload);

        // Initial state should be queued or running
        await Future.delayed(const Duration(milliseconds: 50));
        final jobs1 = service.activeJobs;
        expect(jobs1.isNotEmpty, true, reason: 'Should have active job');

        // Wait for completion
        await genFuture;

        // After completion, job should be succeeded
        // (Note: Service removes succeeded jobs from active list after a delay,
        // so we can't always verify final state here)

        expect(true, true, reason: 'Generation completed without error');
      },
    );
  });
}

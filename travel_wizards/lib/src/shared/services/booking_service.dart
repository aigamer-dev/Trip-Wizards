import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:travel_wizards/src/shared/services/vendors/ease_my_trip_service.dart';

class BookingStepProgress {
  BookingStepProgress({
    required this.index,
    required this.total,
    required this.label,
    required this.status, // pending | in_progress | success | failed
  });
  final int index;
  final int total;
  final String label;
  final String status;
}

class BookingResult {
  BookingResult({
    required this.type, // flight | hotel | transport | activity
    required this.status, // booked | failed
    required this.priceCents,
    this.confirmationCode,
    this.error,
  });
  final String type;
  final String status;
  final int priceCents;
  final String? confirmationCode;
  final String? error;
}

class BookingSummary {
  BookingSummary({
    required this.results,
    required this.totalBookedCents,
    required this.failures,
    required this.deltaCents,
  });
  final List<BookingResult> results;
  final int totalBookedCents;
  final int failures;
  final int deltaCents; // amount to collect beyond already paid
}

class BookingService {
  BookingService._();
  static final BookingService instance = BookingService._();

  Future<BookingSummary> bookSequentially({
    required String tripId,
    void Function(BookingStepProgress progress)? onProgress,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Not signed in');

    final tripsCol = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('trips');
    final tripRef = tripsCol.doc(tripId);

    final tripSnap = await tripRef.get();
    final trip = tripSnap.data() ?? <String, dynamic>{};

    // Determine nights for hotel price estimate
    int nights = 2;
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.tryParse(v.toString());
      } catch (_) {
        return null;
      }
    }

    final start = parseDate(trip['startDate']);
    final end = parseDate(trip['endDate']);
    if (start != null && end != null) {
      nights = end.difference(start).inDays.abs().clamp(1, 30);
    }

    final steps = <({String label, String type, int priceCents})>[
      (label: 'Booking flight', type: 'flight', priceCents: 35000), // $350.00
      (
        label: 'Booking hotel',
        type: 'hotel',
        priceCents: max(1, nights) * 12000, // $120/night
      ),
      (
        label: 'Reserving local transport',
        type: 'transport',
        priceCents: 6000, // $60
      ),
    ];

    // Deterministic failure: based on tripId hash, fail at most one step
    int? failIndex;
    final h = tripId.hashCode.abs();
    final r = h % 10;
    if (r == 1) failIndex = 1; // hotel fails
    if (r == 2) failIndex = 0; // flight fails
    // Optional override via Firestore for testing
    final testOverride = (trip['bookingTest'] as Map?)?.cast<String, dynamic>();
    if (testOverride != null && testOverride['failIndex'] is int) {
      failIndex = testOverride['failIndex'] as int;
    }

    final bookingsCol = tripRef.collection('bookings');

    final results = <BookingResult>[];
    int totalCents = 0;

    for (var i = 0; i < steps.length; i++) {
      final step = steps[i];
      onProgress?.call(
        BookingStepProgress(
          index: i,
          total: steps.length,
          label: step.label,
          status: 'in_progress',
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 700));

      if (failIndex == i) {
        final res = BookingResult(
          type: step.type,
          status: 'failed',
          priceCents: step.priceCents,
          error: 'Partner temporarily unavailable, please retry',
        );
        results.add(res);
        await bookingsCol.add({
          'type': res.type,
          'status': res.status,
          'priceCents': res.priceCents,
          'vendor': 'EaseMyTrip',
          'error': res.error,
          'uid': uid,
          'tripId': tripId,
          'createdAtMs': DateTime.now().millisecondsSinceEpoch,
        });
        onProgress?.call(
          BookingStepProgress(
            index: i,
            total: steps.length,
            label: step.label,
            status: 'failed',
          ),
        );
        continue;
      }

      // Use vendor service to obtain confirmation
      String conf;
      if (step.type == 'flight') {
        conf = await EaseMyTripService.instance.bookFlight(tripId: tripId);
      } else if (step.type == 'hotel') {
        conf = await EaseMyTripService.instance.bookHotel(
          tripId: tripId,
          nights: max(1, nights),
        );
      } else if (step.type == 'transport') {
        conf = await EaseMyTripService.instance.bookTransport(tripId: tripId);
      } else {
        conf = _generateConfirmation(step.type, h + i);
      }
      final res = BookingResult(
        type: step.type,
        status: 'booked',
        priceCents: step.priceCents,
        confirmationCode: conf,
      );
      results.add(res);
      totalCents += step.priceCents;

      await bookingsCol.add({
        'type': res.type,
        'status': res.status,
        'priceCents': res.priceCents,
        'vendor': 'EaseMyTrip',
        'confirmationCode': conf,
        'uid': uid,
        'tripId': tripId,
        'createdAtMs': DateTime.now().millisecondsSinceEpoch,
      });

      onProgress?.call(
        BookingStepProgress(
          index: i,
          total: steps.length,
          label: step.label,
          status: 'success',
        ),
      );
    }

    // Compare with already paid amount to compute delta
    final payment = (trip['payment'] as Map?)?.cast<String, dynamic>();
    final paidAmount = (payment?['amountCents'] as int?) ?? 0;
    final delta = (totalCents - paidAmount).clamp(0, 1 << 31);

    // Update trip booking status
    final failures = results.where((r) => r.status == 'failed').length;
    await tripRef.set({
      'booking': {
        'status': failures == 0 ? 'booked' : 'partial_failed',
        'totalBookedCents': totalCents,
        'failures': failures,
        'deltaCents': delta,
        'currency':
            (trip['invoice'] is Map && (trip['invoice']['currency'] is String))
            ? trip['invoice']['currency']
            : 'USD',
        'updatedAt': DateTime.now().toIso8601String(),
      },
    }, SetOptions(merge: true));

    return BookingSummary(
      results: results,
      totalBookedCents: totalCents,
      failures: failures,
      deltaCents: delta,
    );
  }

  String _generateConfirmation(String type, int seed) {
    final rnd = Random(seed);
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final prefix = switch (type) {
      'flight' => 'FLT',
      'hotel' => 'HTL',
      'transport' => 'CAB',
      _ => 'BKG',
    };
    final code = List.generate(
      6,
      (_) => chars[rnd.nextInt(chars.length)],
    ).join();
    return '$prefix-$code';
  }
}

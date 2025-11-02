import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:travel_wizards/src/shared/widgets/spacing.dart';
import 'package:travel_wizards/src/features/payments/views/screens/trip_payment_sheet.dart';
import 'package:travel_wizards/src/features/bookings/views/screens/booking_progress_sheet.dart';

/// A card widget that displays the booking status for a trip.
///
/// Shows booking information including total booked amount, delta amount due,
/// failure count, and provides actions for payment and retrying bookings.
class TripBookingStatusCard extends StatelessWidget {
  const TripBookingStatusCard({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    final doc = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('trips')
        .doc(tripId);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: doc.snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? const {};
        final booking = (data['booking'] as Map?)?.cast<String, dynamic>();

        if (booking == null) {
          return _buildNoBookingsCard(context);
        }

        return _buildBookingStatusCard(context, booking, doc);
      },
    );
  }

  Widget _buildNoBookingsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: Insets.allMd,
        child: Row(
          children: [
            const Icon(Icons.event_available_rounded),
            Gaps.w8,
            Expanded(
              child: Text(
                'No bookings yet. Complete payment and tap Book to start.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingStatusCard(
    BuildContext context,
    Map<String, dynamic> booking,
    DocumentReference<Map<String, dynamic>> doc,
  ) {
    final total = (booking['totalBookedCents'] as int?) ?? 0;
    final delta = (booking['deltaCents'] as int?) ?? 0;
    final failures = (booking['failures'] as int?) ?? 0;
    final status = (booking['status'] as String?) ?? 'pending';
    final currency = (booking['currency'] as String?) ?? 'USD';

    return Card(
      child: Padding(
        padding: Insets.allMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, status),
            Gaps.h8,
            _buildBookingInfo(context, total, currency),
            if (failures > 0) ...[
              Gaps.h8,
              _buildFailureInfo(context, failures),
            ],
            if (delta > 0) ...[
              Gaps.h8,
              _buildDeltaInfo(context, delta, currency),
            ],
            Gaps.h8,
            _buildActionButtons(context, delta, failures, currency, doc, total),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String status) {
    return Row(
      children: [
        const Icon(Icons.event_available_rounded),
        Gaps.w8,
        Text('Booking status', style: Theme.of(context).textTheme.titleMedium),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(status),
        ),
      ],
    );
  }

  Widget _buildBookingInfo(BuildContext context, int total, String currency) {
    return Row(
      children: [
        Expanded(
          child: Text('Total booked: ${_formatCurrency(total, currency)}'),
        ),
      ],
    );
  }

  Widget _buildFailureInfo(BuildContext context, int failures) {
    return Text(
      'Failures: $failures',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Widget _buildDeltaInfo(BuildContext context, int delta, String currency) {
    return Text(
      'Delta due: ${_formatCurrency(delta, currency)}',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.tertiary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    int delta,
    int failures,
    String currency,
    DocumentReference<Map<String, dynamic>> doc,
    int total,
  ) {
    return Row(
      children: [
        if (delta > 0)
          FilledButton.icon(
            onPressed: () =>
                _handlePayDelta(context, delta, currency, doc, total),
            icon: const Icon(Symbols.payments_rounded),
            label: const Text('Pay delta'),
          ),
        if (failures > 0) ...[Gaps.w8],
        if (failures > 0)
          OutlinedButton.icon(
            onPressed: () => _handleRetryBooking(context),
            icon: const Icon(Symbols.refresh_rounded),
            label: const Text('Retry booking'),
          ),
      ],
    );
  }

  String _formatCurrency(int cents, String currency) {
    return '$currency ${(cents / 100).toStringAsFixed(2)}';
  }

  Future<void> _handlePayDelta(
    BuildContext context,
    int delta,
    String currency,
    DocumentReference<Map<String, dynamic>> doc,
    int total,
  ) async {
    final paid = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => TripPaymentSheet(
        tripId: tripId,
        amountCents: delta,
        currency: currency,
        title: 'Pay Booking Delta',
        paymentType: 'booking_delta',
        skipTripPaymentUpdate: true,
        extraLog: {'reason': 'booking_delta', 'totalBookedCents': total},
        onPaymentSuccess: () async {
          await doc.set({
            'booking': {
              'deltaCents': 0,
              'updatedAt': DateTime.now().toIso8601String(),
            },
          }, SetOptions(merge: true));
        },
      ),
    );

    if (paid == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Delta payment received')));
    }
  }

  Future<void> _handleRetryBooking(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => BookingProgressSheet(tripId: tripId),
    );
  }
}

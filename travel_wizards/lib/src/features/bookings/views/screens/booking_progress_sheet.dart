import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:travel_wizards/src/shared/widgets/spacing.dart';
import 'package:travel_wizards/src/features/payments/views/screens/trip_payment_sheet.dart';
import 'package:travel_wizards/src/shared/services/booking_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingProgressSheet extends StatefulWidget {
  const BookingProgressSheet({super.key, required this.tripId});
  final String tripId;

  @override
  State<BookingProgressSheet> createState() => _BookingProgressSheetState();
}

class _BookingProgressSheetState extends State<BookingProgressSheet> {
  int _currentIndex = -1;
  int _total = 0;
  String? _currentLabel;
  BookingSummary? _summary;
  bool _running = true;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() {
      _running = true;
    });
    final summary = await BookingService.instance.bookSequentially(
      tripId: widget.tripId,
      onProgress: (p) {
        setState(() {
          _currentIndex = p.index;
          _total = p.total;
          _currentLabel = p.label;
        });
      },
    );
    setState(() {
      _summary = summary;
      _running = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = _summary;
    return SafeArea(
      child: Padding(
        padding: Insets.allMd,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Booking', style: theme.textTheme.titleLarge),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: _running
                      ? null
                      : () => Navigator.of(context).pop(s),
                ),
              ],
            ),
            if (_running) ...[
              Gaps.h8,
              if (_currentLabel != null)
                Text(_currentLabel!, style: theme.textTheme.titleMedium),
              Gaps.h8,
              LinearProgressIndicator(
                value: _total == 0 || _currentIndex < 0
                    ? null
                    : (_currentIndex + 1) / _total,
              ),
              Gaps.h16,
              Text(
                'We are booking your flight, hotel, and local transport one by one. This may take a few seconds.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ] else if (s != null) ...[
              Gaps.h8,
              Row(
                children: [
                  Icon(
                    s.failures == 0
                        ? Symbols.task_alt_rounded
                        : Symbols.error_circle_rounded,
                    color: s.failures == 0
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                  ),
                  Gaps.w8,
                  Expanded(
                    child: Text(
                      s.failures == 0
                          ? 'All bookings confirmed!'
                          : 'Some bookings failed. You can retry later.',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              Gaps.h8,
              _SummaryList(results: s.results),
              Gaps.h8,
              Text(
                'Total booked: \$${(s.totalBookedCents / 100).toStringAsFixed(2)}',
                style: theme.textTheme.bodyMedium,
              ),
              if (s.deltaCents > 0) ...[
                Gaps.h8,
                Text(
                  'Additional amount due now: \$${(s.deltaCents / 100).toStringAsFixed(2)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Gaps.h8,
                FilledButton.icon(
                  onPressed: () async {
                    final paid = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      builder: (_) => TripPaymentSheet(
                        tripId: widget.tripId,
                        amountCents: s.deltaCents,
                        currency: 'USD',
                        title: 'Pay Booking Delta',
                        paymentType: 'booking_delta',
                        skipTripPaymentUpdate: true,
                        extraLog: {
                          'reason': 'booking_delta',
                          'totalBookedCents': s.totalBookedCents,
                        },
                        onPaymentSuccess: () async {
                          final uid = FirebaseAuth.instance.currentUser?.uid;
                          if (uid == null) return;
                          final doc = FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .collection('trips')
                              .doc(widget.tripId);
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Delta payment received')),
                      );
                    }
                  },
                  icon: const Icon(Symbols.payments_rounded),
                  label: const Text('Pay delta now'),
                ),
              ],
            ],
            Gaps.h8,
          ],
        ),
      ),
    );
  }
}

class _SummaryList extends StatelessWidget {
  const _SummaryList({required this.results});
  final List<BookingResult> results;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (results.isEmpty) {
      return Text(
        'No bookings were created.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    return Column(
      children: [
        for (final r in results)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              r.status == 'booked' ? Symbols.task_alt_rounded : Symbols.error,
              color: r.status == 'booked'
                  ? theme.colorScheme.primary
                  : theme.colorScheme.error,
            ),
            title: Text(r.type[0].toUpperCase() + r.type.substring(1)),
            subtitle: Text(
              r.status == 'booked'
                  ? 'Confirmed: ${r.confirmationCode}'
                  : (r.error ?? 'Failed'),
            ),
            trailing: Text('\$${(r.priceCents / 100).toStringAsFixed(2)}'),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_wizards/src/shared/services/error_handling_service.dart';
import 'package:travel_wizards/src/shared/widgets/spacing.dart';
import 'package:travel_wizards/src/features/payments/views/screens/trip_payment_sheet.dart';
import 'package:travel_wizards/src/features/bookings/views/screens/booking_progress_sheet.dart';
import 'package:travel_wizards/src/shared/services/booking_service.dart';
import 'package:travel_wizards/src/features/trip_planning/views/screens/trip_collaboration_screen.dart';
import 'package:travel_wizards/src/features/trip_planning/views/screens/plan_trip_screen.dart';
import 'package:travel_wizards/src/shared/widgets/trip_sharing_bottom_sheet.dart';

/// Trip actions bar widget that provides action buttons for a trip
class TripActionsBar extends StatelessWidget {
  const TripActionsBar({super.key, required this.tripId});

  final String tripId;

  DocumentReference<Map<String, dynamic>> _doc() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('trips')
        .doc(tripId);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _doc().snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? const {};
        final status = (data['status'] as String?) ?? 'draft';
        final isFinalized = status == 'finalized';
        final isConfirmed = status == 'confirmed';
        final payment = (data['payment'] as Map?)?.cast<String, dynamic>();
        final isPaid = (payment?['status'] as String?) == 'paid';

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isMobile = Breakpoints.isMobile(width);
            final children = <Widget>[
              Semantics(
                label: 'Edit trip',
                button: true,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    context.pushNamed(
                      'plan',
                      extra: PlanTripArgs(tripId: tripId),
                    );
                  },
                  icon: const Icon(Symbols.edit_rounded),
                  label: const Text('Edit'),
                ),
              ),
              Semantics(
                label: 'Share trip',
                button: true,
                child: OutlinedButton.icon(
                  onPressed: () => _showShareDialog(context, tripId),
                  icon: const Icon(Symbols.share_rounded),
                  label: const Text('Share'),
                ),
              ),
              Semantics(
                label: 'Group chat',
                button: true,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.pushNamed(
                      'group_chat',
                      pathParameters: {'tripId': tripId},
                      queryParameters: {
                        'tripName': data['title'] as String? ?? 'Trip',
                      },
                    );
                  },
                  icon: const Icon(Symbols.chat_rounded),
                  label: const Text('Chat'),
                ),
              ),
              Semantics(
                label: 'Trip expenses',
                button: true,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final buddies =
                        (data['buddies'] as List?)?.cast<String>() ??
                        <String>[];
                    context.pushNamed(
                      'expenses',
                      pathParameters: {'tripId': tripId},
                      queryParameters: {'buddies': buddies.join(',')},
                    );
                  },
                  icon: const Icon(Symbols.payments_rounded),
                  label: const Text('Expenses'),
                ),
              ),
              Semantics(
                label: 'Collaborate on trip',
                button: true,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            TripCollaborationScreen(tripId: tripId),
                      ),
                    );
                  },
                  icon: const Icon(Symbols.group_rounded),
                  label: const Text('Collaborate'),
                ),
              ),
              if (!isFinalized && !isConfirmed)
                Semantics(
                  label: 'Finalize trip',
                  button: true,
                  child: FilledButton.icon(
                    onPressed: () async {
                      await _doc().update({'status': 'finalized'});
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Trip finalized')),
                        );
                      }
                    },
                    icon: const Icon(Symbols.check_rounded),
                    label: const Text('Finalize'),
                  ),
                ),
              if (isFinalized && !isPaid)
                Semantics(
                  label: 'Revert to draft',
                  button: true,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Revert to Draft?'),
                          content: const Text(
                            'This will change the trip status back to draft, allowing you to edit it. Continue?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Revert'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await _doc().update({'status': 'draft'});
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Trip reverted to draft'),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Symbols.undo_rounded),
                    label: const Text('Revert'),
                  ),
                ),
              if (isFinalized && !isPaid)
                Semantics(
                  label: 'Pay for trip',
                  button: true,
                  child: FilledButton.icon(
                    onPressed: () async {
                      // Calculate estimated amount based on trip data
                      int amountCents = 1999; // default minimum
                      final destinations = data['destinations'] as List? ?? [];
                      final startDate = _parseDate(data['startDate']);
                      final endDate = _parseDate(data['endDate']);

                      if (destinations.isNotEmpty) {
                        amountCents = 1999 + (destinations.length * 300);
                        if (startDate != null && endDate != null) {
                          final start = startDate;
                          final end = endDate;
                          if (end.isAfter(start)) {
                            final days = end
                                .difference(start)
                                .inDays
                                .abs()
                                .clamp(1, 30);
                            amountCents = 1999 + (days * 500); // base + per-day
                          }
                        }
                      }
                      if (context.mounted) {
                        final paid = await showModalBottomSheet<bool>(
                          context: context,
                          showDragHandle: true,
                          isScrollControlled: true,
                          builder: (_) => TripPaymentSheet(
                            tripId: tripId,
                            amountCents: amountCents,
                            currency: 'USD',
                          ),
                        );
                        if (!context.mounted) return;
                        if (paid == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Payment successful')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Symbols.payments_rounded),
                    label: const Text('Pay'),
                  ),
                ),
              if (isFinalized && isPaid)
                Semantics(
                  label: 'Book trip',
                  button: true,
                  child: FilledButton.icon(
                    onPressed: () async {
                      if (context.mounted) {
                        final summary = await showModalBottomSheet(
                          context: context,
                          showDragHandle: true,
                          isScrollControlled: true,
                          builder: (_) => BookingProgressSheet(tripId: tripId),
                        );
                        if (!context.mounted) return;
                        if (summary is BookingSummary &&
                            summary.deltaCents > 0) {
                          // Note: delta collection is also prompted inside the sheet
                          final delta = summary.deltaCents;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Bookings complete. Additional charge: \$${(delta / 100).toStringAsFixed(2)}',
                              ),
                            ),
                          );
                        } else if (summary is BookingSummary) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Bookings complete!')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Symbols.flight_takeoff_rounded),
                    label: const Text('Book'),
                  ),
                ),
            ];

            if (isMobile) {
              return Wrap(spacing: 8, runSpacing: 8, children: children);
            }

            return Padding(
              padding: Insets.allSm,
              child: Row(children: children),
            );
          },
        );
      },
    );
  }

  /// Parse date from dynamic value
  DateTime? _parseDate(dynamic v) {
    if (v is String) {
      try {
        return DateTime.parse(v);
      } catch (e) {
        ErrorHandlingService.instance.handleError(
          e,
          context: 'TripActionsBar: Parse date from string',
          showToUser: false,
        );
      }
    }
    return null;
  }

  /// Show sharing options for a trip
  Future<void> _showShareDialog(BuildContext context, String tripId) async {
    try {
      // Get trip data for sharing
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final tripDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('trips')
          .doc(tripId)
          .get();

      if (!tripDoc.exists) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Trip not found')));
        }
        return;
      }

      final tripData = tripDoc.data()!;
      final tripTitle = tripData['title'] as String? ?? 'Untitled Trip';
      final destinationsData = tripData['destinations'] as List<dynamic>? ?? [];
      final destinations = destinationsData.map((dest) {
        if (dest is Map<String, dynamic>) {
          return dest;
        } else if (dest is String) {
          return {'name': dest, 'description': ''};
        } else {
          return {'name': dest.toString(), 'description': ''};
        }
      }).toList();

      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          builder: (context) => TripSharingBottomSheet(
            tripId: tripId,
            tripTitle: tripTitle,
            destinations: destinations,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

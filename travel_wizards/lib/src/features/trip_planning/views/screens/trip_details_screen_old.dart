import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:travel_wizards/src/shared/widgets/spacing.dart';
import 'package:travel_wizards/src/shared/services/invites_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'package:travel_wizards/src/features/payments/views/screens/trip_payment_sheet.dart';
import 'package:travel_wizards/src/shared/services/invoice_service.dart';
import 'package:travel_wizards/src/features/bookings/views/screens/booking_progress_sheet.dart';
import 'package:travel_wizards/src/shared/services/booking_service.dart';
import 'package:travel_wizards/src/features/trip_planning/views/screens/trip_collaboration_screen.dart';
import 'package:travel_wizards/src/shared/widgets/trip_sharing_bottom_sheet.dart';
import 'widgets/widgets.dart';

class TripDetailsScreen extends StatefulWidget {
  const TripDetailsScreen({super.key, required this.tripId});

  final String tripId;

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    // Body-only screen; title is controlled by NavShell via AppBarTitleController
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TripBreadcrumb(tripId: widget.tripId),
                Gaps.h8,
                DefaultTextStyle(
                  style:
                      Theme.of(context).textTheme.headlineSmall ??
                      const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                  child: TripTitle(tripId: widget.tripId),
                ),
                const SizedBox(height: 12),
                TripStatus(tripId: widget.tripId),
                Gaps.h8,
                TripMainInfo(tripId: widget.tripId),
                Gaps.h8,
                TripItineraryCard(tripId: widget.tripId),
                Gaps.h8,
                TripBookingStatusCard(tripId: widget.tripId),
                Gaps.h8,
                TripInvoiceCard(tripId: widget.tripId),
                Gaps.h8,
                TripPackingList(tripId: widget.tripId),
                Gaps.h8,
                Card(
                  child: Padding(
                    padding: Insets.allMd,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Invites',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () async {
                                await _showInviteDialog(context, widget.tripId);
                              },
                              icon: const Icon(Symbols.person_add_rounded),
                              label: const Text('Invite'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TripInvitesList(tripId: widget.tripId),
                      ],
                    ),
                  ),
                ),
                Gaps.h8,
              ],
            ),
          ),
        ),
        // Bottom actions bar
        SafeArea(
          top: false,
          left: false,
          right: false,
          child: _TripActionsBar(tripId: widget.tripId),
        ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// Keep the actions bar and helper functions as they weren't extracted
class _TripActionsBar extends StatelessWidget {
  const _TripActionsBar({required this.tripId});
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
                  onPressed: isFinalized
                      ? null
                      : () async {
                          await _showEditTripDialog(context, tripId);
                        },
                  icon: const Icon(Symbols.edit_rounded),
                  label: const Text('Edit'),
                ),
              ),
              isMobile ? Gaps.h8 : Gaps.w8,
              Semantics(
                label: 'Invite buddies',
                button: true,
                child: OutlinedButton.icon(
                  onPressed: isFinalized
                      ? null
                      : () async {
                          await _showInviteDialog(context, tripId);
                        },
                  icon: const Icon(Symbols.person_add_rounded),
                  label: const Text('Invite'),
                ),
              ),
              isMobile ? Gaps.h8 : Gaps.w8,
              Semantics(
                label: 'Manage collaboration',
                button: true,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TripCollaborationScreen(tripId: tripId),
                      ),
                    );
                  },
                  icon: const Icon(Symbols.groups_rounded),
                  label: const Text('Collaborate'),
                ),
              ),
              isMobile ? Gaps.h8 : Gaps.w8,
              Semantics(
                label: 'Share trip',
                button: true,
                child: OutlinedButton.icon(
                  onPressed: () => _showShareDialog(context, tripId),
                  icon: const Icon(Symbols.share_rounded),
                  label: const Text('Share'),
                ),
              ),
              const Spacer(),
              if (!isConfirmed && !isFinalized)
                Semantics(
                  label: 'Confirm trip',
                  button: true,
                  child: FilledButton.icon(
                    onPressed: () async {
                      await _confirmTrip(context, tripId);
                    },
                    icon: const Icon(Symbols.check_circle_rounded),
                    label: const Text('Confirm'),
                  ),
                ),
              if (isConfirmed && !isFinalized)
                Semantics(
                  label: 'Finalize trip',
                  button: true,
                  child: FilledButton.icon(
                    onPressed: () async {
                      await _finalizeTrip(context, tripId);
                    },
                    icon: const Icon(Symbols.task_alt_rounded),
                    label: const Text('Finalize'),
                  ),
                ),
              if (isFinalized && !isPaid)
                Semantics(
                  label: 'Proceed to payment',
                  button: true,
                  child: FilledButton.icon(
                    onPressed: () async {
                      // Prefer invoice total if present; else estimate
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      int amountCents = 4999; // fallback $49.99
                      if (uid != null) {
                        final doc = FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .collection('trips')
                            .doc(tripId);
                        final snap = await doc.get();
                        final data = snap.data() ?? {};
                        final inv = (data['invoice'] as Map?)
                            ?.cast<String, dynamic>();
                        if (inv != null && inv['totalCents'] is int) {
                          amountCents = inv['totalCents'] as int;
                        } else {
                          final start = _parseDate(data['startDate']);
                          final end = _parseDate(data['endDate']);
                          if (start != null && end != null) {
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
                                'Booked with pending delta: \$${(delta / 100).toStringAsFixed(2)}',
                              ),
                            ),
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
              return Padding(
                padding: Insets.allSm,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Edit & Invite
                    OutlinedButton.icon(
                      onPressed: isFinalized
                          ? null
                          : () async {
                              await _showEditTripDialog(context, tripId);
                            },
                      icon: const Icon(Symbols.edit_rounded),
                      label: const Text('Edit'),
                    ),
                    Gaps.h8,
                    OutlinedButton.icon(
                      onPressed: isFinalized
                          ? null
                          : () async {
                              await _showInviteDialog(context, tripId);
                            },
                      icon: const Icon(Symbols.person_add_rounded),
                      label: const Text('Invite'),
                    ),
                    Gaps.h8,
                    // Action CTA (one of below)
                    if (!isConfirmed && !isFinalized)
                      FilledButton.icon(
                        onPressed: () async {
                          await _confirmTrip(context, tripId);
                        },
                        icon: const Icon(Symbols.check_circle_rounded),
                        label: const Text('Confirm'),
                      ),
                    if (isConfirmed && !isFinalized)
                      FilledButton.icon(
                        onPressed: () async {
                          await _finalizeTrip(context, tripId);
                        },
                        icon: const Icon(Symbols.task_alt_rounded),
                        label: const Text('Finalize'),
                      ),
                    if (isFinalized && !isPaid)
                      FilledButton.icon(
                        onPressed: () async {
                          // Prefer invoice total if present; else estimate
                          final uid = FirebaseAuth.instance.currentUser?.uid;
                          int amountCents = 4999; // fallback $49.99
                          if (uid != null) {
                            final doc = FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .collection('trips')
                                .doc(tripId);
                            final snap = await doc.get();
                            final data = snap.data() ?? {};
                            final inv = (data['invoice'] as Map?)
                                ?.cast<String, dynamic>();
                            if (inv != null && inv['totalCents'] is int) {
                              amountCents = inv['totalCents'] as int;
                            } else {
                              final start = _parseDate(data['startDate']);
                              final end = _parseDate(data['endDate']);
                              if (start != null && end != null) {
                                final days = end
                                    .difference(start)
                                    .inDays
                                    .abs()
                                    .clamp(1, 30);
                                amountCents =
                                    1999 + (days * 500); // base + per-day
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
                                const SnackBar(
                                  content: Text('Payment successful'),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Symbols.payments_rounded),
                        label: const Text('Pay'),
                      ),
                    if (isFinalized && isPaid)
                      FilledButton.icon(
                        onPressed: () async {
                          if (context.mounted) {
                            final summary = await showModalBottomSheet(
                              context: context,
                              showDragHandle: true,
                              isScrollControlled: true,
                              builder: (_) =>
                                  BookingProgressSheet(tripId: tripId),
                            );
                            if (!context.mounted) return;
                            if (summary is BookingSummary &&
                                summary.deltaCents > 0) {
                              final delta = summary.deltaCents;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Booked with pending delta: \$${(delta / 100).toStringAsFixed(2)}',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Symbols.flight_takeoff_rounded),
                        label: const Text('Book'),
                      ),
                  ],
                ),
              );
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
}

// Helper functions that are still needed
DateTime? _parseDate(dynamic v) {
  if (v is String) {
    try {
      return DateTime.parse(v);
    } catch (_) {}
  }
  return null;
}

Future<void> _showInviteDialog(BuildContext context, String tripId) async {
  final controller = TextEditingController();
  final invitesRepo = InvitesRepository.instance;
  final messenger = ScaffoldMessenger.of(context);
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Invite a buddy'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email address',
              hintText: 'friend@example.com',
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                // Request contacts permission and show a bottom sheet selector
                if (kIsWeb) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Contacts picker is not available on web'),
                    ),
                  );
                  return;
                }
                final perm = await Permission.contacts.request();
                if (!perm.isGranted) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Contacts permission denied')),
                  );
                  return;
                }
                final contacts = await FlutterContacts.getContacts(
                  withProperties: true,
                  withPhoto: false,
                );
                if (!ctx.mounted) return;
                await showModalBottomSheet<void>(
                  context: ctx,
                  showDragHandle: true,
                  builder: (bctx) {
                    final withEmails = contacts
                        .where((c) => (c.emails.isNotEmpty))
                        .take(200)
                        .toList(growable: false);
                    if (withEmails.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No contacts with emails found'),
                      );
                    }
                    return ListView.separated(
                      itemCount: withEmails.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (c, i) {
                        final person = withEmails[i];
                        final email = person.emails.first.address;
                        return ListTile(
                          leading: const Icon(Symbols.person_rounded),
                          title: Text(person.displayName),
                          subtitle: Text(email),
                          onTap: () {
                            controller.text = email;
                            Navigator.of(bctx).pop();
                          },
                        );
                      },
                    );
                  },
                );
              },
              icon: const Icon(Symbols.contacts_rounded),
              label: const Text('Pick from contacts'),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            final email = controller.text.trim();
            if (email.isEmpty || !email.contains('@')) {
              messenger.showSnackBar(
                const SnackBar(content: Text('Please enter a valid email')),
              );
              return;
            }
            Navigator.of(ctx).pop();
            try {
              await invitesRepo.sendInvite(tripId: tripId, email: email);
              messenger.showSnackBar(
                SnackBar(content: Text('Invite sent to $email')),
              );
            } catch (e) {
              messenger.showSnackBar(
                SnackBar(content: Text('Failed to send invite: $e')),
              );
            }
          },
          child: const Text('Send'),
        ),
      ],
    ),
  );
}

Future<void> _showEditTripDialog(BuildContext context, String tripId) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _EditTripSheet(tripId: tripId),
  );
}

Future<void> _confirmTrip(BuildContext context, String tripId) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;
  final doc = FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('trips')
      .doc(tripId);
  await doc.set({'status': 'confirmed'}, SetOptions(merge: true));
  if (context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Trip confirmed')));
  }
}

Future<void> _finalizeTrip(BuildContext context, String tripId) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;
  final doc = FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('trips')
      .doc(tripId);
  await doc.set({'status': 'finalized'}, SetOptions(merge: true));
  // Generate consolidated invoice on finalization
  try {
    await InvoiceService.instance.generateIfAbsent(tripId);
  } catch (_) {}
  if (context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Trip finalized')));
  }
}

class _EditTripSheet extends StatefulWidget {
  const _EditTripSheet({required this.tripId});
  final String tripId;

  @override
  State<_EditTripSheet> createState() => _EditTripSheetState();
}

class _EditTripSheetState extends State<_EditTripSheet> {
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _tripTypeCtrl = TextEditingController();
  final _transportCtrl = TextEditingController();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('trips')
        .doc(widget.tripId);
    final snap = await doc.get();
    final data = snap.data() ?? const {};
    _titleCtrl.text = (data['title'] as String?) ?? '';
    _notesCtrl.text = (data['notes'] as String?) ?? '';
    _tripTypeCtrl.text =
        (data['tripType'] as String?) ?? (data['type'] as String?) ?? '';
    _transportCtrl.text =
        (data['mainTransport'] as String?) ??
        (data['transport'] as String?) ??
        '';
    setState(() => _loaded = true);
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('trips')
        .doc(widget.tripId);
    await doc.set({
      'title': _titleCtrl.text.trim(),
      'notes': _notesCtrl.text.trim(),
      'tripType': _tripTypeCtrl.text.trim(),
      'mainTransport': _transportCtrl.text.trim(),
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Edit Trip', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Trip Title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tripTypeCtrl,
            decoration: const InputDecoration(labelText: 'Trip Type'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _transportCtrl,
            decoration: const InputDecoration(labelText: 'Main Transport'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(labelText: 'Notes'),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () async {
                  await _save();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Trip updated')),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
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

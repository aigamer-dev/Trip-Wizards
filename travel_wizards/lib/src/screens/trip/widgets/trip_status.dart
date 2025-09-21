import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:travel_wizards/src/services/invoice_service.dart';

/// A widget that displays and manages the trip status.
///
/// Shows the current trip status (draft, confirmed, finalized) and provides
/// actions to progress the trip through different states.
class TripStatus extends StatelessWidget {
  const TripStatus({super.key, required this.tripId});

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

        return ListTile(
          leading: const Icon(Symbols.info_rounded),
          title: Text(
            'Status: ${status[0].toUpperCase()}${status.substring(1)}',
          ),
          trailing: _buildStatusAction(context, status),
        );
      },
    );
  }

  Widget _buildStatusAction(BuildContext context, String status) {
    switch (status) {
      case 'finalized':
        return const Icon(Symbols.verified_rounded, color: Colors.green);
      case 'confirmed':
        return TextButton.icon(
          onPressed: () => _finalizeTrip(context),
          icon: const Icon(Symbols.task_alt_rounded),
          label: const Text('Finalize'),
        );
      default:
        return TextButton.icon(
          onPressed: () => _confirmTrip(context),
          icon: const Icon(Symbols.check_circle_rounded),
          label: const Text('Mark Confirmed'),
        );
    }
  }

  Future<void> _confirmTrip(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _doc().set({'status': 'confirmed'}, SetOptions(merge: true));

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Trip confirmed')));
    }
  }

  Future<void> _finalizeTrip(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _doc().set({'status': 'finalized'}, SetOptions(merge: true));

    // Generate consolidated invoice on finalization
    try {
      await InvoiceService.instance.generateIfAbsent(tripId);
    } catch (_) {
      // Handle error silently for now
    }

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Trip finalized')));
    }
  }
}

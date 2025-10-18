import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// A breadcrumb widget that shows the trip route with destinations.
///
/// Displays destinations connected with arrows. For trips with more than 4 destinations,
/// it shows first, second, ellipsis with count, and last destination.
class TripBreadcrumb extends StatelessWidget implements PreferredSizeWidget {
  const TripBreadcrumb({super.key, required this.tripId});

  final String tripId;

  @override
  Size get preferredSize => const Size.fromHeight(28);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const PreferredSize(
        preferredSize: Size.zero,
        child: SizedBox.shrink(),
      );
    }

    final doc = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('trips')
        .doc(tripId);

    return PreferredSize(
      preferredSize: preferredSize,
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: doc.snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() ?? const {};
          final List<dynamic> raw = (data['destinations'] as List?) ?? const [];
          final dests = raw
              .map((e) => e.toString())
              .where((s) => s.isNotEmpty)
              .toList();

          if (dests.length < 2) {
            return const SizedBox.shrink();
          }

          final breadcrumbText = _buildBreadcrumbText(dests);

          return Semantics(
            label: 'Trip route breadcrumb',
            child: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                breadcrumbText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          );
        },
      ),
    );
  }

  String _buildBreadcrumbText(List<String> destinations) {
    if (destinations.length <= 4) {
      return destinations.join(' → ');
    } else {
      final hidden = destinations.length - 3;
      return '${destinations.first} → ${destinations[1]} (…$hidden…) → ${destinations.last}';
    }
  }
}

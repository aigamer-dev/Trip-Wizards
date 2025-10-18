import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:travel_wizards/src/core/routing/app_bar_title_controller.dart';

/// A widget that displays the trip title and updates the app bar title.
///
/// Shows the trip title from Firestore and automatically updates the
/// AppBarTitleController for NavShell integration.
class TripTitle extends StatelessWidget {
  const TripTitle({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Text('Trip');

    final doc = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('trips')
        .doc(tripId);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: doc.snapshots(),
      builder: (context, snapshot) {
        final t = (snapshot.data?.data() ?? const {})['title'] as String?;
        final title = t == null || t.isEmpty ? 'Trip' : t;

        // Update AppBar title override for NavShell
        AppBarTitleController.instance.setOverride(title);

        return Text(title);
      },
    );
  }
}

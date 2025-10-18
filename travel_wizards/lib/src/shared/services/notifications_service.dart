import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Lightweight in-app notifications for key events using SnackBars.
/// Push notifications (FCM) can be added later; this is in-app only.
class NotificationsService {
  NotificationsService._();
  static final NotificationsService instance = NotificationsService._();

  ScaffoldMessengerState? _messenger;
  StreamSubscription? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _paymentsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _bookingsSub;

  void init(ScaffoldMessengerState messenger) {
    _messenger = messenger;
    _authSub?.cancel();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _disposeStreams();
      if (user != null) {
        _watchUserCollections(user.uid);
      }
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) _watchUserCollections(user.uid);
  }

  void _watchUserCollections(String uid) {
    // payments feed (most recent 10, listen for additions)
    _paymentsSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('payments')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .listen((snap) {
          if (!snap.metadata.isFromCache && snap.docChanges.isNotEmpty) {
            for (final c in snap.docChanges) {
              if (c.type == DocumentChangeType.added) {
                final d = c.doc.data();
                if (d == null) continue;
                final status = (d['status'] as String?) ?? 'unknown';
                final title = (d['title'] as String?) ?? 'Payment';
                _show('Payment $status: $title');
              }
            }
          }
        });

    // bookings feed via collection group (last 10 for uid)
    _bookingsSub = FirebaseFirestore.instance
        .collectionGroup('bookings')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAtMs', descending: true)
        .limit(10)
        .snapshots()
        .listen((snap) {
          if (!snap.metadata.isFromCache && snap.docChanges.isNotEmpty) {
            for (final c in snap.docChanges) {
              if (c.type == DocumentChangeType.added) {
                final d = c.doc.data();
                if (d == null) continue;
                final status = (d['status'] as String?) ?? 'unknown';
                final type = (d['type'] as String?) ?? 'item';
                if (status == 'booked') {
                  _show('Booked ${type[0].toUpperCase()}${type.substring(1)}');
                } else if (status == 'failed') {
                  _show(
                    'Booking failed: ${type[0].toUpperCase()}${type.substring(1)}',
                  );
                }
              }
            }
          }
        });
  }

  void _show(String message) {
    final m = _messenger;
    if (m == null) return;
    m.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Public API for other services to trigger a lightweight in-app notification.
  void show(String message) => _show(message);

  void _disposeStreams() {
    _paymentsSub?.cancel();
    _paymentsSub = null;
    _bookingsSub?.cancel();
    _bookingsSub = null;
  }

  void dispose() {
    _disposeStreams();
    _authSub?.cancel();
    _authSub = null;
    _messenger = null;
  }
}

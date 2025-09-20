import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Tracks whether the current user has completed onboarding by listening to the
/// Firestore user document and exposes a [hasOnboarded] flag.
class OnboardingState extends ChangeNotifier {
  OnboardingState._();
  static final OnboardingState instance = OnboardingState._();

  bool? _hasOnboarded; // null = unknown/not loaded
  bool? get hasOnboarded => _hasOnboarded;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSub;

  void start() {
    _authSub ??= FirebaseAuth.instance.authStateChanges().listen((user) {
      _userDocSub?.cancel();
      _userDocSub = null;
      if (user == null) {
        _hasOnboarded = null;
        notifyListeners();
        return;
      }
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      _userDocSub = docRef.snapshots().listen(
        (snap) {
          final data = snap.data();
          final v = (data?['hasOnboarded'] as bool?) ?? false;
          if (_hasOnboarded != v) {
            _hasOnboarded = v;
            notifyListeners();
          }
        },
        onError: (_) {
          // If read fails, do not block routing; keep value as-is.
        },
      );
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _userDocSub?.cancel();
    super.dispose();
  }
}

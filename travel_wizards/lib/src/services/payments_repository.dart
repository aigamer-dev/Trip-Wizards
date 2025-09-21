import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentEntry {
  PaymentEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.amountCents,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.productId,
    this.platform,
    this.tripId,
    this.extra,
  });

  final String id;
  final String type; // subscription | trip | other
  final String title; // e.g., Pro Monthly, Trip Invoice XYZ
  final int amountCents; // store minor units
  final String currency; // e.g., USD
  final String status; // success | failed | pending
  final DateTime createdAt;
  final String? productId;
  final String? platform; // google_play | stripe | web | unknown
  final String? tripId;
  final Map<String, dynamic>? extra;

  factory PaymentEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data() ?? const {};
    return PaymentEntry(
      id: d.id,
      type: (data['type'] as String?) ?? 'other',
      title: (data['title'] as String?) ?? 'Payment',
      amountCents: (data['amountCents'] as int?) ?? 0,
      currency: (data['currency'] as String?) ?? 'USD',
      status: (data['status'] as String?) ?? 'success',
      createdAt:
          DateTime.tryParse((data['createdAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(
            (data['createdAtMs'] as int?) ??
                DateTime.now().millisecondsSinceEpoch,
          ),
      productId: data['productId'] as String?,
      platform: data['platform'] as String?,
      tripId: data['tripId'] as String?,
      extra: (data['extra'] as Map?)?.cast<String, dynamic>(),
    );
  }
}

class PaymentsRepository {
  PaymentsRepository._();
  static final PaymentsRepository instance = PaymentsRepository._();

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('payments');

  Future<void> logPayment({
    required String type,
    required String title,
    required int amountCents,
    required String currency,
    required String status,
    String? productId,
    String? platform,
    String? tripId,
    Map<String, dynamic>? extra,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final now = DateTime.now();
    await _col(uid).add({
      'type': type,
      'title': title,
      'amountCents': amountCents,
      'currency': currency,
      'status': status,
      'productId': productId,
      'platform': platform,
      'tripId': tripId,
      'extra': extra,
      'createdAt': now.toIso8601String(),
      'createdAtMs': now.millisecondsSinceEpoch,
    });
  }

  Stream<List<PaymentEntry>> watchPayments() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Stream<List<PaymentEntry>>.empty();
    }
    return _col(uid)
        .orderBy('createdAtMs', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => PaymentEntry.fromDoc(d)).toList());
  }
}

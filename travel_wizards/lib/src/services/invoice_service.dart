import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'error_handling_service.dart';

class InvoiceService {
  InvoiceService._();
  static final InvoiceService instance = InvoiceService._();

  Future<Map<String, dynamic>> generateInvoiceForTrip(String tripId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {};
    final tripDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('trips')
        .doc(tripId);
    final snap = await tripDoc.get();
    final data = snap.data() ?? {};
    final start = _parseDate(data['startDate']);
    final end = _parseDate(data['endDate']);
    final days = (start != null && end != null)
        ? (end.difference(start).inDays.abs().clamp(1, 30))
        : 3;

    // Very simple demo invoice with base planning fee + per-day service fee
    final items = <Map<String, dynamic>>[
      {
        'label': 'Planning & concierge fee',
        'quantity': 1,
        'unitAmountCents': 1999,
        'totalCents': 1999,
      },
      {
        'label': 'Daily service fee',
        'quantity': days,
        'unitAmountCents': 500,
        'totalCents': days * 500,
      },
    ];
    final subtotal = items.fold<int>(0, (s, i) => s + (i['totalCents'] as int));
    final taxCents = (subtotal * 0.18).round(); // 18% GST demo
    final total = subtotal + taxCents;

    final inv = {
      'items': items,
      'subtotalCents': subtotal,
      'taxCents': taxCents,
      'totalCents': total,
      'currency': 'USD',
      'createdAt': DateTime.now().toIso8601String(),
      'status': 'due',
    };
    await tripDoc.set({'invoice': inv}, SetOptions(merge: true));
    return inv;
  }

  Future<Map<String, dynamic>> generateIfAbsent(String tripId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {};
    final tripDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('trips')
        .doc(tripId);
    final snap = await tripDoc.get();
    final invoice = (snap.data()?['invoice'] as Map?)?.cast<String, dynamic>();
    if (invoice != null && (invoice['totalCents'] is int)) return invoice;
    return generateInvoiceForTrip(tripId);
  }
}

DateTime? _parseDate(dynamic v) {
  if (v is String) {
    try {
      return DateTime.parse(v);
    } catch (e) {
      ErrorHandlingService.instance.handleError(
        e,
        context: 'InvoiceService: Parse date from string',
        showToUser: false,
      );
    }
  }
  return null;
}

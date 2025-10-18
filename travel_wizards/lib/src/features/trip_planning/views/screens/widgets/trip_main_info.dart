import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:travel_wizards/src/shared/services/error_handling_service.dart';
import 'package:travel_wizards/src/shared/widgets/spacing.dart';

/// A card widget that displays the main trip information.
///
/// Shows dates, duration, trip type, transport, budget, and notes.
class TripMainInfo extends StatelessWidget {
  const TripMainInfo({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    final doc = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('trips')
        .doc(tripId);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: doc.snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? const {};
        final start = _parseDate(data['startDate']);
        final end = _parseDate(data['endDate']);
        final notes = (data['notes'] as String?) ?? '';
        final tripType =
            (data['tripType'] as String?) ?? (data['type'] as String?) ?? '—';
        final transport =
            (data['mainTransport'] as String?) ??
            (data['transport'] as String?) ??
            '—';
        final invoice = (data['invoice'] as Map?)?.cast<String, dynamic>();
        final invTotal = (invoice?['totalCents'] as int?) ?? 0;
        final invCurrency = (invoice?['currency'] as String?) ?? 'USD';
        final budgetCents = (data['budgetCents'] as int?) ?? invTotal;
        final budgetCurrency =
            (data['budgetCurrency'] as String?) ?? invCurrency;

        int? durationDays;
        if (start != null && end != null) {
          durationDays = end.difference(start).inDays.abs().clamp(1, 365);
        }

        return Semantics(
          label: 'Main trip summary',
          child: Card(
            child: Padding(
              padding: Insets.allMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSection(
                    context,
                    'Dates',
                    start != null && end != null
                        ? '${_fmtDate(start)} → ${_fmtDate(end)}'
                        : 'Dates not set',
                  ),
                  _buildInfoSection(
                    context,
                    'Duration',
                    durationDays != null ? '$durationDays days' : '—',
                  ),
                  _buildInfoSection(
                    context,
                    'Trip Type',
                    tripType.isEmpty ? '—' : tripType,
                  ),
                  _buildInfoSection(
                    context,
                    'Main Transport',
                    transport.isEmpty ? '—' : transport,
                  ),
                  _buildInfoSection(
                    context,
                    'Budget',
                    budgetCents > 0
                        ? '$budgetCurrency ${(budgetCents / 100).toStringAsFixed(2)}'
                        : '—',
                  ),
                  _buildInfoSection(
                    context,
                    'Notes',
                    notes.isEmpty ? '—' : notes,
                    isLast: true,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    String title,
    String value, {
    bool isLast = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(value),
        if (!isLast) const SizedBox(height: 12),
      ],
    );
  }

  String _fmtDate(DateTime d) => d.toLocal().toString().split(' ').first;

  DateTime? _parseDate(dynamic v) {
    if (v is String) {
      try {
        return DateTime.parse(v);
      } catch (e) {
        ErrorHandlingService.instance.handleError(
          e,
          context: 'TripMainInfo: Parse date from string',
          showToUser: false,
        );
      }
    }
    return null;
  }
}

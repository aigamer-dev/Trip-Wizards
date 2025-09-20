import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:travel_wizards/src/common/ui/spacing.dart';

class TripInvoiceCard extends StatelessWidget {
  const TripInvoiceCard({super.key, required this.tripId});

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
        final invoice = (data['invoice'] as Map?)?.cast<String, dynamic>();
        if (invoice == null) {
          return Card(
            child: Padding(
              padding: Insets.allMd,
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_rounded),
                  Gaps.w8,
                  const Expanded(
                    child: Text('Invoice will be generated on finalization.'),
                  ),
                ],
              ),
            ),
          );
        }
        final items = (invoice['items'] as List?)?.cast<Map>() ?? const [];
        int subtotal = (invoice['subtotalCents'] as int?) ?? 0;
        int tax = (invoice['taxCents'] as int?) ?? 0;
        int total = (invoice['totalCents'] as int?) ?? 0;
        final currency = (invoice['currency'] as String?) ?? 'USD';
        final payment = (data['payment'] as Map?)?.cast<String, dynamic>();
        final paid = (payment?['status'] as String?) == 'paid';

        String fmt(int cents) =>
            '$currency ${(cents / 100).toStringAsFixed(2)}';

        return Semantics(
          label: 'Invoice summary',
          child: Card(
            child: Padding(
              padding: Insets.allMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long_rounded),
                      Gaps.w8,
                      Text(
                        'Invoice',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: paid
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          paid ? 'PAID' : 'DUE',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: paid
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onErrorContainer,
                              ),
                        ),
                      ),
                    ],
                  ),
                  Gaps.h8,
                  ...items.map((m) {
                    final item = m.cast<String, dynamic>();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item['label']} x${item['quantity']}',
                            ),
                          ),
                          Text(fmt(item['totalCents'] as int)),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 16),
                  Row(
                    children: [
                      const Expanded(child: Text('Subtotal')),
                      Text(fmt(subtotal)),
                    ],
                  ),
                  Row(
                    children: [
                      const Expanded(child: Text('Tax')),
                      Text(fmt(tax)),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'Total',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Text(
                        fmt(total),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

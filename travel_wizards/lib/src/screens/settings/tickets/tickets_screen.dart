import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:share_plus/share_plus.dart';
import 'package:travel_wizards/src/common/ui/spacing.dart';
import 'package:flutter/services.dart';

class TicketsScreen extends StatelessWidget {
  const TicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Please sign in.'));
    }
    final query = FirebaseFirestore.instance
        .collectionGroup('bookings')
        .where('uid', isEqualTo: uid)
        .where('status', isEqualTo: 'booked')
        .orderBy('createdAtMs', descending: true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text('Tickets', style: Theme.of(context).textTheme.titleLarge),
        ),
        const Divider(),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: query.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator();
              }
              final docs = snapshot.data?.docs ?? const [];
              if (docs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: Insets.allMd,
                    child: Text('No tickets yet.'),
                  ),
                );
              }
              return ListView.separated(
                padding: Insets.allMd,
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final data = docs[index].data();
                  final type = (data['type'] as String?) ?? 'item';
                  final vendor = (data['vendor'] as String?) ?? 'Vendor';
                  final tripId = data['tripId'] as String?;
                  final code = (data['confirmationCode'] as String?) ?? '';
                  final createdAt = DateTime.fromMillisecondsSinceEpoch(
                    (data['createdAtMs'] as int?) ?? 0,
                  );
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    leading: const Icon(Symbols.airplane_ticket_rounded),
                    title: Text(
                      '${type[0].toUpperCase()}${type.substring(1)} — $code',
                    ),
                    subtitle: Text(
                      '${createdAt.toLocal().toString().split('.').first} • $vendor',
                    ),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          tooltip: 'Copy',
                          icon: const Icon(Symbols.content_copy_rounded),
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: code));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Code copied')),
                              );
                            }
                          },
                        ),
                        IconButton(
                          tooltip: 'Share',
                          icon: const Icon(Symbols.share_rounded),
                          onPressed: () => Share.share('Ticket $type: $code'),
                        ),
                        if (tripId != null)
                          IconButton(
                            tooltip: 'Open trip',
                            icon: const Icon(Symbols.open_in_new_rounded),
                            onPressed: () => context.pushNamed(
                              'trip_details',
                              pathParameters: {'id': tripId},
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

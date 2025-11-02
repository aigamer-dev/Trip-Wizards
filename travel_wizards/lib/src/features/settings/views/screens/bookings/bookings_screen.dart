import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:travel_wizards/src/shared/widgets/layout/modern_page_scaffold.dart';
import 'package:travel_wizards/src/shared/widgets/layout/modern_section.dart';
import 'package:travel_wizards/src/shared/widgets/spacing.dart';
import 'package:travel_wizards/src/shared/widgets/avatar/profile_avatar.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  String _status = 'all'; // all | booked | failed
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final theme = Theme.of(context);
    if (uid == null) {
      return const ModernPageScaffold(
        pageTitle: 'Bookings',
        body: Center(child: Text('Please sign in.')),
      );
    }
    final query = FirebaseFirestore.instance
        .collectionGroup('bookings')
        .limit(500); // Increased limit to filter in memory

    Stream<QuerySnapshot<Map<String, dynamic>>> safeStream;
    try {
      safeStream = query.snapshots();
    } catch (e) {
      // If query setup fails, return empty stream
      safeStream = const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }
    return ModernPageScaffold(
      pageTitle: 'Bookings',
      actions: [
        PopupMenuButton<String>(
          onSelected: (v) => setState(() => _status = v),
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'all', child: Text('All')),
            PopupMenuItem(value: 'booked', child: Text('Booked')),
            PopupMenuItem(value: 'failed', child: Text('Failed')),
          ],
          icon: const Icon(Symbols.filter_list_rounded),
        ),
      ],
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: safeStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LinearProgressIndicator();
          }
          if (snapshot.hasError) {
            // Handle Firestore index errors gracefully
            final error = snapshot.error.toString();
            if (error.contains('requires an index') ||
                error.contains('FAILED_PRECONDITION')) {
              return const Center(
                child: Padding(
                  padding: Insets.allMd,
                  child: Text(
                    'Bookings data is loading. Please wait or try again later.',
                  ),
                ),
              );
            }
            return Center(
              child: Padding(
                padding: Insets.allMd,
                child: Text('Error loading bookings: $error'),
              ),
            );
          }
          final docs = snapshot.data?.docs ?? const [];
          // Filter by uid in memory to avoid index requirement
          final userDocs = docs
              .where((doc) => doc.data()['uid'] == uid)
              .toList();
          var items = userDocs.map((d) => d.data()).toList(growable: false);
          // Sort by createdAtMs descending since we removed orderBy to avoid index requirement
          items.sort((a, b) {
            final aTime = (a['createdAtMs'] as int?) ?? 0;
            final bTime = (b['createdAtMs'] as int?) ?? 0;
            return bTime.compareTo(aTime);
          });
          if (_status != 'all') {
            items = items.where((e) => e['status'] == _status).toList();
          }
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: Insets.allMd,
                child: Text('No bookings yet.'),
              ),
            );
          }
          return ModernSection(
            title: 'Bookings',
            child: ListView.separated(
              padding: Insets.allMd,
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final b = items[index];
                final tripId = b['tripId'] as String?;
                final createdAt = DateTime.fromMillisecondsSinceEpoch(
                  (b['createdAtMs'] as int?) ?? 0,
                );
                final isBooked = b['status'] == 'booked';
                final priceCents = (b['priceCents'] as int?) ?? 0;
                final vendor = (b['vendor'] as String?) ?? 'Vendor';
                final type = (b['type'] as String?) ?? 'item';
                final subtitle = isBooked
                    ? 'Confirmed ${b['confirmationCode'] ?? ''} • $vendor'
                    : '${b['error'] ?? 'Failed'} • $vendor';
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  leading: ProfileAvatar(
                    size: 40,
                    backgroundColor: isBooked
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.errorContainer,
                    icon: isBooked
                        ? Symbols.task_alt_rounded
                        : Symbols.error_rounded,
                    iconColor: isBooked
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onErrorContainer,
                  ),
                  title: Text('${(priceCents / 100).toStringAsFixed(2)} $type'),
                  subtitle: Text(
                    '${createdAt.toLocal().toString().split('.').first} • $subtitle',
                  ),
                  trailing: tripId == null
                      ? null
                      : IconButton(
                          tooltip: 'Open trip',
                          icon: const Icon(Symbols.open_in_new_rounded),
                          onPressed: () => context.pushNamed(
                            'trip_details',
                            pathParameters: {'id': tripId},
                          ),
                        ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

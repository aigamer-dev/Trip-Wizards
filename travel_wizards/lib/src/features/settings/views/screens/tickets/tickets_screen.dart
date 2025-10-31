import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

class TicketsScreen extends StatelessWidget {
  const TicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Please sign in to view your tickets.'));
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

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: safeStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          // Handle Firestore index errors gracefully
          final error = snapshot.error.toString();
          if (error.contains('requires an index') ||
              error.contains('FAILED_PRECONDITION')) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Symbols.airplane_ticket, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Tickets Loading',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please wait while we load your tickets.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final docs = snapshot.data?.docs ?? const [];
        // Filter by uid and status in memory to avoid index requirement
        final filteredDocs = docs.where((doc) {
          final data = doc.data();
          return data['uid'] == uid &&
              (data['status'] == 'booked' || data['status'] == 'confirmed');
        }).toList();
        // Sort by createdAtMs descending since we removed orderBy to avoid index requirement
        filteredDocs.sort((a, b) {
          final aTime = (a.data()['createdAtMs'] as int?) ?? 0;
          final bTime = (b.data()['createdAtMs'] as int?) ?? 0;
          return bTime.compareTo(aTime);
        });
        if (filteredDocs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Symbols.airplane_ticket, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No Tickets Found',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Your booked tickets will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            return _TicketCard(data: filteredDocs[index].data());
          },
        );
      },
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _TicketCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final type = (data['type'] as String?) ?? 'item';
    final vendor = (data['vendor'] as String?) ?? 'Vendor';
    final tripId = data['tripId'] as String?;
    final code = (data['confirmationCode'] as String?) ?? 'N/A';
    final createdAt = DateTime.fromMillisecondsSinceEpoch(
      (data['createdAtMs'] as int?) ?? 0,
    );

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  type == 'flight' ? Symbols.flight_takeoff : Symbols.hotel,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Text(
                  '${type[0].toUpperCase()}${type.substring(1)} Ticket',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Chip(
                  label: Text(code),
                  backgroundColor: Theme.of(context).primaryColorLight,
                ),
              ],
            ),
            const Divider(height: 24),
            Text('Vendor: $vendor', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              'Booked on: ${createdAt.toLocal().toString().split(' ')[0]}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Copy Confirmation Code',
                  icon: const Icon(Symbols.content_copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Confirmation code copied!'),
                      ),
                    );
                  },
                ),
                IconButton(
                  tooltip: 'Share Ticket',
                  icon: const Icon(Symbols.share),
                  onPressed: () => Share.share(
                    'My $type ticket confirmation code is: $code',
                  ),
                ),
                if (tripId != null)
                  IconButton(
                    tooltip: 'View Trip Details',
                    icon: const Icon(Symbols.open_in_new),
                    onPressed: () => context.pushNamed(
                      'trip_details',
                      pathParameters: {'id': tripId},
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

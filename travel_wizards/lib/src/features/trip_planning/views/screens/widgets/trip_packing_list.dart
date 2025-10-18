import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:travel_wizards/src/shared/widgets/spacing.dart';

/// A card widget that displays and manages the trip packing list.
///
/// Provides functionality to add, check off, and remove packing items.
/// Automatically seeds with common travel essentials when empty.
class TripPackingList extends StatefulWidget {
  const TripPackingList({super.key, required this.tripId});

  final String tripId;

  @override
  State<TripPackingList> createState() => _TripPackingListState();
}

class _TripPackingListState extends State<TripPackingList> {
  late final CollectionReference<Map<String, dynamic>> _col;
  final _controller = TextEditingController();
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _col = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('trips')
        .doc(widget.tripId)
        .collection('packing');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _seedIfEmpty() async {
    if (_seeded) return;
    final snap = await _col.limit(1).get();
    if (snap.size == 0) {
      final now = DateTime.now().toIso8601String();
      final items = _getDefaultPackingItems(now);
      final batch = FirebaseFirestore.instance.batch();
      for (final item in items) {
        batch.set(_col.doc(), item);
      }
      await batch.commit();
    }
    _seeded = true;
  }

  List<Map<String, dynamic>> _getDefaultPackingItems(String timestamp) {
    return [
      {
        'title': 'Passport/ID',
        'checked': false,
        'category': 'Essentials',
        'createdAt': timestamp,
      },
      {
        'title': 'Tickets/Itinerary',
        'checked': false,
        'category': 'Essentials',
        'createdAt': timestamp,
      },
      {
        'title': 'Cash & Cards',
        'checked': false,
        'category': 'Essentials',
        'createdAt': timestamp,
      },
      {
        'title': 'Phone & Charger',
        'checked': false,
        'category': 'Electronics',
        'createdAt': timestamp,
      },
      {
        'title': 'Clothes',
        'checked': false,
        'category': 'Clothing',
        'createdAt': timestamp,
      },
      {
        'title': 'Toiletries',
        'checked': false,
        'category': 'Toiletries',
        'createdAt': timestamp,
      },
    ];
  }

  Future<void> _addItem(String title) async {
    if (title.trim().isEmpty) return;
    await _col.add({
      'title': title.trim(),
      'checked': false,
      'category': 'Custom',
      'createdAt': DateTime.now().toIso8601String(),
    });
    _controller.clear();
  }

  Future<void> _toggle(String id, bool value) async {
    await _col.doc(id).set({'checked': value}, SetOptions(merge: true));
  }

  Future<void> _remove(String id) async {
    await _col.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Packing checklist',
      child: Card(
        child: Padding(
          padding: Insets.allMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Packing List',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _buildAddItemRow(),
              const SizedBox(height: 8),
              _buildPackingItemsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddItemRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Add item',
              hintText: 'e.g., Power bank',
            ),
            onSubmitted: _addItem,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Add item',
          icon: const Icon(Symbols.add_circle_rounded),
          onPressed: () => _addItem(_controller.text),
        ),
      ],
    );
  }

  Widget _buildPackingItemsList() {
    return FutureBuilder<void>(
      future: _seedIfEmpty(),
      builder: (context, _) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _col.orderBy('createdAt').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LinearProgressIndicator();
            }

            final docs = snapshot.data?.docs ?? const [];
            if (docs.isEmpty) {
              return _buildEmptyState();
            }

            return Column(children: docs.map(_buildPackingItem).toList());
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        'No items yet. Add essentials you don\'t want to forget.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildPackingItem(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final title = data['title'] as String? ?? '';
    final checked = (data['checked'] as bool?) ?? false;

    return Dismissible(
      key: ValueKey(doc.id),
      background: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Icon(
          Symbols.delete_rounded,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _remove(doc.id),
      child: CheckboxListTile(
        controlAffinity: ListTileControlAffinity.leading,
        value: checked,
        onChanged: (value) => _toggle(doc.id, value ?? false),
        title: Text(title),
      ),
    );
  }
}

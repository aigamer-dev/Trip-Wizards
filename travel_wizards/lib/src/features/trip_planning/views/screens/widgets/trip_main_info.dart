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
                  _buildVisibilitySection(context, data),
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

  Widget _buildVisibilitySection(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final visibility = (data['visibility'] as String?) ?? 'private';
    final isPublic = (data['isPublic'] as bool?) ?? false;
    final sharedWith = (data['sharedWith'] as List?) ?? [];

    String visibilityLabel = 'Private';
    IconData visibilityIcon = Icons.lock_outline;
    Color? visibilityColor;

    if (visibility == 'community' || isPublic) {
      visibilityLabel = 'Community (Public)';
      visibilityIcon = Icons.public;
      visibilityColor = Colors.green;
    } else if (visibility == 'shared' && sharedWith.isNotEmpty) {
      visibilityLabel = 'Shared with ${sharedWith.length} user(s)';
      visibilityIcon = Icons.people_outline;
      visibilityColor = Colors.blue;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Visibility', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _showVisibilityDialog(context),
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Change'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(visibilityIcon, size: 16, color: visibilityColor),
            const SizedBox(width: 4),
            Text(visibilityLabel, style: TextStyle(color: visibilityColor)),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  void _showVisibilityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _VisibilityDialog(tripId: tripId),
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

/// Dialog for changing trip visibility
class _VisibilityDialog extends StatefulWidget {
  const _VisibilityDialog({required this.tripId});

  final String tripId;

  @override
  State<_VisibilityDialog> createState() => _VisibilityDialogState();
}

class _VisibilityDialogState extends State<_VisibilityDialog> {
  String _selectedVisibility = 'private';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentVisibility();
  }

  Future<void> _loadCurrentVisibility() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('trips')
        .doc(widget.tripId)
        .get();

    if (doc.exists && mounted) {
      final data = doc.data() ?? {};
      setState(() {
        _selectedVisibility = (data['visibility'] as String?) ?? 'private';
      });
    }
  }

  Future<void> _saveVisibility() async {
    setState(() => _isLoading = true);

    try {
      // Import TripsRepository at top of file
      final repo = FirebaseFirestore.instance;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final tripRef = repo
          .collection('users')
          .doc(uid)
          .collection('trips')
          .doc(widget.tripId);

      if (_selectedVisibility == 'private') {
        await tripRef.update({
          'visibility': 'private',
          'isPublic': false,
          'sharedWith': [],
        });
      } else if (_selectedVisibility == 'community') {
        await tripRef.update({'visibility': 'community', 'isPublic': true});
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Visibility updated')));
      }
    } catch (e) {
      ErrorHandlingService.instance.handleError(
        e,
        context: 'Update trip visibility',
        showToUser: true,
        userContext: context,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Visibility'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<String>(
            value: 'private',
            groupValue: _selectedVisibility,
            onChanged: _isLoading
                ? null
                : (value) => setState(() => _selectedVisibility = value!),
          ),
          const ListTile(
            title: Text('Private'),
            subtitle: Text('Only you can see this trip'),
          ),
          Radio<String>(
            value: 'community',
            groupValue: _selectedVisibility,
            onChanged: _isLoading
                ? null
                : (value) => setState(() => _selectedVisibility = value!),
          ),
          const ListTile(
            title: Text('Community (Public)'),
            subtitle: Text('Everyone can discover this trip'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _saveVisibility,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:travel_wizards/src/core/routing/app_bar_title_controller.dart';
import 'package:travel_wizards/src/shared/widgets/translated_text.dart';

/// A widget that displays the trip title and updates the app bar title.
///
/// Shows the trip title from Firestore and automatically updates the
/// AppBarTitleController for NavShell integration. Allows editing the title.
class TripTitle extends StatelessWidget {
  const TripTitle({super.key, required this.tripId});

  final String tripId;

  void _showEditDialog(BuildContext context, String currentTitle) {
    final textController = TextEditingController(text: currentTitle);
    var isSaving = false;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const TranslatedText('Edit Trip Name'),
              content: TextField(
                controller: textController,
                decoration: const InputDecoration(
                  hintText: 'Enter new trip name',
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const TranslatedText('Cancel'),
                ),
                FilledButton(
                  onPressed: (textController.text.trim().isEmpty || isSaving)
                      ? null
                      : () async {
                          setState(() => isSaving = true);
                          try {
                            final uid = FirebaseAuth.instance.currentUser?.uid;
                            if (uid != null) {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(uid)
                                  .collection('trips')
                                  .doc(tripId)
                                  .update({
                                    'title': textController.text.trim(),
                                  });
                            }
                            if (context.mounted) {
                              Navigator.of(dialogContext).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: TranslatedText('Trip name updated'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: TranslatedText(
                                    'Error: ${e.toString()}',
                                  ),
                                ),
                              );
                            }
                          } finally {
                            if (context.mounted) {
                              setState(() => isSaving = false);
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const TranslatedText('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Text('Trip');

    final doc = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('trips')
        .doc(tripId);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: doc.snapshots(),
      builder: (context, snapshot) {
        final t = (snapshot.data?.data() ?? const {})['title'] as String?;
        final title = t == null || t.isEmpty ? 'Trip' : t;

        // Update AppBar title override for NavShell
        AppBarTitleController.instance.setOverride(title);

        return Row(
          children: [
            Expanded(child: Text(title)),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showEditDialog(context, title),
              tooltip: 'Edit Trip Name',
            ),
          ],
        );
      },
    );
  }
}

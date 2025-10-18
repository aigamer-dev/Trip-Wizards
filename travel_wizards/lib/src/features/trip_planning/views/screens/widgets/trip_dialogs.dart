import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:material_symbols_icons/symbols.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:travel_wizards/src/shared/services/invites_repository.dart';
import 'package:travel_wizards/src/shared/widgets/avatar/profile_avatar.dart';

/// Utility class for showing trip-related dialogs
class TripDialogs {
  TripDialogs._();

  /// Show invite dialog for adding buddies to a trip
  static Future<void> showInviteDialog(
    BuildContext context,
    String tripId,
  ) async {
    final controller = TextEditingController();
    final invitesRepo = InvitesRepository.instance;
    final messenger = ScaffoldMessenger.of(context);

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invite a buddy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email address',
                hintText: 'friend@example.com',
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  // Request contacts permission and show a bottom sheet selector
                  if (kIsWeb) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Contacts picker is not available on web',
                        ),
                      ),
                    );
                    return;
                  }

                  var status = await Permission.contacts.status;
                  if (status.isDenied) {
                    status = await Permission.contacts.request();
                  }

                  if (status.isGranted) {
                    try {
                      final contacts = await FlutterContacts.getContacts(
                        withProperties: true,
                      );
                      if (ctx.mounted) {
                        final selected = await showModalBottomSheet<Contact>(
                          context: ctx,
                          showDragHandle: true,
                          builder: (context) =>
                              _ContactPickerSheet(contacts: contacts),
                        );
                        if (selected != null &&
                            selected.emails.isNotEmpty &&
                            ctx.mounted) {
                          controller.text = selected.emails.first.address;
                        }
                      }
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Error accessing contacts: $e')),
                      );
                    }
                  } else {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Contacts permission is required'),
                      ),
                    );
                  }
                },
                icon: const Icon(Symbols.contacts_rounded),
                label: const Text('Contacts'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final email = controller.text.trim();
              if (email.isEmpty) return;

              Navigator.of(ctx).pop();

              try {
                await invitesRepo.sendInvite(tripId: tripId, email: email);
                messenger.showSnackBar(
                  SnackBar(content: Text('Invite sent to $email')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Failed to send invite: $e')),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  /// Show edit item dialog for trip items
  static Future<void> showEditItemDialog(
    BuildContext context,
    String tripId,
    String item,
    String category,
  ) async {
    final controller = TextEditingController(text: item);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('trips')
        .doc(tripId);

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit $category'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText:
                category.substring(0, 1).toUpperCase() + category.substring(1),
            hintText: 'Enter ${category.toLowerCase()}',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final snapshot = await doc.get();
                final data = snapshot.data() ?? {};
                final items = List<String>.from(data[category] ?? []);
                final index = items.indexOf(item);
                if (index != -1) {
                  items[index] = controller.text.trim();
                  await doc.update({category: items});
                }
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('$category updated')));
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

/// Contact picker bottom sheet widget
class _ContactPickerSheet extends StatelessWidget {
  const _ContactPickerSheet({required this.contacts});

  final List<Contact> contacts;

  @override
  Widget build(BuildContext context) {
    final contactsWithEmails = contacts
        .where((contact) => contact.emails.isNotEmpty)
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Select Contact',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: contactsWithEmails.isEmpty
                ? const Center(
                    child: Text('No contacts with email addresses found'),
                  )
                : ListView.builder(
                    itemCount: contactsWithEmails.length,
                    itemBuilder: (context, index) {
                      final contact = contactsWithEmails[index];
                      final email = contact.emails.first.address;

                      return ListTile(
                        leading: ProfileAvatar(
                          size: 40,
                          initials: contact.displayName.isNotEmpty
                              ? contact.displayName[0].toUpperCase()
                              : '?',
                        ),
                        title: Text(contact.displayName),
                        subtitle: Text(email),
                        onTap: () => Navigator.of(context).pop(contact),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travel_wizards/src/shared/widgets/spacing.dart';
import 'package:travel_wizards/src/shared/models/collaborative_trip.dart';
import 'package:travel_wizards/src/shared/services/collaborative_trip_service.dart';
import 'package:travel_wizards/src/shared/services/navigation_service.dart';
import 'package:travel_wizards/src/shared/widgets/translated_text.dart';
import 'package:travel_wizards/src/shared/widgets/avatar/profile_avatar.dart';

class TripCollaborationScreen extends StatefulWidget {
  final String tripId;

  const TripCollaborationScreen({super.key, required this.tripId});

  @override
  State<TripCollaborationScreen> createState() =>
      _TripCollaborationScreenState();
}

class _TripCollaborationScreenState extends State<TripCollaborationScreen>
    with TranslationMixin {
  final _collaborativeService = CollaborativeTripService.instance;
  final _inviteEmailController = TextEditingController();
  final _inviteMessageController = TextEditingController();
  TripRole _selectedRole = TripRole.viewer;
  bool _isInviting = false;

  @override
  void dispose() {
    _inviteEmailController.dispose();
    _inviteMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const TranslatedText('Trip Collaboration'),
        leading: const NavigationBackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showPermissionsDialog(),
            tooltip: 'Trip Permissions',
          ),
        ],
      ),
      body: StreamBuilder<CollaborativeTrip?>(
        stream: _collaborativeService.getTripStream(widget.tripId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  Gaps.h16,
                  TranslatedText(
                    'Error loading trip collaboration',
                    style: theme.textTheme.titleLarge,
                  ),
                  Gaps.h8,
                  TranslatedText(
                    snapshot.error.toString(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final trip = snapshot.data;
          if (trip == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.trip_origin,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  Gaps.h16,
                  const TranslatedText(
                    'Trip not found or access denied',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            );
          }

          return _buildCollaborationContent(trip, theme);
        },
      ),
    );
  }

  Widget _buildCollaborationContent(CollaborativeTrip trip, ThemeData theme) {
    return SingleChildScrollView(
      padding: Insets.allMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trip info card
          _buildTripInfoCard(trip, theme),
          Gaps.h24,

          // Members section
          _buildMembersSection(trip, theme),
          Gaps.h24,

          // Pending invitations
          if (trip.invitations.where((i) => i.isPending).isNotEmpty) ...[
            _buildPendingInvitationsSection(trip, theme),
            Gaps.h24,
          ],

          // Invite new member
          if (trip.canInvite(_collaborativeService.currentUserId ?? '')) ...[
            _buildInviteSection(trip, theme),
            Gaps.h24,
          ],

          // Activity log (simplified)
          _buildActivitySection(trip, theme),
        ],
      ),
    );
  }

  Widget _buildTripInfoCard(CollaborativeTrip trip, ThemeData theme) {
    return Card(
      child: Padding(
        padding: Insets.allMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.groups, color: theme.colorScheme.primary),
                Gaps.w8,
                Expanded(
                  child: Text(trip.title, style: theme.textTheme.titleLarge),
                ),
              ],
            ),
            Gaps.h8,
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                Gaps.w8,
                const TranslatedText('Owner'),
                Gaps.w8,
                Chip(
                  label: Text(
                    trip.ownerId == _collaborativeService.currentUserId
                        ? 'You'
                        : 'Other',
                  ),
                  backgroundColor: theme.colorScheme.primaryContainer,
                ),
              ],
            ),
            Gaps.h8,
            Row(
              children: [
                Icon(
                  Icons.group,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                Gaps.w8,
                TranslatedText('${trip.members.length + 1} members'),
                const Spacer(),
                if (trip.invitations.where((i) => i.isPending).isNotEmpty) ...[
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                  Gaps.w8,
                  TranslatedText(
                    '${trip.invitations.where((i) => i.isPending).length} pending',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersSection(CollaborativeTrip trip, ThemeData theme) {
    final currentUserId = _collaborativeService.currentUserId ?? '';
    final isOwner = trip.isOwner(currentUserId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Members', style: theme.textTheme.titleMedium),
        Gaps.h8,

        // Owner
        ListTile(
          leading: ProfileAvatar(
            initials: trip.ownerId.substring(0, 1).toUpperCase(),
            size: 40,
            semanticLabel: 'Trip Owner',
          ),
          title: Text(trip.ownerId == currentUserId ? 'You' : 'Trip Owner'),
          subtitle: const TranslatedText('Owner'),
          trailing: const Chip(
            label: Text('Owner'),
            backgroundColor: Colors.amber,
          ),
        ),

        // Members
        ...trip.members.map((member) {
          final isSelf = member.userId == currentUserId;
          return ListTile(
            leading: ProfileAvatar(
              photoUrl: member.photoUrl,
              size: 40,
              initials: member.displayNameOrEmail.substring(0, 1).toUpperCase(),
              semanticLabel: '${member.displayNameOrEmail} avatar',
            ),
            title: Text(isSelf ? 'You' : member.displayNameOrEmail),
            subtitle: Text(member.email),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Chip(
                  label: Text(member.role.displayName),
                  backgroundColor: _getRoleColor(member.role, theme),
                ),
                if (isOwner && !isSelf) ...[
                  Gaps.w8,
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (action) =>
                        _handleMemberAction(action, member, trip),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'change_role',
                        child: TranslatedText('Change Role'),
                      ),
                      const PopupMenuItem(
                        value: 'remove',
                        child: TranslatedText('Remove Member'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPendingInvitationsSection(
    CollaborativeTrip trip,
    ThemeData theme,
  ) {
    final pendingInvitations = trip.invitations
        .where((i) => i.isPending)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pending Invitations', style: theme.textTheme.titleMedium),
        Gaps.h8,
        ...pendingInvitations.map((invitation) {
          return ListTile(
            leading: ProfileAvatar(
              size: 40,
              icon: Icons.schedule,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
            title: Text(invitation.inviteeEmail),
            subtitle: Text('Invited as ${invitation.proposedRole.displayName}'),
            trailing: const Chip(
              label: Text('Pending'),
              backgroundColor: Colors.orange,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInviteSection(CollaborativeTrip trip, ThemeData theme) {
    return Card(
      child: Padding(
        padding: Insets.allMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invite New Member', style: theme.textTheme.titleMedium),
            Gaps.h8,
            Autocomplete<Map<String, String>>(
              optionsBuilder: (TextEditingValue textEditingValue) async {
                if (textEditingValue.text.length < 2) {
                  return const Iterable<Map<String, String>>.empty();
                }
                try {
                  final querySnapshot = await FirebaseFirestore.instance
                      .collection('users')
                      .where(
                        'email',
                        isGreaterThanOrEqualTo: textEditingValue.text
                            .toLowerCase(),
                      )
                      .where(
                        'email',
                        isLessThan: '${textEditingValue.text.toLowerCase()}z',
                      )
                      .limit(10)
                      .get();

                  return querySnapshot.docs
                      .map(
                        (doc) => {
                          'email': doc.data()['email'] as String? ?? '',
                          'name': doc.data()['displayName'] as String? ?? '',
                        },
                      )
                      .where((user) => user['email']!.isNotEmpty)
                      .toList();
                } catch (e) {
                  return const Iterable<Map<String, String>>.empty();
                }
              },
              displayStringForOption: (Map<String, String> option) =>
                  option['name']!.isNotEmpty
                  ? '${option['name']} (${option['email']})'
                  : option['email']!,
              onSelected: (Map<String, String> selection) {
                _inviteEmailController.text = selection['email']!;
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        hintText: 'Start typing to search users...',
                        helperText: 'Type at least 2 characters to search',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) {
                        _inviteEmailController.text = value;
                      },
                    );
                  },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);
                          return ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(
                              option['name']!.isNotEmpty
                                  ? option['name']!
                                  : option['email']!,
                            ),
                            subtitle: option['name']!.isNotEmpty
                                ? Text(option['email']!)
                                : null,
                            onTap: () {
                              onSelected(option);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            Gaps.h8,
            DropdownButtonFormField<TripRole>(
              initialValue: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Role',
                border: OutlineInputBorder(),
              ),
              items: TripRole.values.map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(role.displayName),
                      Text(role.description, style: theme.textTheme.bodySmall),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (role) {
                if (role != null) {
                  setState(() {
                    _selectedRole = role;
                  });
                }
              },
            ),
            Gaps.h8,
            TextFormField(
              controller: _inviteMessageController,
              decoration: const InputDecoration(
                labelText: 'Message (Optional)',
                hintText: 'Add a personal message',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            Gaps.h16,
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isInviting ? null : () => _sendInvitation(trip),
                icon: _isInviting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: const TranslatedText('Send Invitation'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySection(CollaborativeTrip trip, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Activity', style: theme.textTheme.titleMedium),
        Gaps.h8,
        Card(
          child: Padding(
            padding: Insets.allMd,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.edit, color: theme.colorScheme.primary),
                  title: TranslatedText(
                    'Trip last updated by ${trip.getLastUpdatedByName()}',
                  ),
                  subtitle: Text(
                    trip.updatedAt.toString().split(
                      '.',
                    )[0], // Simple date format
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.add_circle,
                    color: theme.colorScheme.tertiary,
                  ),
                  title: const TranslatedText('Trip created'),
                  subtitle: Text(
                    trip.createdAt.toString().split(
                      '.',
                    )[0], // Simple date format
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getRoleColor(TripRole role, ThemeData theme) {
    switch (role) {
      case TripRole.viewer:
        return theme.colorScheme.surfaceContainerHighest;
      case TripRole.editor:
        return theme.colorScheme.primaryContainer;
      case TripRole.admin:
        return theme.colorScheme.tertiaryContainer;
    }
  }

  Future<void> _sendInvitation(CollaborativeTrip trip) async {
    if (_inviteEmailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: TranslatedText('Please enter an email address'),
        ),
      );
      return;
    }

    setState(() {
      _isInviting = true;
    });

    try {
      // Directly add user as member instead of sending invitation
      await _collaborativeService.addMember(
        tripId: trip.id,
        userEmail: _inviteEmailController.text.trim(),
        role: _selectedRole,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: TranslatedText('Member added successfully')),
        );
        _inviteEmailController.clear();
        _inviteMessageController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: TranslatedText('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInviting = false;
        });
      }
    }
  }

  void _handleMemberAction(
    String action,
    TripMember member,
    CollaborativeTrip trip,
  ) {
    switch (action) {
      case 'change_role':
        _showChangeRoleDialog(member, trip);
        break;
      case 'remove':
        _showRemoveMemberDialog(member, trip);
        break;
    }
  }

  void _showChangeRoleDialog(TripMember member, CollaborativeTrip trip) {
    TripRole selectedRole = member.role;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const TranslatedText('Change Member Role'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Change role for ${member.displayNameOrEmail}'),
              Gaps.h16,
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final role in TripRole.values)
                    ListTile(
                      title: Text(role.displayName),
                      subtitle: Text(role.description),
                      leading: Icon(
                        selectedRole == role
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                      ),
                      onTap: () {
                        setState(() {
                          selectedRole = role;
                        });
                      },
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const TranslatedText('Cancel'),
            ),
            FilledButton(
              onPressed: selectedRole == member.role
                  ? null
                  : () async {
                      try {
                        await _collaborativeService.updateMemberRole(
                          trip.id,
                          member.userId,
                          selectedRole,
                        );
                        if (mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: TranslatedText('Member role updated'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: TranslatedText('Error: ${e.toString()}'),
                            ),
                          );
                        }
                      }
                    },
              child: const TranslatedText('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveMemberDialog(TripMember member, CollaborativeTrip trip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const TranslatedText('Remove Member'),
        content: TranslatedText(
          'Are you sure you want to remove ${member.displayNameOrEmail} from this trip?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const TranslatedText('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await _collaborativeService.removeMember(
                  trip.id,
                  member.userId,
                );
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: TranslatedText('Member removed')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: TranslatedText('Error: ${e.toString()}')),
                  );
                }
              }
            },
            child: const TranslatedText('Remove'),
          ),
        ],
      ),
    );
  }

  void _showPermissionsDialog() {
    TripPermissions? pendingPermissions;
    var isSaving = false;

    showDialog<void>(
      context: context,
      barrierDismissible: !isSaving,
      builder: (dialogContext) {
        return FutureBuilder<CollaborativeTrip?>(
          future: _collaborativeService.getTrip(widget.tripId),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const AlertDialog(
                title: TranslatedText('Trip Permissions'),
                content: SizedBox(
                  height: 96,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            if (snapshot.hasError || snapshot.data == null) {
              return AlertDialog(
                title: const TranslatedText('Trip Permissions'),
                content: TranslatedText(
                  snapshot.hasError
                      ? snapshot.error.toString()
                      : 'Unable to load trip permissions',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const TranslatedText('Close'),
                  ),
                ],
              );
            }

            final trip = snapshot.data!;
            final canEdit = trip.ownerId == _collaborativeService.currentUserId;

            return StatefulBuilder(
              builder: (context, setStateDialog) {
                final permissions = pendingPermissions ?? trip.permissions;

                Future<void> savePermissions() async {
                  if (!canEdit || isSaving) return;
                  setStateDialog(() {
                    isSaving = true;
                  });

                  try {
                    await _collaborativeService.updateTripPermissions(
                      trip.id,
                      pendingPermissions ?? trip.permissions,
                    );

                    if (mounted) {
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: TranslatedText('Permissions updated'),
                        ),
                      );
                    }
                  } catch (e) {
                    setStateDialog(() {
                      isSaving = false;
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: TranslatedText('Error: ${e.toString()}'),
                        ),
                      );
                    }
                  }
                }

                return AlertDialog(
                  title: const TranslatedText('Trip Permissions'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!canEdit)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              'Only the trip owner can edit these settings.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        SwitchListTile(
                          value: permissions.allowMemberInvites,
                          onChanged: canEdit
                              ? (value) {
                                  setStateDialog(() {
                                    pendingPermissions = permissions.copyWith(
                                      allowMemberInvites: value,
                                    );
                                  });
                                }
                              : null,
                          title: const TranslatedText('Allow member invites'),
                          subtitle: const TranslatedText(
                            'Enable admins to invite new collaborators',
                          ),
                        ),
                        SwitchListTile(
                          value: permissions.allowMemberEdit,
                          onChanged: canEdit
                              ? (value) {
                                  setStateDialog(() {
                                    pendingPermissions = permissions.copyWith(
                                      allowMemberEdit: value,
                                    );
                                  });
                                }
                              : null,
                          title: const TranslatedText('Allow member edits'),
                          subtitle: const TranslatedText(
                            'Let collaborators update trip details',
                          ),
                        ),
                        SwitchListTile(
                          value: permissions.allowMemberDelete,
                          onChanged: canEdit
                              ? (value) {
                                  setStateDialog(() {
                                    pendingPermissions = permissions.copyWith(
                                      allowMemberDelete: value,
                                    );
                                  });
                                }
                              : null,
                          title: const TranslatedText('Allow member deletions'),
                          subtitle: const TranslatedText(
                            'Permit admins to remove places and notes',
                          ),
                        ),
                        SwitchListTile(
                          value: permissions.requireApprovalForChanges,
                          onChanged: canEdit
                              ? (value) {
                                  setStateDialog(() {
                                    pendingPermissions = permissions.copyWith(
                                      requireApprovalForChanges: value,
                                    );
                                  });
                                }
                              : null,
                          title: const TranslatedText(
                            'Require approval for changes',
                          ),
                          subtitle: const TranslatedText(
                            'Owner reviews edits before they go live',
                          ),
                        ),
                        SwitchListTile(
                          value: permissions.allowPublicSharing,
                          onChanged: canEdit
                              ? (value) {
                                  setStateDialog(() {
                                    pendingPermissions = permissions.copyWith(
                                      allowPublicSharing: value,
                                    );
                                  });
                                }
                              : null,
                          title: const TranslatedText('Allow public sharing'),
                          subtitle: const TranslatedText(
                            'Generate a view-only link for this trip',
                          ),
                        ),
                      ],
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
                      onPressed: (!canEdit || isSaving)
                          ? null
                          : () {
                              savePermissions();
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
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:travel_wizards/src/common/ui/spacing.dart';
import 'package:travel_wizards/src/models/collaborative_trip.dart';
import 'package:travel_wizards/src/services/collaborative_trip_service.dart';
import 'package:travel_wizards/src/widgets/translated_text.dart';

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
          leading: CircleAvatar(
            child: Text(trip.ownerId.substring(0, 1).toUpperCase()),
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
            leading: CircleAvatar(
              backgroundImage: member.photoUrl != null
                  ? NetworkImage(member.photoUrl!)
                  : null,
              child: member.photoUrl == null
                  ? Text(
                      member.displayNameOrEmail.substring(0, 1).toUpperCase(),
                    )
                  : null,
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
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.schedule),
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
            TextFormField(
              controller: _inviteEmailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'Enter email to invite',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            Gaps.h8,
            DropdownButtonFormField<TripRole>(
              value: _selectedRole,
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
      await _collaborativeService.inviteUser(
        tripId: trip.id,
        inviteeEmail: _inviteEmailController.text.trim(),
        role: _selectedRole,
        message: _inviteMessageController.text.trim().isEmpty
            ? null
            : _inviteMessageController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: TranslatedText('Invitation sent successfully'),
          ),
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
              ...TripRole.values.map((role) {
                return RadioListTile<TripRole>(
                  title: Text(role.displayName),
                  subtitle: Text(role.description),
                  value: role,
                  groupValue: selectedRole,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedRole = value;
                      });
                    }
                  },
                );
              }),
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
    // TODO: Implement permissions dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: TranslatedText('Permissions settings coming soon'),
      ),
    );
  }
}

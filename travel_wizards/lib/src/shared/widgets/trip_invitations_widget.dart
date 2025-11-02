import 'package:flutter/material.dart';
import 'package:travel_wizards/src/shared/widgets/spacing.dart';
import 'package:travel_wizards/src/shared/models/collaborative_trip.dart';
import 'package:travel_wizards/src/shared/services/collaborative_trip_service.dart';
import 'package:travel_wizards/src/shared/widgets/avatar/profile_avatar.dart';

class TripInvitationsWidget extends StatelessWidget {
  final List<TripInvitation> invitations;
  final String tripId;

  const TripInvitationsWidget({
    super.key,
    required this.invitations,
    required this.tripId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pendingInvitations = invitations.where((i) => i.isPending).toList();

    if (pendingInvitations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: Insets.allMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pending_actions, color: theme.colorScheme.primary),
                Gaps.w8,
                Text('Pending Invitations', style: theme.textTheme.titleMedium),
              ],
            ),
            Gaps.h16,
            ...pendingInvitations.map(
              (invitation) => _buildInvitationTile(invitation, theme, context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitationTile(
    TripInvitation invitation,
    ThemeData theme,
    BuildContext context,
  ) {
    final currentUserId = CollaborativeTripService.instance.currentUserId;
    final isCurrentUser =
        invitation.inviteeEmail == currentUserId; // Simplified check

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: ProfileAvatar(
          size: 40,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          icon: Icons.person_add,
        ),
        title: Text(invitation.inviteeEmail),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invited as ${invitation.proposedRole.name}'),
            if (invitation.message?.isNotEmpty == true) ...[
              Gaps.h8,
              Text(
                invitation.message!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        trailing: isCurrentUser
            ? _buildInvitationActions(invitation, context)
            : Chip(
                label: const Text('Pending'),
                backgroundColor: Colors.orange.shade100,
              ),
      ),
    );
  }

  Widget _buildInvitationActions(
    TripInvitation invitation,
    BuildContext context,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.check_circle, color: Colors.green),
          onPressed: () => _respondToInvitation(invitation, true, context),
          tooltip: 'Accept',
        ),
        IconButton(
          icon: const Icon(Icons.cancel, color: Colors.red),
          onPressed: () => _respondToInvitation(invitation, false, context),
          tooltip: 'Decline',
        ),
      ],
    );
  }

  Future<void> _respondToInvitation(
    TripInvitation invitation,
    bool accept,
    BuildContext context,
  ) async {
    try {
      await CollaborativeTripService.instance.respondToInvitation(
        tripId,
        invitation.id,
        accept,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accept ? 'Invitation accepted' : 'Invitation declined',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

/// Extension to add display functionality to TripRole
extension TripRoleDisplay on TripRole {
  String get displayName {
    switch (this) {
      case TripRole.viewer:
        return 'Viewer';
      case TripRole.editor:
        return 'Editor';
      case TripRole.admin:
        return 'Admin';
    }
  }

  String get description {
    switch (this) {
      case TripRole.viewer:
        return 'Can view trip details only';
      case TripRole.editor:
        return 'Can edit trip content';
      case TripRole.admin:
        return 'Can manage members and settings';
    }
  }
}

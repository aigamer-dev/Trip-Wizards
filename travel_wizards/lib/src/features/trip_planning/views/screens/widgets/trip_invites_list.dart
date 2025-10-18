import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:travel_wizards/src/shared/services/invites_repository.dart';

/// A widget that displays and manages trip invites.
///
/// Shows all invites for a trip with their status and provides actions
/// for accepting, declining, or removing pending invites.
class TripInvitesList extends StatelessWidget {
  const TripInvitesList({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Invite>>(
      stream: InvitesRepository.instance.watchInvites(tripId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: LinearProgressIndicator(),
          );
        }

        final invites = snapshot.data ?? const <Invite>[];
        if (invites.isEmpty) {
          return _buildEmptyState(context);
        }

        return Column(children: invites.map(_buildInviteCard).toList());
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        'No invites yet. Use the Invite button to add buddies.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildInviteCard(Invite invite) {
    return Builder(
      builder: (context) {
        final isPending = invite.status == 'pending';

        return Card(
          child: ListTile(
            leading: const Icon(Symbols.mail_rounded),
            title: Text(invite.email),
            subtitle: Text('Status: ${invite.status}'),
            trailing: _buildInviteActions(context, invite, isPending),
          ),
        );
      },
    );
  }

  Widget _buildInviteActions(
    BuildContext context,
    Invite invite,
    bool isPending,
  ) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        Text(
          invite.createdAt.toLocal().toString().split('.').first,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (isPending) ..._buildPendingActions(invite),
      ],
    );
  }

  List<Widget> _buildPendingActions(Invite invite) {
    return [
      TextButton(
        onPressed: () => _acceptInvite(invite),
        child: const Text('Accept'),
      ),
      TextButton(
        onPressed: () => _declineInvite(invite),
        child: const Text('Decline'),
      ),
      IconButton(
        tooltip: 'Remove invite',
        icon: const Icon(Symbols.delete_rounded),
        onPressed: () => _removeInvite(invite),
      ),
    ];
  }

  Future<void> _acceptInvite(Invite invite) async {
    await InvitesRepository.instance.updateInviteStatus(
      tripId: tripId,
      inviteId: invite.id,
      status: 'accepted',
    );
  }

  Future<void> _declineInvite(Invite invite) async {
    await InvitesRepository.instance.updateInviteStatus(
      tripId: tripId,
      inviteId: invite.id,
      status: 'declined',
    );
  }

  Future<void> _removeInvite(Invite invite) async {
    await InvitesRepository.instance.cancelInvite(
      tripId: tripId,
      inviteId: invite.id,
    );
  }
}

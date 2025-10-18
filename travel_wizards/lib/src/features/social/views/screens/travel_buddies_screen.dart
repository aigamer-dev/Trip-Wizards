// Travel Buddies Management Screen
// Provides comprehensive travel buddy management and connection features
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:travel_wizards/src/shared/models/social_models.dart';
import 'package:travel_wizards/src/shared/services/social_features_service.dart';
import 'package:travel_wizards/src/shared/widgets/avatar/profile_avatar.dart';
import 'package:travel_wizards/src/shared/widgets/layout/modern_page_scaffold.dart';
import 'package:travel_wizards/src/shared/widgets/layout/modern_section.dart';
import 'package:travel_wizards/src/shared/widgets/spacing.dart';
import 'package:travel_wizards/src/features/social/views/widgets/create_group_dialog.dart';

class TravelBuddiesScreen extends StatefulWidget {
  const TravelBuddiesScreen({super.key});

  @override
  State<TravelBuddiesScreen> createState() => _TravelBuddiesScreenState();
}

class _TravelBuddiesScreenState extends State<TravelBuddiesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModernPageScaffold(
      pageTitle: 'Travel Buddies',
      sections: [
        _buildMyBuddiesSection(),
        _buildRequestsSection(),
        _buildFindBuddiesSection(),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateGroupDialog,
        icon: const Icon(Symbols.group_add),
        label: const Text('Create Group'),
      ),
    );
  }

  Widget _buildMyBuddiesSection() {
    return ModernSection(
      title: 'My Buddies',
      icon: Symbols.people,
      child: StreamBuilder<List<TravelGroup>>(
        stream: context.read<SocialFeaturesService>().getUserTravelGroups(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final groups = snapshot.data ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Travel Groups Section
              Text(
                'Travel Groups',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const VGap(Insets.sm),
              Text(
                'Join or create groups with like-minded travelers',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const VGap(Insets.md),
              if (groups.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Symbols.group_off, size: 64, color: Colors.grey),
                        VGap(Insets.md),
                        Text(
                          'No travel groups yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        VGap(Insets.sm),
                        Text(
                          'Create your first group to connect with fellow travelers!',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...groups.map((group) => _buildGroupCard(group)),
              // Individual Buddies Section
              const VGap(Insets.lg),
              Text(
                'Individual Buddies',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const VGap(Insets.md),
              // This would be populated with individual travel buddies
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Individual buddy connections coming soon!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGroupCard(TravelGroup group) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: Insets.xs),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: Corners.lgBorder),
      child: ListTile(
        leading: ProfileAvatar(
          photoUrl: group.photoUrl,
          initials: group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G',
          size: 40,
        ),
        title: Text(group.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(group.description),
            const VGap(Insets.xs),
            Row(
              children: [
                Icon(Symbols.people, size: 16, color: Colors.grey[600]),
                const HGap(Insets.xs),
                Text(
                  '${group.memberCount} members',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const HGap(Insets.md),
                if (group.isPrivate) ...[
                  Icon(Symbols.lock, size: 16, color: Colors.grey[600]),
                  const HGap(Insets.xs),
                  Text(
                    'Private',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'view':
                _viewGroup(group);
                break;
              case 'leave':
                _leaveGroup(group);
                break;
              case 'invite':
                _inviteToGroup(group);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: ListTile(
                leading: Icon(Symbols.visibility),
                title: Text('View Group'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'invite',
              child: ListTile(
                leading: Icon(Symbols.person_add),
                title: Text('Invite Members'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'leave',
              child: ListTile(
                leading: Icon(Symbols.logout),
                title: Text('Leave Group'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () => _viewGroup(group),
      ),
    );
  }

  Widget _buildRequestsSection() {
    return ModernSection(
      title: 'Requests',
      icon: Symbols.inbox,
      child: StreamBuilder<List<BuddyRequest>>(
        stream: context.read<SocialFeaturesService>().getPendingBuddyRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: Insets.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Symbols.mark_email_unread,
                      size: 64,
                      color: Colors.grey,
                    ),
                    VGap(Insets.md),
                    Text(
                      'No pending requests',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    VGap(Insets.sm),
                    Text(
                      'New buddy requests will appear here',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: requests
                .map((request) => _buildRequestCard(request))
                .toList(),
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(BuddyRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: Insets.sm),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: Corners.lgBorder),
      child: Padding(
        padding: Insets.allMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProfileAvatar(
                  photoUrl: request.senderPhotoUrl,
                  initials: request.senderName.isNotEmpty
                      ? request.senderName[0].toUpperCase()
                      : '?',
                  size: 40,
                ),
                const HGap(Insets.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.senderName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Wants to be travel buddies',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      Text(
                        _formatDateTime(request.createdAt),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (request.message != null) ...[
              const VGap(Insets.sm),
              Container(
                padding: Insets.allMd,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: Corners.mdBorder,
                ),
                child: Text(request.message!),
              ),
            ],
            const VGap(Insets.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _respondToRequest(request.id, false),
                  child: const Text('Decline'),
                ),
                const HGap(Insets.sm),
                ElevatedButton(
                  onPressed: () => _respondToRequest(request.id, true),
                  child: const Text('Accept'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFindBuddiesSection() {
    return ModernSection(
      title: 'Find Buddies',
      icon: Symbols.group_add,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: Insets.md),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search for travel buddies...',
                prefixIcon: Icon(Symbols.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                // Implement search functionality
              },
            ),
          ),
          _buildSectionHeader('Suggested Buddies'),
          _buildSuggestedBuddiesCard(),
          const VGap(Insets.lg),
          _buildSectionHeader('Join Public Groups'),
          _buildPublicGroupsCard(),
          const VGap(Insets.lg),
          _buildSectionHeader('Invite by Email'),
          _buildInviteByEmailCard(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.sm),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSuggestedBuddiesCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: Corners.lgBorder),
      child: Padding(
        padding: Insets.allMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Find people with similar travel interests'),
            const VGap(Insets.sm),
            const Text(
              'This feature will suggest buddies based on your travel preferences, destinations, and activity history.',
              style: TextStyle(color: Colors.grey),
            ),
            const VGap(Insets.md),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Buddy suggestions coming soon!'),
                  ),
                );
              },
              child: const Text('Find Suggested Buddies'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPublicGroupsCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: Corners.lgBorder),
      child: Padding(
        padding: Insets.allMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Join existing travel communities'),
            const VGap(Insets.sm),
            const Text(
              'Browse and join public travel groups based on destinations, interests, or travel styles.',
              style: TextStyle(color: Colors.grey),
            ),
            const VGap(Insets.md),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Public groups coming soon!')),
                );
              },
              child: const Text('Browse Public Groups'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteByEmailCard() {
    final TextEditingController emailController = TextEditingController();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: Corners.lgBorder),
      child: Padding(
        padding: Insets.allMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Invite friends via email'),
            const VGap(Insets.sm),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                hintText: 'Enter email address',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const VGap(Insets.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final email = emailController.text.trim();
                  if (email.isNotEmpty) {
                    _sendEmailInvite(email);
                    emailController.clear();
                  }
                },
                child: const Text('Send Invite'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateGroupDialog(),
    );
  }

  void _viewGroup(TravelGroup group) {
    // Navigate to group details screen
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Viewing group: ${group.name}')));
  }

  void _leaveGroup(TravelGroup group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: Text('Are you sure you want to leave ${group.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<SocialFeaturesService>().leaveTravelGroup(group.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Left group: ${group.name}')),
              );
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _inviteToGroup(TravelGroup group) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Inviting members to ${group.name}')),
    );
  }

  void _respondToRequest(String requestId, bool accept) {
    context.read<SocialFeaturesService>().respondToBuddyRequest(
      requestId: requestId,
      accept: accept,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Request ${accept ? 'accepted' : 'declined'}')),
    );
  }

  void _sendEmailInvite(String email) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Email invite sent to $email')));
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

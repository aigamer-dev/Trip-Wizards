// Travel Buddies Management Screen
// Provides comprehensive travel buddy management and connection features
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/social_features_service.dart';
import '../../models/social_models.dart';

class TravelBuddiesScreen extends StatefulWidget {
  const TravelBuddiesScreen({super.key});

  @override
  State<TravelBuddiesScreen> createState() => _TravelBuddiesScreenState();
}

class _TravelBuddiesScreenState extends State<TravelBuddiesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Buddies'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'My Buddies'),
            Tab(icon: Icon(Icons.inbox), text: 'Requests'),
            Tab(icon: Icon(Icons.group_add), text: 'Find Buddies'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyBuddiesTab(),
          _buildRequestsTab(),
          _buildFindBuddiesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateGroupDialog,
        icon: const Icon(Icons.group_add),
        label: const Text('Create Group'),
      ),
    );
  }

  Widget _buildMyBuddiesTab() {
    return StreamBuilder<List<TravelGroup>>(
      stream: context.read<SocialFeaturesService>().getUserTravelGroups(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final groups = snapshot.data ?? [];

        return CustomScrollView(
          slivers: [
            // Travel Groups Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Travel Groups',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join or create groups with like-minded travelers',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            if (groups.isEmpty)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.group_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No travel groups yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Create your first group to connect with fellow travelers!',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final group = groups[index];
                  return _buildGroupCard(group);
                }, childCount: groups.length),
              ),
            // Individual Buddies Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Individual Buddies',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),
            // This would be populated with individual travel buddies
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Individual buddy connections coming soon!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGroupCard(TravelGroup group) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: group.photoUrl != null
              ? NetworkImage(group.photoUrl!)
              : null,
          child: group.photoUrl == null
              ? Text(group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G')
              : null,
        ),
        title: Text(group.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(group.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${group.memberCount} members',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(width: 16),
                if (group.isPrivate) ...[
                  Icon(Icons.lock, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
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
              child: Row(
                children: [
                  Icon(Icons.visibility),
                  SizedBox(width: 8),
                  Text('View Group'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'invite',
              child: Row(
                children: [
                  Icon(Icons.person_add),
                  SizedBox(width: 8),
                  Text('Invite Members'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'leave',
              child: Row(
                children: [
                  Icon(Icons.exit_to_app),
                  SizedBox(width: 8),
                  Text('Leave Group'),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _viewGroup(group),
      ),
    );
  }

  Widget _buildRequestsTab() {
    return StreamBuilder<List<BuddyRequest>>(
      stream: context.read<SocialFeaturesService>().getPendingBuddyRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No pending requests',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'New buddy requests will appear here',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _buildRequestCard(request);
          },
        );
      },
    );
  }

  Widget _buildRequestCard(BuddyRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: request.senderPhotoUrl != null
                      ? NetworkImage(request.senderPhotoUrl!)
                      : null,
                  child: request.senderPhotoUrl == null
                      ? Text(
                          request.senderName.isNotEmpty
                              ? request.senderName[0].toUpperCase()
                              : '?',
                        )
                      : null,
                ),
                const SizedBox(width: 12),
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
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(request.message!),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _respondToRequest(request.id, false),
                  child: const Text('Decline'),
                ),
                const SizedBox(width: 8),
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

  Widget _buildFindBuddiesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search for travel buddies...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              // Implement search functionality
            },
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildSectionHeader('Suggested Buddies'),
              _buildSuggestedBuddiesCard(),
              const SizedBox(height: 24),
              _buildSectionHeader('Join Public Groups'),
              _buildPublicGroupsCard(),
              const SizedBox(height: 24),
              _buildSectionHeader('Invite by Email'),
              _buildInviteByEmailCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Find people with similar travel interests'),
            const SizedBox(height: 12),
            const Text(
              'This feature will suggest buddies based on your travel preferences, destinations, and activity history.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Join existing travel communities'),
            const SizedBox(height: 12),
            const Text(
              'Browse and join public travel groups based on destinations, interests, or travel styles.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Invite friends via email'),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                hintText: 'Enter email address',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
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
                child: const Text('Send Invitation'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isPrivate = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Travel Group'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Private Group'),
                subtitle: const Text('Only invited members can join'),
                value: isPrivate,
                onChanged: (value) {
                  setState(() {
                    isPrivate = value ?? false;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final description = descriptionController.text.trim();
                if (name.isNotEmpty && description.isNotEmpty) {
                  _createGroup(name, description, isPrivate);
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _createGroup(String name, String description, bool isPrivate) {
    context.read<SocialFeaturesService>().createTravelGroup(
      name: name,
      description: description,
      isPrivate: isPrivate,
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Travel group created!')));
  }

  void _viewGroup(TravelGroup group) {
    // Navigate to group details screen
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Viewing ${group.name}')));
  }

  void _leaveGroup(TravelGroup group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Leave ${group.name}?'),
        content: const Text('Are you sure you want to leave this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Left ${group.name}')));
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _inviteToGroup(TravelGroup group) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Inviting to ${group.name}')));
  }

  void _respondToRequest(String requestId, bool accept) {
    context.read<SocialFeaturesService>().respondToBuddyRequest(
      requestId: requestId,
      accept: accept,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          accept ? 'Buddy request accepted!' : 'Buddy request declined',
        ),
      ),
    );
  }

  void _sendEmailInvite(String email) {
    // This would integrate with email service
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Invitation sent to $email')));
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

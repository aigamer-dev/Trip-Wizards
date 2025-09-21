// Enhanced Social Features Screen for Travel Wizards
// Provides comprehensive social interaction UI beyond basic collaboration
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/social_features_service.dart';
import '../../models/social_models.dart';

class SocialFeaturesScreen extends StatefulWidget {
  final String tripId;

  const SocialFeaturesScreen({super.key, required this.tripId});

  @override
  State<SocialFeaturesScreen> createState() => _SocialFeaturesScreenState();
}

class _SocialFeaturesScreenState extends State<SocialFeaturesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Social Hub'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.comment_rounded), text: 'Comments'),
            Tab(icon: Icon(Icons.favorite_rounded), text: 'Reactions'),
            Tab(icon: Icon(Icons.timeline_rounded), text: 'Activity'),
            Tab(icon: Icon(Icons.photo_album_rounded), text: 'Photos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCommentsTab(),
          _buildReactionsTab(),
          _buildActivityTab(),
          _buildPhotosTab(),
        ],
      ),
    );
  }

  Widget _buildCommentsTab() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<TripComment>>(
            stream: context.read<SocialFeaturesService>().getTripComments(
              widget.tripId,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error loading comments: ${snapshot.error}'),
                );
              }

              final comments = snapshot.data ?? [];

              if (comments.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.comment_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No comments yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Be the first to share your thoughts!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  return _buildCommentCard(comment);
                },
              );
            },
          ),
        ),
        _buildCommentInput(),
      ],
    );
  }

  Widget _buildCommentCard(TripComment comment) {
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
                  backgroundImage: comment.authorPhotoUrl != null
                      ? NetworkImage(comment.authorPhotoUrl!)
                      : null,
                  child: comment.authorPhotoUrl == null
                      ? Text(
                          comment.authorName.isNotEmpty
                              ? comment.authorName[0].toUpperCase()
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
                        comment.authorName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _formatDateTime(comment.createdAt),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'reply':
                        _replyToComment(comment);
                        break;
                      case 'report':
                        _reportComment(comment);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'reply',
                      child: Row(
                        children: [
                          Icon(Icons.reply),
                          SizedBox(width: 8),
                          Text('Reply'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.report),
                          SizedBox(width: 8),
                          Text('Report'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(comment.content),
            if (comment.mentionedUserIds.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: comment.mentionedUserIds.map((userId) {
                  return Chip(
                    label: Text('@User'),
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    labelStyle: const TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _likeComment(comment),
                  icon: Icon(
                    Icons.favorite,
                    size: 16,
                    color: comment.likeCount > 0 ? Colors.red : Colors.grey,
                  ),
                  label: Text('${comment.likeCount}'),
                ),
                TextButton.icon(
                  onPressed: () => _replyToComment(comment),
                  icon: const Icon(Icons.reply, size: 16),
                  label: const Text('Reply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: 'Add a comment...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submitComment(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _submitComment,
              icon: const Icon(Icons.send),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionsTab() {
    return StreamBuilder<Map<TripReactionType, List<TripReaction>>>(
      stream: context.read<SocialFeaturesService>().getTripReactions(
        widget.tripId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final reactionsMap = snapshot.data ?? {};

        return Column(
          children: [
            // Reaction buttons
            Container(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                children: TripReactionType.values.map((type) {
                  final reactions = reactionsMap[type] ?? [];
                  final hasUserReacted = reactions.any(
                    (r) =>
                        r.userId ==
                        context.read<SocialFeaturesService>().currentUserId,
                  );

                  return FilterChip(
                    label: Text(
                      '${_getReactionEmoji(type)} ${reactions.length}',
                    ),
                    selected: hasUserReacted,
                    onSelected: (selected) {
                      if (selected) {
                        context.read<SocialFeaturesService>().addTripReaction(
                          tripId: widget.tripId,
                          reactionType: type,
                        );
                      } else {
                        context
                            .read<SocialFeaturesService>()
                            .removeTripReaction(tripId: widget.tripId);
                      }
                    },
                  );
                }).toList(),
              ),
            ),
            // Reactions list
            Expanded(
              child: ListView(
                children: reactionsMap.entries.map((entry) {
                  final type = entry.key;
                  final reactions = entry.value;

                  if (reactions.isEmpty) return const SizedBox.shrink();

                  return ExpansionTile(
                    title: Text(
                      '${_getReactionEmoji(type)} ${_getReactionName(type)}',
                    ),
                    subtitle: Text('${reactions.length} reactions'),
                    children: reactions.map((reaction) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: reaction.userPhotoUrl != null
                              ? NetworkImage(reaction.userPhotoUrl!)
                              : null,
                          child: reaction.userPhotoUrl == null
                              ? Text(
                                  reaction.userName.isNotEmpty
                                      ? reaction.userName[0].toUpperCase()
                                      : '?',
                                )
                              : null,
                        ),
                        title: Text(reaction.userName),
                        subtitle: Text(_formatDateTime(reaction.createdAt)),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActivityTab() {
    return StreamBuilder<List<ActivityFeedItem>>(
      stream: context.read<SocialFeaturesService>().getTripActivityFeed(
        widget.tripId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final activities = snapshot.data ?? [];

        if (activities.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timeline_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No activity yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            return _buildActivityCard(activity);
          },
        );
      },
    );
  }

  Widget _buildActivityCard(ActivityFeedItem activity) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: activity.userPhotoUrl != null
              ? NetworkImage(activity.userPhotoUrl!)
              : null,
          child: activity.userPhotoUrl == null
              ? Icon(_getActivityIcon(activity.activityType))
              : null,
        ),
        title: Text(activity.description),
        subtitle: Text(_formatDateTime(activity.createdAt)),
        trailing: Icon(_getActivityIcon(activity.activityType)),
      ),
    );
  }

  Widget _buildPhotosTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_album_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Photo albums coming soon',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _submitComment() {
    final content = _commentController.text.trim();
    if (content.isNotEmpty) {
      context.read<SocialFeaturesService>().addTripComment(
        tripId: widget.tripId,
        content: content,
      );
      _commentController.clear();
    }
  }

  void _replyToComment(TripComment comment) {
    _commentController.text = '@${comment.authorName} ';
    _commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commentController.text.length),
    );
  }

  void _reportComment(TripComment comment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Comment'),
        content: const Text('Are you sure you want to report this comment?'),
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
              ).showSnackBar(const SnackBar(content: Text('Comment reported')));
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _likeComment(TripComment comment) {
    // This would update the comment like count
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Comment liked!')));
  }

  String _getReactionEmoji(TripReactionType type) {
    switch (type) {
      case TripReactionType.like:
        return '👍';
      case TripReactionType.love:
        return '❤️';
      case TripReactionType.excited:
        return '🤩';
      case TripReactionType.thumbsUp:
        return '👍';
      case TripReactionType.helpful:
        return '💡';
      case TripReactionType.wow:
        return '😮';
    }
  }

  String _getReactionName(TripReactionType type) {
    switch (type) {
      case TripReactionType.like:
        return 'Like';
      case TripReactionType.love:
        return 'Love';
      case TripReactionType.excited:
        return 'Excited';
      case TripReactionType.thumbsUp:
        return 'Thumbs Up';
      case TripReactionType.helpful:
        return 'Helpful';
      case TripReactionType.wow:
        return 'Wow';
    }
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.tripCreated:
        return Icons.add_circle;
      case ActivityType.tripUpdated:
        return Icons.edit;
      case ActivityType.memberAdded:
        return Icons.person_add;
      case ActivityType.memberRemoved:
        return Icons.person_remove;
      case ActivityType.commentAdded:
        return Icons.comment;
      case ActivityType.reactionAdded:
        return Icons.favorite;
      case ActivityType.photoAdded:
        return Icons.photo;
      case ActivityType.itineraryUpdated:
        return Icons.schedule;
      case ActivityType.bookingConfirmed:
        return Icons.confirmation_number;
      case ActivityType.checkIn:
        return Icons.location_on;
      case ActivityType.checkOut:
        return Icons.location_off;
      case ActivityType.emergencyAlert:
        return Icons.emergency;
    }
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

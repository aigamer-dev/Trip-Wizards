// Enhanced Social Features Screen for Travel Wizards
// Provides comprehensive social interaction UI beyond basic collaboration
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:travel_wizards/src/shared/models/social_models.dart';
import 'package:travel_wizards/src/shared/services/social_features_service.dart';
import 'package:travel_wizards/src/shared/widgets/avatar/profile_avatar.dart';
import 'package:travel_wizards/src/shared/widgets/layout/modern_page_scaffold.dart';
import 'package:travel_wizards/src/shared/widgets/layout/modern_section.dart';
import 'package:travel_wizards/src/shared/widgets/spacing.dart';

class SocialFeaturesScreen extends StatefulWidget {
  final String tripId;

  const SocialFeaturesScreen({super.key, required this.tripId});

  @override
  State<SocialFeaturesScreen> createState() => _SocialFeaturesScreenState();
}

class _SocialFeaturesScreenState extends State<SocialFeaturesScreen> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModernPageScaffold(
      pageTitle: 'Trip Social Hub',
      sections: [
        _buildCommentsSection(),
        _buildReactionsSection(),
        _buildActivitySection(),
        _buildPhotosSection(),
      ],
      floatingActionButton: _buildCommentInput(),
    );
  }

  Widget _buildCommentsSection() {
    return ModernSection(
      title: 'Comments',
      icon: Symbols.comment,
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
                  Icon(Symbols.forum, size: 64, color: Colors.grey),
                  VGap(Insets.md),
                  Text(
                    'No comments yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  VGap(Insets.sm),
                  Text(
                    'Be the first to share your thoughts!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: comments
                .map((comment) => _buildCommentCard(comment))
                .toList(),
          );
        },
      ),
    );
  }

  Widget _buildCommentCard(TripComment comment) {
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
                  photoUrl: comment.authorPhotoUrl,
                  initials: comment.authorName,
                  size: 40,
                ),
                const HGap(Insets.sm),
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
                      child: ListTile(
                        leading: Icon(Symbols.reply),
                        title: Text('Reply'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'report',
                      child: ListTile(
                        leading: Icon(Symbols.report),
                        title: Text('Report'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const VGap(Insets.sm),
            Text(comment.content),
            if (comment.mentionedUserIds.isNotEmpty) ...[
              const VGap(Insets.sm),
              Wrap(
                spacing: 4,
                children: comment.mentionedUserIds.map((userId) {
                  return Chip(
                    label: const Text('@User'),
                    backgroundColor: Colors.blue.withAlpha((0.1 * 255).toInt()),
                    labelStyle: const TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
            ],
            const VGap(Insets.sm),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _likeComment(comment),
                  icon: Icon(
                    Symbols.favorite,
                    size: 16,
                    color: comment.likeCount > 0 ? Colors.red : Colors.grey,
                  ),
                  label: Text('${comment.likeCount}'),
                ),
                TextButton.icon(
                  onPressed: () => _replyToComment(comment),
                  icon: const Icon(Symbols.reply, size: 16),
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
    return Padding(
      padding: const EdgeInsets.all(Insets.md),
      child: Material(
        elevation: 8,
        borderRadius: Corners.xlBorder,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: 'Add a comment...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: Insets.lg,
                    vertical: Insets.md,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submitComment(),
              ),
            ),
            IconButton(
              onPressed: _submitComment,
              icon: const Icon(Symbols.send),
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

  Widget _buildReactionsSection() {
    return ModernSection(
      title: 'Reactions',
      icon: Symbols.favorite,
      child: StreamBuilder<Map<TripReactionType, List<TripReaction>>>(
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
                padding: const EdgeInsets.all(Insets.md),
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
              ...reactionsMap.entries.map((entry) {
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
                      leading: ProfileAvatar(
                        photoUrl: reaction.userPhotoUrl,
                        initials: reaction.userName,
                        size: 40,
                      ),
                      title: Text(reaction.userName),
                      subtitle: Text(_formatDateTime(reaction.createdAt)),
                    );
                  }).toList(),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActivitySection() {
    return ModernSection(
      title: 'Activity Feed',
      icon: Symbols.timeline,
      child: StreamBuilder<List<ActivityFeedItem>>(
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
                  Icon(Symbols.timeline, size: 64, color: Colors.grey),
                  VGap(Insets.md),
                  Text(
                    'No activity yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: activities
                .map((activity) => _buildActivityCard(activity))
                .toList(),
          );
        },
      ),
    );
  }

  Widget _buildActivityCard(ActivityFeedItem activity) {
    return Card(
      margin: const EdgeInsets.only(bottom: Insets.sm),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: Corners.lgBorder),
      child: ListTile(
        leading: ProfileAvatar(
          photoUrl: activity.userPhotoUrl,
          size: 40,
          icon: _getActivityIcon(activity.activityType),
        ),
        title: Text(activity.description),
        subtitle: Text(_formatDateTime(activity.createdAt)),
        trailing: Icon(_getActivityIcon(activity.activityType)),
      ),
    );
  }

  Widget _buildPhotosSection() {
    return const ModernSection(
      title: 'Photos',
      icon: Symbols.photo_album,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Symbols.collections_bookmark, size: 64, color: Colors.grey),
            VGap(Insets.md),
            Text(
              'Photo albums coming soon',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
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
      FocusScope.of(context).unfocus();
    }
  }

  void _replyToComment(TripComment comment) {
    _commentController.text = '@${comment.authorName} ';
    _commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commentController.text.length),
    );
    FocusScope.of(context).requestFocus();
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
      case TripReactionType.wow:
        return '😮';
      case TripReactionType.thumbsUp:
        return '👍';
      case TripReactionType.helpful:
        return '💡';
    }
  }

  String _getReactionName(TripReactionType type) {
    return type.toString().split('.').last;
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.commentAdded:
        return Symbols.comment;
      case ActivityType.reactionAdded:
        return Symbols.favorite;
      case ActivityType.photoAdded:
        return Symbols.add_a_photo;
      case ActivityType.tripCreated:
        return Symbols.flight_takeoff;
      case ActivityType.tripUpdated:
        return Symbols.edit;
      case ActivityType.memberAdded:
        return Symbols.person_add;
      case ActivityType.memberRemoved:
        return Symbols.person_remove;
      case ActivityType.itineraryUpdated:
        return Symbols.edit_calendar;
      case ActivityType.bookingConfirmed:
        return Symbols.book_online;
      case ActivityType.checkIn:
        return Symbols.login;
      case ActivityType.checkOut:
        return Symbols.logout;
      case ActivityType.emergencyAlert:
        return Symbols.emergency;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:travel_wizards/src/shared/services/group_chat_service.dart';
import 'package:travel_wizards/src/shared/widgets/layout/modern_page_scaffold.dart';
import 'package:travel_wizards/src/features/brainstorm/views/widgets/decrypted_message_widget.dart';
import 'package:intl/intl.dart';

class GroupChatScreen extends StatefulWidget {
  final String tripId;
  final String tripName;

  const GroupChatScreen({
    super.key,
    required this.tripId,
    required this.tripName,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<String> _buddies = [];

  @override
  void initState() {
    super.initState();
    _loadBuddies();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadBuddies() async {
    try {
      // Get owner ID first
      final ownerId = await GroupChatService.instance.getTripOwnerId(
        widget.tripId,
      );
      if (ownerId == null) return;

      final buddies = await GroupChatService.instance.getTripBuddies(
        widget.tripId,
        ownerId,
      );
      if (mounted) {
        setState(() {
          _buddies = buddies;
        });
      }
    } catch (e) {
      debugPrint('Error loading buddies: $e');
    }
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    GroupChatService.instance.sendMessage(
      tripId: widget.tripId,
      message: message,
    );

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ModernPageScaffold(
      pageTitle: '${widget.tripName} - Group Chat',
      body: Column(
        children: [
          if (_buddies.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: colorScheme.surfaceContainerHighest,
              child: Wrap(
                spacing: 8,
                children: [
                  Chip(
                    label: const Text('You'),
                    avatar: const Icon(Icons.person, size: 16),
                  ),
                  ..._buddies.map(
                    (buddy) => Chip(
                      label: Text(buddy),
                      avatar: const Icon(Icons.person_outline, size: 16),
                    ),
                  ),
                  Chip(
                    label: const Text('AI Wizard'),
                    avatar: const Icon(Icons.auto_awesome, size: 16),
                    backgroundColor: colorScheme.primaryContainer,
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: GroupChatService.instance.getChatMessages(widget.tripId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final messages = snapshot.data ?? [];

                // Auto-scroll behaviour: since the ListView is reversed (newest messages
                // are at index 0), we scroll to offset 0 to show the latest message.
                // However, avoid auto-scrolling when the user has manually scrolled up
                // (i.e. offset is larger than a small threshold) so they can read
                // earlier messages without being pulled back.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  try {
                    if (!_scrollController.hasClients) return;

                    // Consider the user at "bottom" when offset is near 0.
                    const autoScrollThreshold = 200.0;
                    final isNearBottom =
                        _scrollController.position.maxScrollExtent >=
                        autoScrollThreshold;
                    debugPrint(
                      'Scroll offset: ${_scrollController.offset}, '
                      'Scroll End: ${_scrollController.position.maxScrollExtent}, '
                      'isNearBottom: $isNearBottom',
                    );
                    if (isNearBottom) {
                      // Jump to 0 (the newest message) immediately without animation
                      // to avoid interrupting quick streams. Use animate for smoother UX
                      // only when not the very first frame.
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                      );
                    }
                  } catch (e) {
                    // Scroll may throw if controller detached; ignore safely
                    debugPrint('Auto-scroll failed: $e');
                  }
                });

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Start the conversation!',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tag @ai or @wizard to get AI suggestions',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 200, 16, 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    debugPrint(
                      'Rendering message: ${message.message} at index $index',
                    );
                    return _buildMessageBubble(message, colorScheme, theme);
                  },
                );
              },
            ),
          ),
          _buildInputArea(colorScheme),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    ChatMessage message,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isCurrentUser =
        currentUser != null && message.senderId == currentUser.uid;
    final isAi = message.isAiResponse;

    // WhatsApp-style alignment: current user right, others (including AI) left
    final alignment = isCurrentUser
        ? Alignment.centerRight
        : Alignment.centerLeft;

    final bubbleColor = isCurrentUser
        ? colorScheme.primaryContainer
        : isAi
        ? colorScheme.tertiaryContainer
        : colorScheme.surfaceContainerHighest;

    final textColor = isCurrentUser
        ? colorScheme.onPrimaryContainer
        : isAi
        ? colorScheme.onTertiaryContainer
        : colorScheme.onSurface;

    // Display name logic
    String displayName;
    if (isAi) {
      displayName = 'Trip Wizards';
    } else {
      displayName = message.senderName;
    }

    return Align(
      alignment: alignment,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: isCurrentUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Only show name for non-current user messages
            if (!isCurrentUser) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isAi)
                    Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: colorScheme.tertiary,
                    ),
                  if (isAi) const SizedBox(width: 4),
                  Text(
                    displayName,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isCurrentUser ? 16 : 4),
                  bottomRight: Radius.circular(isCurrentUser ? 4 : 16),
                ),
              ),
              child: DecryptedMessageWidget(
                message: message,
                style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('HH:mm').format(message.timestamp),
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withAlpha(153),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message... (use @ai for AI help)',
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send),
              label: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }
}

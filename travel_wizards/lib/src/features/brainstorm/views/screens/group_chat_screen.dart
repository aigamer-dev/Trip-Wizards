import 'package:flutter/material.dart';
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
    final buddies = await GroupChatService.instance.getTripBuddies(
      widget.tripId,
    );
    if (mounted) {
      setState(() {
        _buddies = buddies;
      });
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
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
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
    final isAi = message.isAiResponse;
    final alignment = isAi ? Alignment.centerLeft : Alignment.centerRight;
    final bubbleColor = isAi
        ? colorScheme.tertiaryContainer
        : colorScheme.primaryContainer;
    final textColor = isAi
        ? colorScheme.onTertiaryContainer
        : colorScheme.onPrimaryContainer;

    return Align(
      alignment: alignment,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: isAi
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          children: [
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
                  message.senderName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isAi ? 4 : 16),
                  bottomRight: Radius.circular(isAi ? 16 : 4),
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
                color: colorScheme.onSurfaceVariant.withOpacity(0.6),
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
            color: colorScheme.shadow.withOpacity(0.1),
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

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:travel_wizards/src/shared/services/adk_service.dart';
import 'package:travel_wizards/src/shared/services/error_handling_service.dart';
import 'package:travel_wizards/src/shared/services/conversation_controller.dart';
import 'package:travel_wizards/src/shared/widgets/enhanced_message_widgets.dart';
import 'package:travel_wizards/src/shared/models/trip.dart';
import 'package:travel_wizards/src/shared/widgets/layout/modern_page_scaffold.dart';
import 'package:travel_wizards/src/shared/widgets/spacing.dart';

class EnhancedConciergeChatScreen extends StatefulWidget {
  const EnhancedConciergeChatScreen({super.key});

  @override
  State<EnhancedConciergeChatScreen> createState() =>
      _EnhancedConciergeChatScreenState();
}

class _EnhancedConciergeChatScreenState
    extends State<EnhancedConciergeChatScreen>
    with WidgetsBindingObserver {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _textFocusNode = FocusNode();

  late ConversationController _conversationController;
  StreamSubscription<String>? _adkSubscription;
  String? _currentStreamingMessageId;

  // UI state
  bool _isInputEnabled = true;
  bool _showScrollToBottom = false;

  // Enhanced features
  Timer? _messageDeliveryTimer;
  bool _hasUnreadMessages = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _conversationController = ConversationController();
    _conversationController.addListener(_onConversationChanged);
    _scrollController.addListener(_onScrollChanged);
    _initializeChat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _conversationController.removeListener(_onConversationChanged);
    _conversationController.dispose();
    _adkSubscription?.cancel();
    _messageDeliveryTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Mark messages as read when app comes to foreground
    if (state == AppLifecycleState.resumed && _hasUnreadMessages) {
      _markVisibleMessagesAsDelivered();
    }
  }

  void _initializeChat() {
    // Add welcome message if no conversation history
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_conversationController.messages.isEmpty) {
        _addWelcomeMessage();
      }
      _scrollToBottom(animated: false);
    });
  }

  Future<void> _addWelcomeMessage() async {
    final welcomeText = _buildContextualWelcomeMessage();
    await _conversationController.addAssistantMessage(welcomeText);
  }

  String _buildContextualWelcomeMessage() {
    final trips = _conversationController.userTrips;
    final activeTrip = _conversationController.activeTrip;

    if (activeTrip != null) {
      return "Hi! I'm your AI travel concierge. I see you have an active trip to ${activeTrip.destinations.join(', ')}. "
          "How can I help you today? I can assist with trains, flights, hotels, local recommendations, and more!";
    } else if (trips.isNotEmpty) {
      return "Welcome back! I'm your AI travel concierge. I can see you have some trips planned. "
          "How can I help you today? I can assist with transportation, accommodations, activities, and travel advice!";
    } else {
      return "Hello! I'm your AI travel concierge, ready to help you plan your perfect trip. "
          "Ask me about destinations, flights, trains, hotels, or anything travel-related!";
    }
  }

  void _onConversationChanged() {
    setState(() {
      _hasUnreadMessages = _conversationController.hasUnreadMessages;
    });

    // Auto-scroll to bottom for new messages
    if (_conversationController.messages.isNotEmpty) {
      final lastMessage = _conversationController.messages.last;
      if (lastMessage.role == MessageRole.assistant) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
          _scheduleMessageDeliveryUpdate(lastMessage.id);
        });
      }
    }
  }

  void _onScrollChanged() {
    final isAtBottom =
        _scrollController.hasClients &&
        _scrollController.offset >=
            _scrollController.position.maxScrollExtent - 100;

    if (_showScrollToBottom != !isAtBottom) {
      setState(() {
        _showScrollToBottom = !isAtBottom;
      });
    }

    // Mark visible messages as delivered
    if (isAtBottom && _hasUnreadMessages) {
      _markVisibleMessagesAsDelivered();
    }
  }

  void _scheduleMessageDeliveryUpdate(String messageId) {
    _messageDeliveryTimer?.cancel();
    _messageDeliveryTimer = Timer(const Duration(milliseconds: 1500), () {
      _conversationController.markMessageAsDelivered(messageId);
    });
  }

  void _markVisibleMessagesAsDelivered() {
    // Mark recent assistant messages as delivered
    final recentMessages = _conversationController.messages
        .where(
          (m) =>
              m.role == MessageRole.assistant &&
              m.status != MessageStatus.delivered,
        )
        .toList();

    for (final message in recentMessages) {
      _conversationController.markMessageAsDelivered(message.id);
    }

    setState(() {
      _hasUnreadMessages = false;
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || !_isInputEnabled) return;

    _textController.clear();
    setState(() {
      _isInputEnabled = false;
    });

    try {
      // Add user message
      final userMessageId = await _conversationController.addUserMessage(text);
      await _conversationController.updateMessage(
        userMessageId,
        text,
        status: MessageStatus.sending,
      );

      _scrollToBottom();

      // Ensure session exists
      await _ensureAdkSession();

      // Start AI response with typing indicator
      _conversationController.showTypingIndicator();
      _conversationController.updateConnectionStatus(true);

      // Create streaming message placeholder
      _currentStreamingMessageId = await _conversationController
          .addAssistantMessage('', isStreaming: true);

      // Mark user message as sent
      await _conversationController.updateMessage(
        userMessageId,
        text,
        status: MessageStatus.sent,
      );

      // Start ADK streaming
      await _startAdkStreaming(text);
    } catch (e) {
      _handleStreamingError(e);
    } finally {
      setState(() {
        _isInputEnabled = true;
      });
      _conversationController.hideTypingIndicator();
    }
  }

  Future<void> _ensureAdkSession() async {
    if (_conversationController.sessionId == null) {
      await _createAdkSession();
    }
  }

  Future<void> _createAdkSession() async {
    await AdkService.instance.createSession(
      userId: 'demo_user',
      sessionId: 'enhanced_flutter_session',
    );
    // Session is managed by the conversation controller
  }

  Future<void> _startAdkStreaming(String userMessage) async {
    final sessionId =
        _conversationController.sessionId ?? 'enhanced_flutter_session';

    _adkSubscription?.cancel();
    _adkSubscription = AdkService.instance
        .runSse(userId: 'demo_user', sessionId: sessionId, text: userMessage)
        .listen(
          _handleStreamingChunk,
          onDone: _handleStreamingComplete,
          onError: _handleStreamingError,
        );
  }

  void _handleStreamingChunk(String chunk) {
    if (chunk.isEmpty || _currentStreamingMessageId == null) return;

    // Update the streaming message content
    final currentMessage = _conversationController.messages.firstWhere(
      (m) => m.id == _currentStreamingMessageId,
    );

    final updatedContent = currentMessage.content + chunk;
    _conversationController.updateMessage(
      _currentStreamingMessageId!,
      updatedContent,
      status: MessageStatus.sending,
    );

    // Parse JSON for structured data
    _tryParseStructuredData(chunk);
  }

  void _handleStreamingComplete() {
    if (_currentStreamingMessageId != null) {
      _conversationController.updateMessage(
        _currentStreamingMessageId!,
        _conversationController.messages
            .firstWhere((m) => m.id == _currentStreamingMessageId)
            .content,
        status: MessageStatus.sent,
      );
      _currentStreamingMessageId = null;
    }

    _conversationController.hideTypingIndicator();
    _scrollToBottom();
  }

  void _handleStreamingError(dynamic error) {
    _conversationController.hideTypingIndicator();
    _conversationController.updateConnectionStatus(
      false,
      error: 'Failed to connect to AI service. Please try again.',
    );

    ErrorHandlingService.instance.handleError(
      error,
      context: 'Enhanced AI Chat Streaming',
      showToUser: true,
      userContext: context,
      userMessage:
          'Failed to get AI response. Please check your connection and try again.',
    );

    if (_currentStreamingMessageId != null) {
      _conversationController.updateMessage(
        _currentStreamingMessageId!,
        'Failed to get response. Please try again.',
        status: MessageStatus.failed,
      );
      _currentStreamingMessageId = null;
    }
  }

  void _tryParseStructuredData(String chunk) {
    try {
      // Look for JSON data in the chunk
      final openBrace = chunk.indexOf('{');
      if (openBrace == -1) return;

      final closeBrace = chunk.lastIndexOf('}');
      if (closeBrace == -1 || closeBrace <= openBrace) return;

      final jsonStr = chunk.substring(openBrace, closeBrace + 1);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      // Handle different types of structured data
      _handleStructuredData(data);
    } catch (e) {
      // Ignore JSON parsing errors - not all chunks will contain valid JSON
    }
  }

  void _handleStructuredData(Map<String, dynamic> data) {
    // Handle trains, flights, hotels, and other structured travel data
    if (data.containsKey('trains') ||
        data.containsKey('flights') ||
        data.containsKey('hotels')) {
      // This could trigger UI updates for structured travel information
      // For now, we'll let the conversation controller handle it
    }
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          maxScroll + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(maxScroll + 100);
      }
    });
  }

  void _onTripSelected(Trip? trip) {
    _conversationController.setActiveTrip(trip);
  }

  Future<void> _clearConversation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Conversation'),
        content: const Text(
          'Are you sure you want to clear all conversation history? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _conversationController.clearHistory();
      await _addWelcomeMessage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModernPageScaffold(
      pageTitle: 'AI Concierge',
      actions: [
        ListenableBuilder(
          listenable: _conversationController,
          builder: (context, _) => TripContextChip(
            activeTrip: _conversationController.activeTrip,
            availableTrips: _conversationController.userTrips,
            onTripSelected: _onTripSelected,
          ),
        ),
        IconButton(
          onPressed: _clearConversation,
          icon: const Icon(Symbols.delete_outline),
          tooltip: 'Clear conversation',
        ),
      ],
      sections: [
        Expanded(
          child: Column(
            children: [
              // Connection status indicator
              ConnectionStatusIndicator(
                isConnected: _conversationController.isConnected,
                errorMessage: _conversationController.lastError,
                onRetry: () {
                  _conversationController.updateConnectionStatus(true);
                  if (_textController.text.trim().isNotEmpty) {
                    _sendMessage();
                  }
                },
              ),

              // Messages list
              Expanded(
                child: Stack(
                  children: [
                    ListenableBuilder(
                      listenable: _conversationController,
                      builder: (context, _) => ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: Insets.md,
                        ),
                        itemCount:
                            _conversationController.messages.length +
                            (_conversationController.isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Show typing indicator at the end
                          if (index ==
                              _conversationController.messages.length) {
                            return const TypingIndicator(
                              userName: 'AI Assistant',
                            );
                          }

                          final message =
                              _conversationController.messages[index];
                          return MessageBubble(
                            message: message,
                            showTimestamp: true,
                            onLongPress: () => _showMessageOptions(message),
                          );
                        },
                      ),
                    ),

                    // Scroll to bottom button
                    if (_showScrollToBottom)
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: FloatingActionButton.small(
                          onPressed: () => _scrollToBottom(),
                          child: Badge(
                            isLabelVisible: _hasUnreadMessages,
                            child: const Icon(Symbols.keyboard_arrow_down),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Input area
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withAlpha((0.1 * 255).toInt()),
                    ),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      // Text input
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          focusNode: _textFocusNode,
                          enabled: _isInputEnabled,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          decoration: InputDecoration(
                            hintText: _isInputEnabled
                                ? 'Ask about flights, trains, hotels...'
                                : 'Sending...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainer,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),

                      const HGap(Insets.sm),

                      // Send button
                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: _isInputEnabled ? _sendMessage : null,
                          style: FilledButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: EdgeInsets.zero,
                          ),
                          child: _isInputEnabled
                              ? const Icon(Symbols.send)
                              : const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showMessageOptions(ConversationMessage message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Symbols.content_copy),
            title: const Text('Copy Message'),
            onTap: () {
              // Copy message content to clipboard
              Navigator.pop(context);
            },
          ),
          if (message.role == MessageRole.assistant)
            ListTile(
              leading: const Icon(Symbols.refresh),
              title: const Text('Regenerate Response'),
              onTap: () {
                // Regenerate AI response
                Navigator.pop(context);
              },
            ),
          ListTile(
            leading: const Icon(Symbols.info),
            title: const Text('Message Info'),
            onTap: () {
              Navigator.pop(context);
              _showMessageInfo(message);
            },
          ),
        ],
      ),
    );
  }

  void _showMessageInfo(ConversationMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Message Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${message.id}'),
            Text('Role: ${message.role.name}'),
            Text('Status: ${message.status.name}'),
            Text('Time: ${message.timestamp}'),
            if (message.sessionId != null)
              Text('Session: ${message.sessionId}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

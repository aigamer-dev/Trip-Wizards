import 'package:flutter/material.dart';
import 'package:travel_wizards/src/shared/services/travel_agent_service.dart';

/// Chat screen for interacting with the Travel Agent ADK
class TravelAgentChatScreen extends StatefulWidget {
  const TravelAgentChatScreen({super.key});

  @override
  State<TravelAgentChatScreen> createState() => _TravelAgentChatScreenState();
}

class _TravelAgentChatScreenState extends State<TravelAgentChatScreen> {
  final TravelAgentService _agentService = TravelAgentService();
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];

  bool _isLoading = false;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initializeAgent();
  }

  Future<void> _initializeAgent() async {
    try {
      // Check if API is available
      final available = await _agentService.isAvailable();
      if (!available) {
        _showError(
          'Agent API is not available. Make sure the backend is running.',
        );
        return;
      }

      // Create a new session
      await _agentService.createSession();

      setState(() {
        _isConnected = true;
        _messages.add(
          ChatMessage(
            role: 'agent',
            content:
                'Welcome to Travel Concierge! I\'m your personal AI travel assistant. '
                'I can help you with trip inspiration, planning, booking, and support throughout your journey. '
                'What would you like help with today?',
            timestamp: DateTime.now(),
          ),
        );
      });
    } catch (e) {
      _showError('Failed to initialize agent: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _sendMessage(String message) async {
    if (message.isEmpty || !_isConnected) return;

    // Add user message to UI
    setState(() {
      _messages.add(
        ChatMessage(role: 'user', content: message, timestamp: DateTime.now()),
      );
      _isLoading = true;
    });

    _messageController.clear();

    try {
      // Send message and get response
      final response = await _agentService.sendMessage(message);

      setState(() {
        _messages.add(
          ChatMessage(
            role: 'agent',
            content: response.toString(),
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });

      // Scroll to bottom
      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error: $e');
    }
  }

  void _scrollToBottom() {
    // Delayed scroll to ensure widget is rendered
    Future.delayed(const Duration(milliseconds: 100), () {
      // In a real app, use ScrollController
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _agentService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Concierge'),
        elevation: 0,
        actions: [
          if (_isConnected)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Connected',
                        style: TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: !_isConnected
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Connecting to Travel Concierge...',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Messages list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Show typing indicator at the end when loading
                      if (_isLoading && index == _messages.length) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      scheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'AI is thinking...',
                                  style: TextStyle(
                                    color: scheme.onSurface.withOpacity(0.7),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final message = _messages[index];
                      final isUserMessage = message.role == 'user';

                      return Align(
                        alignment: isUserMessage
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isUserMessage
                                ? scheme.primary
                                : scheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: isUserMessage
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.content,
                                style: TextStyle(
                                  color: isUserMessage
                                      ? scheme.onPrimary
                                      : scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTime(message.timestamp),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isUserMessage
                                      ? scheme.onPrimary.withValues(alpha: 0.7)
                                      : scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Message input
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: scheme.outlineVariant),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Ask me anything about your trip...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            filled: true,
                            fillColor: scheme.surfaceContainerHigh,
                          ),
                          maxLines: null,
                          enabled: !_isLoading,
                        ),
                      ),
                      const SizedBox(width: 12),
                      FloatingActionButton(
                        onPressed: _isLoading
                            ? null
                            : () =>
                                  _sendMessage(_messageController.text.trim()),
                        child: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }
}

/// Model for chat messages
class ChatMessage {
  final String role; // 'user' or 'agent'
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });
}

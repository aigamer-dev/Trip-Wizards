import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:travel_wizards/src/shared/services/travel_agent_service.dart';
import 'package:travel_wizards/src/features/trip_planning/views/screens/plan_trip_screen.dart';
import 'package:travel_wizards/src/shared/widgets/spacing.dart';

/// Screen for AI-powered trip generation using ADK
class AdkTripGenerationScreen extends StatefulWidget {
  const AdkTripGenerationScreen({super.key});

  @override
  State<AdkTripGenerationScreen> createState() =>
      _AdkTripGenerationScreenState();
}

class _AdkTripGenerationScreenState extends State<AdkTripGenerationScreen> {
  final TravelAgentService _agentService = TravelAgentService();
  final TextEditingController _promptController = TextEditingController();
  final List<Map<String, String>> _conversation = [];
  bool _loading = false;
  bool _sessionInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  @override
  void dispose() {
    _promptController.dispose();
    _agentService.closeSession();
    super.dispose();
  }

  Future<void> _initializeSession() async {
    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Set user ID before creating session
      _agentService.setUserId(user.uid);

      // Create session
      await _agentService.createSession();
      setState(() => _sessionInitialized = true);

      // Add welcome message
      setState(() {
        _conversation.add({
          'role': 'assistant',
          'content':
              '👋 Welcome! I\'m your Travel Concierge AI.\n\nI can help you:\n'
              '• Find travel inspiration for your next adventure\n'
              '• Plan your complete itinerary\n'
              '• Suggest activities, hotels, and flights\n'
              '• Provide travel tips and recommendations\n\n'
              'Tell me about your ideal trip! For example:\n'
              '"A 5-day trip to Japan in spring with cultural activities"',
        });
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize session: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty || _loading) return;

    final trimmed = message.trim();
    _promptController.clear();

    setState(() {
      _loading = true;
      _conversation.add({'role': 'user', 'content': trimmed});
    });

    try {
      final eventResponse = await _agentService.sendMessage(trimmed);

      // Extract text from event response
      final content = eventResponse['content'] as Map?;
      final parts = content?['parts'] as List? ?? [];
      String responseText = '';

      if (parts.isNotEmpty) {
        final firstPart = parts.first as Map?;
        responseText =
            (firstPart?['text'] ?? 'No response available') as String;
      } else {
        responseText = 'No response available';
      }

      setState(() {
        _conversation.add({'role': 'assistant', 'content': responseText});
      });
    } catch (e) {
      setState(() {
        _conversation.add({
          'role': 'error',
          'content': 'Error: $e\n\nPlease try again or switch to manual entry.',
        });
      });
    } finally {
      setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Scroll implementation would go here
    });
  }

  Future<void> _proceedToPlanning() async {
    // Navigate to plan trip screen with AI suggestions
    if (mounted) {
      context.pushNamed(
        'plan',
        extra: PlanTripArgs(
          ideaId: 'adk_generated',
          title: 'AI-Generated Trip Plan',
          tags: {'ai_suggested', 'from_adk'},
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Trip Planning'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton.icon(
            onPressed: _conversation.length > 1 ? _proceedToPlanning : null,
            icon: const Icon(Icons.check),
            label: const Text('Next'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Conversation history
          Expanded(
            child: _sessionInitialized
                ? ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _conversation.length + (_loading ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Show loading indicator at the end
                      if (_loading && index == _conversation.length) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest,
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

                      final msg = _conversation[index];
                      final isUser = msg['role'] == 'user';
                      final isError = msg['role'] == 'error';

                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.8,
                          ),
                          decoration: BoxDecoration(
                            color: isError
                                ? scheme.errorContainer
                                : isUser
                                ? scheme.primaryContainer
                                : scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            msg['content'] ?? '',
                            style: TextStyle(
                              color: isError
                                  ? scheme.error
                                  : isUser
                                  ? scheme.onPrimaryContainer
                                  : scheme.onSurface,
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: scheme.primary),
                        const VGap(16),
                        Text(
                          'Initializing Travel Concierge AI...',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
          ),

          // Input area
          if (_sessionInitialized)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: scheme.outlineVariant)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _promptController,
                      enabled: !_loading,
                      decoration: InputDecoration(
                        hintText: 'Describe your ideal trip...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      onSubmitted: (value) => _sendMessage(value),
                    ),
                  ),
                  const HGap(8),
                  FilledButton.icon(
                    onPressed: _loading
                        ? null
                        : () => _sendMessage(_promptController.text),
                    icon: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: const Text('Send'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:travel_wizards/src/features/brainstorm/data/brainstorm_session_store.dart';
import 'package:travel_wizards/src/shared/services/brainstorm_service.dart';

class BrainstormScreen extends StatefulWidget {
  const BrainstormScreen({super.key});

  @override
  State<BrainstormScreen> createState() => _BrainstormScreenState();
}

class _BrainstormScreenState extends State<BrainstormScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final List<String> _messages = <String>[
    'Welcome to Travel Wizards AI brainstorm!',
  ];
  bool _sessionActive = false;
  static const List<String> _suggestions = <String>[
    'Weekend trip to Goa under ₹20k',
    'Book Flights, Hotels, and Activities for 2 days this weekend',
    'Give me a full itinerary',
    'Romantic getaway near Udaipur',
    'Food tour in Hyderabad for 2 days',
  ];

  @override
  void initState() {
    super.initState();
    BrainstormService.instance.initialize();

    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send([String? prompt]) {
    final text = (prompt ?? _controller.text).trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(text);
      _controller.clear();
    });
    _scrollToBottom();
    _messages.add('...');
    BrainstormService.instance.send(text).then((resp) {
      if (!mounted) return;
      setState(() {
        _messages.last = resp;
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1080;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [scheme.surfaceContainerHighest, scheme.surface],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          flex: 5,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 420),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildIdeaHero(context),
                                  const SizedBox(height: 16),
                                  _buildSuggestionCard(context),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Flexible(flex: 7, child: _buildChatCard(context)),
                      ],
                    )
                  : Column(
                      children: [
                        _buildIdeaHero(context),
                        const SizedBox(height: 16),
                        _buildSuggestionCard(context),
                        const SizedBox(height: 16),
                        Expanded(child: _buildChatCard(context)),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIdeaHero(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SizedBox(
      width: double.infinity,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                scheme.primaryContainer,
                scheme.secondaryContainer.withAlpha((0.7 * 255).toInt()),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: scheme.onPrimaryContainer.withAlpha((0.1 * 255).toInt()),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 32,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Brainstorm your next escape',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Describe the vibe or constraints and let Travel Wizards co-create an itinerary in seconds.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onPrimaryContainer.withAlpha((0.8 * 255).toInt()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: scheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Suggestion Prompts',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to auto-fill the composer with popular requests.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final suggestion in _suggestions)
                  _buildSuggestionPill(context, suggestion),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatCard(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: scheme.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Idea Board',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_sessionActive) _buildSessionBanner(context),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildMessagesList(context)),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(16.0), child: _buildInputRow()),
        ],
      ),
    );
  }

  Widget _buildSessionBanner(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final startedAt = BrainstormSessionStore.instance.startedAt;
    final startedLabel = startedAt != null
        ? TimeOfDay.fromDateTime(startedAt.toLocal()).format(context)
        : 'just now';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt_rounded, color: scheme.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Session active · started $startedLabel',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
          TextButton(onPressed: _toggleSession, child: const Text('End')),
        ],
      ),
    );
  }

  Widget _buildMessagesList(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isUser = index.isOdd;
        final bubbleColor = isUser
            ? scheme.primary
            : scheme.surfaceContainerHighest;
        final textColor = isUser ? scheme.onPrimary : scheme.onSurface;

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isUser ? 20 : 8),
                bottomRight: Radius.circular(isUser ? 8 : 20),
              ),
              boxShadow: [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              msg,
              style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputRow() {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (kIsWeb) {
                _focusNode.requestFocus();
              }
            },
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Ask for destinations, mood, or timeframes…',
                filled: true,
                fillColor: scheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
              onSubmitted: (_) => _send(),
              textInputAction: TextInputAction.send,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              autofocus: kIsWeb,
            ),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: _send,
          icon: const Icon(Icons.send_rounded),
          label: const Text('Send'),
        ),
      ],
    );
  }

  Future<void> _toggleSession() async {
    if (_sessionActive) {
      await BrainstormSessionStore.instance.end();
      if (!mounted) return;
      setState(() {
        _sessionActive = false;
        _messages
          ..clear()
          ..add('Welcome to Travel Wizards AI brainstorm!');
      });
    } else {
      await BrainstormService.instance.initialize();
      if (!mounted) return;
      setState(() {
        _sessionActive = true;
        _messages
          ..clear()
          ..add('Welcome to Travel Wizards AI brainstorm!');
      });
    }
    _scrollToBottom();
  }

  Widget _buildSuggestionPill(BuildContext context, String suggestion) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final double availableWidth = MediaQuery.sizeOf(context).width;
    final double maxWidth = (availableWidth - 72)
        .clamp(220.0, 420.0)
        .toDouble();

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => _send(suggestion),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.flash_on_rounded, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    suggestion,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

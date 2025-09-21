import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_wizards/src/common/ui/spacing.dart';
import 'package:travel_wizards/src/data/brainstorm_session_store.dart';
import 'package:travel_wizards/src/screens/trip/plan_trip_screen.dart';
import 'package:travel_wizards/src/services/brainstorm_service.dart';
import 'package:travel_wizards/src/services/calendar_service.dart';

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

    // On web, ensure the text field can receive focus
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }

    // BrainstormSessionStore.instance.load().then((_) async {
    //   if (!mounted) return;
    //   setState(() => _sessionActive = BrainstormSessionStore.instance.isActive);
    //   if (!BrainstormSessionStore.instance.isActive) {
    //     await BrainstormSessionStore.instance.start();
    //     if (!mounted) return;
    //     setState(() => _sessionActive = true);
    //   }
    // });
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
    // Body-only; NavShell supplies AppBar and back behavior.
    return Column(
      children: [
        // Inline quick actions row
        Padding(
          padding: const EdgeInsets.only(
            left: Insets.md,
            right: Insets.md,
            top: Insets.sm,
          ),
          child: Row(
            children: [
              Tooltip(
                message: 'Attach Preferences',
                child: IconButton(
                  icon: const Icon(Icons.tune_rounded),
                  onPressed: () => context.pushNamed('settings'),
                ),
              ),
              Tooltip(
                message: 'Use Calendar Availability',
                child: IconButton(
                  icon: const Icon(Icons.event_available_rounded),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final count = await CalendarService.syncTripsFromCalendar();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Imported $count trip-like events from calendar',
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Spacer(),
              Tooltip(
                message: _sessionActive ? 'End Session' : 'New Session',
                child: IconButton(
                  icon: Icon(
                    _sessionActive
                        ? Icons.stop_circle_rounded
                        : Icons.fiber_new_rounded,
                  ),
                  onPressed: () async {
                    if (_sessionActive) {
                      // await BrainstormSessionStore.instance.end();
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
                  },
                ),
              ),
              Tooltip(
                message: 'Review & Convert',
                child: IconButton(
                  icon: const Icon(Icons.auto_awesome_rounded),
                  onPressed: () {
                    final lastUser = _messages.reversed.firstWhere(
                      (m) => !m.startsWith('data:'),
                      orElse: () => '',
                    );
                    final args = PlanTripArgs(
                      ideaId: 'brainstorm',
                      title: lastUser.isNotEmpty
                          ? lastUser
                          : 'Brainstormed Trip',
                      tags: {'Weekend', 'Budget'},
                    );
                    context.pushNamed('plan', extra: args);
                  },
                ),
              ),
            ],
          ),
        ),
        // Quick suggestion chips
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.md,
            vertical: Insets.sm,
          ),
          child: SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => Gaps.w8,
              itemBuilder: (context, index) {
                final s = _suggestions[index];
                return Semantics(
                  button: true,
                  label: 'Suggestion: $s',
                  child: ActionChip(label: Text(s), onPressed: () => _send(s)),
                );
              },
            ),
          ),
        ),
        if (_sessionActive)
          MaterialBanner(
            content: Text(
              'Session active — started at: '
              '${BrainstormSessionStore.instance.startedAt != null ? BrainstormSessionStore.instance.startedAt!.toLocal().toString().split('.').first : 'now'}',
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await BrainstormSessionStore.instance.end();
                  if (!mounted) return;
                  setState(() => _sessionActive = false);
                },
                child: const Text('End'),
              ),
            ],
          ),
        Expanded(
          child: ListView.separated(
            controller: _scrollController,
            padding: Insets.allMd,
            itemCount: _messages.length,
            separatorBuilder: (_, __) => Gaps.h8,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              return Align(
                alignment: index % 2 == 0
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Text(msg),
                  ),
                ),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: Insets.allSm,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // Ensure focus on web when clicking the text field area
                      if (kIsWeb) {
                        _focusNode.requestFocus();
                      }
                    },
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        label: Text('Your Prompt'),
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(),
                      textInputAction: TextInputAction.send,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      autofocus: kIsWeb, // Auto-focus on web
                    ),
                  ),
                ),
                Gaps.w8,
                Semantics(
                  label: 'Send message',
                  button: true,
                  child: FilledButton.icon(
                    onPressed: _send,
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Send'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

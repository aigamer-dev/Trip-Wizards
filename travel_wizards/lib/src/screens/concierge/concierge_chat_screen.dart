import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:travel_wizards/src/services/adk_service.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_wizards/src/screens/trip/add_to_trip_screen.dart';
import 'package:travel_wizards/src/services/trips_repository.dart';
import 'package:travel_wizards/src/services/error_handling_service.dart';

class ConciergeChatScreen extends StatefulWidget {
  const ConciergeChatScreen({super.key});

  @override
  State<ConciergeChatScreen> createState() => _ConciergeChatScreenState();
}

class _ConciergeChatScreenState extends State<ConciergeChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<_Msg> _messages = [];
  String? _sessionId;
  final String _userId = 'demo_user';
  StreamSubscription<String>? _sub;
  bool _busy = false;

  // Parsed structured data
  final List<_Train> _trains = [];
  _RoadTrip? _roadTrip;

  // Simple JSON accumulator for SSE chunks
  final StringBuffer _jsonBuf = StringBuffer();
  int _braceDepth = 0;
  bool _inJson = false;

  @override
  void dispose() {
    _sub?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _ensureSession() async {
    if (_sessionId != null) return;
    final res = await AdkService.instance.createSession(
      userId: _userId,
      sessionId: 'flutter_demo',
    );
    setState(
      () => _sessionId = (res['sessionId'] ?? 'flutter_demo').toString(),
    );
  }

  void _appendSystem(String text) {
    setState(() {
      _messages.add(_Msg(role: 'system', text: text));
    });
  }

  void _appendBotChunk(String text) {
    if (text.isEmpty) return;
    setState(() {
      if (_messages.isEmpty || _messages.last.role != 'assistant_stream') {
        _messages.add(_Msg(role: 'assistant_stream', text: text));
      } else {
        _messages.last = _messages.last.copyWith(
          text: _messages.last.text + text,
        );
      }
    });
    _ingestForJson(text);
    _scrollToEnd();
  }

  void _finalizeBotMessage() {
    setState(() {
      if (_messages.isNotEmpty && _messages.last.role == 'assistant_stream') {
        final last = _messages.removeLast();
        _messages.add(_Msg(role: 'assistant', text: last.text));
      }
    });
  }

  void _ingestForJson(String data) {
    // Accumulate balanced JSON objects and parse when complete
    for (int i = 0; i < data.length; i++) {
      final ch = data[i];
      if (!_inJson) {
        if (ch == '{') {
          _inJson = true;
          _braceDepth = 1;
          _jsonBuf.clear();
          _jsonBuf.write(ch);
        }
        // else ignore until we see a '{'
      } else {
        _jsonBuf.write(ch);
        if (ch == '{') _braceDepth++;
        if (ch == '}') _braceDepth--;
        if (_braceDepth == 0) {
          // Potential complete JSON object
          final candidate = _jsonBuf.toString();
          _inJson = false;
          _jsonBuf.clear();
          try {
            final obj = jsonDecode(candidate);
            if (obj is Map<String, dynamic>) {
              _handleJson(obj);
            }
          } catch (_) {
            // Not valid JSON; ignore
          }
        }
      }
    }
  }

  void _handleJson(Map<String, dynamic> obj) {
    // Trains detection
    if (obj.containsKey('trains') && obj['trains'] is List) {
      final items = (obj['trains'] as List)
          .whereType<Map<String, dynamic>>()
          .map((m) => _Train.fromJson(m))
          .where((t) => t != null)
          .cast<_Train>()
          .toList();
      if (items.isNotEmpty) {
        setState(() {
          _trains
            ..clear()
            ..addAll(items);
          _messages.add(
            _Msg(
              role: 'system',
              text: 'Parsed ${items.length} train option(s).',
            ),
          );
        });
      }
      return;
    }
    // Road trip detection
    final keys = obj.keys.toSet();
    const roadKeys = {
      'mode',
      'origin',
      'destination',
      'distance_km',
      'duration_hours',
    };
    if (roadKeys.difference(keys).isEmpty) {
      final rt = _RoadTrip.fromJson(obj);
      if (rt != null) {
        setState(() {
          _roadTrip = rt;
          _messages.add(
            _Msg(role: 'system', text: 'Parsed road trip estimate.'),
          );
        });
      }
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _busy) return;
    _controller.clear();
    setState(() {
      _messages.add(_Msg(role: 'user', text: text));
      _busy = true;
    });

    await ErrorHandlingService.instance.handleAsync(
      () async {
        await _ensureSession();
        final sess = _sessionId!;
        _sub?.cancel();
        _appendSystem('Streaming...');
        _sub = AdkService.instance
            .runSse(userId: _userId, sessionId: sess, text: text)
            .listen(
              _appendBotChunk,
              onDone: () {
                _finalizeBotMessage();
                setState(() => _busy = false);
              },
              onError: (e) {
                if (!mounted) return;
                ErrorHandlingService.instance.handleError(
                  e,
                  context: 'AI Chat Streaming',
                  showToUser: true,
                  userContext: context,
                  userMessage: 'Failed to get AI response. Please try again.',
                );
                _appendSystem('Error: Failed to get response');
                setState(() => _busy = false);
              },
            );
      },
      context: 'AI Chat Send Message',
      userContext: context,
      userErrorMessage:
          'Failed to send message. Please check your connection and try again.',
      showUserError: true,
    );

    // Ensure busy state is reset if something goes wrong
    if (_busy) {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Shell AppBar provides title/back; return body-only to avoid double app bars.
    return Column(
      children: [
        if (_trains.isNotEmpty || _roadTrip != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_trains.isNotEmpty) _TrainsCard(trains: _trains),
                if (_roadTrip != null) _RoadTripCard(estimate: _roadTrip!),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length,
            itemBuilder: (context, i) {
              final m = _messages[i];
              final isUser = m.role == 'user';
              final align = isUser
                  ? Alignment.centerRight
                  : Alignment.centerLeft;
              final color = isUser
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest;
              return Align(
                alignment: align,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SelectableText(m.text),
                ),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      hintText:
                          'Ask for trains, road trips, flights, hotels...',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _busy ? null : _send,
                  icon: const Icon(Icons.send),
                  label: const Text('Send'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Msg {
  final String role; // user | assistant | assistant_stream | system
  final String text;
  _Msg({required this.role, required this.text});
  _Msg copyWith({String? role, String? text}) =>
      _Msg(role: role ?? this.role, text: text ?? this.text);
}

class _Train {
  final String trainNumber;
  final String name;
  final String departureStation;
  final String arrivalStation;
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final List<String> classes;
  final int? priceUsd;

  _Train({
    required this.trainNumber,
    required this.name,
    required this.departureStation,
    required this.arrivalStation,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.classes,
    this.priceUsd,
  });

  static _Train? fromJson(Map<String, dynamic> j) {
    try {
      return _Train(
        trainNumber: (j['train_number'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        departureStation: (j['departure_station'] ?? '').toString(),
        arrivalStation: (j['arrival_station'] ?? '').toString(),
        departureTime: (j['departure_time'] ?? '').toString(),
        arrivalTime: (j['arrival_time'] ?? '').toString(),
        duration: (j['duration'] ?? '').toString(),
        classes:
            (j['classes'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
        priceUsd: j['price_in_usd'] is int
            ? j['price_in_usd'] as int
            : int.tryParse(j['price_in_usd']?.toString() ?? ''),
      );
    } catch (_) {
      return null;
    }
  }
}

class _RoadTrip {
  final String mode;
  final String origin;
  final String destination;
  final double distanceKm;
  final double durationHours;
  final String? vehicleModel;
  final double? fuelCostUsd;

  _RoadTrip({
    required this.mode,
    required this.origin,
    required this.destination,
    required this.distanceKm,
    required this.durationHours,
    this.vehicleModel,
    this.fuelCostUsd,
  });

  static _RoadTrip? fromJson(Map<String, dynamic> j) {
    try {
      double toD(v) => v is num ? v.toDouble() : double.parse(v.toString());
      return _RoadTrip(
        mode: (j['mode'] ?? '').toString(),
        origin: (j['origin'] ?? '').toString(),
        destination: (j['destination'] ?? '').toString(),
        distanceKm: toD(j['distance_km']),
        durationHours: toD(j['duration_hours']),
        vehicleModel: j['vehicle_model']?.toString(),
        fuelCostUsd: j['fuel_cost_usd'] != null
            ? toD(j['fuel_cost_usd'])
            : null,
      );
    } catch (_) {
      return null;
    }
  }
}

class _TrainsCard extends StatelessWidget {
  final List<_Train> trains;
  const _TrainsCard({required this.trains});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.train_rounded),
                const SizedBox(width: 8),
                Text(
                  'Train options',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () async {
                    final chosen = await showModalBottomSheet<String>(
                      context: context,
                      showDragHandle: true,
                      useSafeArea: true,
                      builder: (_) => const AddToTripScreen(),
                    );
                    if (chosen == null || chosen.isEmpty) return;
                    // Derive destinations from first visible train
                    if (trains.isEmpty) return;
                    final first = trains.first;
                    final dests = <String>{
                      first.departureStation,
                      first.arrivalStation,
                    }..removeWhere((e) => e.trim().isEmpty);
                    if (dests.isEmpty) return;
                    await TripsRepository.instance.addDestinations(
                      chosen,
                      dests.toList(growable: false),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Added to trip')),
                      );
                      context.push('/trips/$chosen');
                    }
                  },
                  icon: const Icon(Icons.playlist_add_rounded),
                  label: const Text('Add to Trip'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...trains
                .take(5)
                .map(
                  (t) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.directions_railway_rounded),
                    title: Text('${t.name} (${t.trainNumber})'),
                    subtitle: Text(
                      '${t.departureStation} ${t.departureTime} → ${t.arrivalStation} ${t.arrivalTime}\n${t.duration}  •  Classes: ${t.classes.join(', ')}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (t.priceUsd != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text('USD ${t.priceUsd}'),
                          ),
                        IconButton(
                          tooltip: 'Add this route to a trip',
                          icon: const Icon(Icons.playlist_add_rounded),
                          onPressed: () async {
                            final chosen = await showModalBottomSheet<String>(
                              context: context,
                              showDragHandle: true,
                              useSafeArea: true,
                              builder: (_) => const AddToTripScreen(),
                            );
                            if (chosen == null || chosen.isEmpty) return;
                            final dests = <String>{
                              t.departureStation,
                              t.arrivalStation,
                            }..removeWhere((e) => e.trim().isEmpty);
                            if (dests.isEmpty) return;
                            await TripsRepository.instance.addDestinations(
                              chosen,
                              dests.toList(growable: false),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Added to trip')),
                              );
                              context.push('/trips/$chosen');
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _RoadTripCard extends StatelessWidget {
  final _RoadTrip estimate;
  const _RoadTripCard({required this.estimate});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_car_rounded),
                const SizedBox(width: 8),
                Text(
                  'Road trip estimate',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () async {
                    final chosen = await showModalBottomSheet<String>(
                      context: context,
                      showDragHandle: true,
                      useSafeArea: true,
                      builder: (_) => const AddToTripScreen(),
                    );
                    if (chosen == null || chosen.isEmpty) return;
                    final dests = <String>{
                      estimate.origin,
                      estimate.destination,
                    }..removeWhere((e) => e.trim().isEmpty);
                    if (dests.isEmpty) return;
                    await TripsRepository.instance.addDestinations(
                      chosen,
                      dests.toList(growable: false),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Added to trip')),
                      );
                      context.push('/trips/$chosen');
                    }
                  },
                  icon: const Icon(Icons.playlist_add_rounded),
                  label: const Text('Add to Trip'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${estimate.mode.toUpperCase()}  •  ${estimate.origin} → ${estimate.destination}',
            ),
            const SizedBox(height: 4),
            Text(
              'Distance: ${estimate.distanceKm.toStringAsFixed(1)} km   •   Time: ${estimate.durationHours.toStringAsFixed(2)} h',
            ),
            if (estimate.vehicleModel != null)
              Text('Vehicle: ${estimate.vehicleModel}'),
            if (estimate.fuelCostUsd != null)
              Text(
                'Fuel cost: USD ${estimate.fuelCostUsd!.toStringAsFixed(2)}',
              ),
          ],
        ),
      ),
    );
  }
}

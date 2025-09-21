import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:travel_wizards/src/services/trip_execution_service.dart';
import 'package:travel_wizards/src/common/ui/spacing.dart';

/// Screen for managing trip execution - check-ins, progress tracking, and live updates
class TripExecutionScreen extends StatefulWidget {
  final String tripId;
  final String tripName;

  const TripExecutionScreen({
    super.key,
    required this.tripId,
    required this.tripName,
  });

  @override
  State<TripExecutionScreen> createState() => _TripExecutionScreenState();
}

class _TripExecutionScreenState extends State<TripExecutionScreen> {
  final TripExecutionService _executionService = TripExecutionService.instance;

  bool _isLoading = false;
  double _tripProgress = 0.0;
  TripExecutionStatus? _currentStatus;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadTripData();
  }

  Future<void> _loadTripData() async {
    setState(() => _isLoading = true);

    try {
      final status = await _executionService.getCurrentTripStatus();
      final progress = await _executionService.getTripProgress();

      setState(() {
        _currentStatus = status;
        _tripProgress = progress;
      });

      // Get current location
      try {
        final position = await Geolocator.getCurrentPosition();
        setState(() => _currentPosition = position);
      } catch (e) {
        debugPrint('Failed to get location: $e');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load trip data: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startTrip() async {
    try {
      await _executionService.startTripExecution(widget.tripId);
      await _loadTripData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip started! Enjoy your journey! 🎉')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to start trip: $e')));
      }
    }
  }

  Future<void> _endTrip() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Trip'),
        content: const Text(
          'Are you sure you want to end this trip? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('End Trip'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _executionService.endTripExecution();
        await _loadTripData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Trip completed! Hope you had a great time! ✨'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to end trip: $e')));
        }
      }
    }
  }

  Future<void> _checkIn() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _CheckInDialog(currentPosition: _currentPosition),
    );

    if (result != null) {
      try {
        final checkInResult = await _executionService.checkIn(
          activityId: result['activityId'],
          activityName: result['activityName'],
          location: result['location'],
          currentPosition: _currentPosition,
          notes: result['notes'],
        );

        if (checkInResult.isSuccess) {
          await _loadTripData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Checked in to ${result['activityName']}! 📍'),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Check-in failed: ${checkInResult.error}'),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Check-in failed: $e')));
        }
      }
    }
  }

  Future<void> _checkOut() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _CheckOutDialog(),
    );

    if (result != null) {
      try {
        final checkOutResult = await _executionService.checkOut(
          activityId: result['activityId'],
          notes: result['notes'],
          rating: result['rating'],
        );

        if (checkOutResult.isSuccess) {
          await _loadTripData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Checked out successfully! 👋')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Check-out failed: ${checkOutResult.error}'),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Check-out failed: $e')));
        }
      }
    }
  }

  Future<void> _triggerEmergency() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Emergency Assistance'),
          ],
        ),
        content: const Text(
          'This will notify emergency contacts and local authorities. '
          'Only use in case of real emergency.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Request Help',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _executionService.triggerEmergencyAssistance(
          type: 'general',
          message: 'Emergency assistance requested from mobile app',
          location: _currentPosition,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Emergency assistance requested. Help is on the way! 🚨',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to request emergency assistance: $e'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.tripName} - Execution'),
        actions: [
          IconButton(
            onPressed: _triggerEmergency,
            icon: const Icon(Icons.emergency, color: Colors.red),
            tooltip: 'Emergency Assistance',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: Insets.allLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trip status card
                  _buildStatusCard(theme),
                  const SizedBox(height: 24),

                  // Progress indicator
                  _buildProgressCard(theme),
                  const SizedBox(height: 24),

                  // Quick actions
                  _buildQuickActions(theme),
                  const SizedBox(height: 24),

                  // Real-time updates
                  _buildUpdatesSection(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard(ThemeData theme) {
    final statusIcon = _getStatusIcon();
    final statusText = _getStatusText();
    final statusColor = _getStatusColor();

    return Card(
      child: Padding(
        padding: Insets.allLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 32),
                const SizedBox(width: 12),
                Text(
                  'Trip Status',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              statusText,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_currentPosition != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Current location: ${_currentPosition!.latitude.toStringAsFixed(4)}, '
                    '${_currentPosition!.longitude.toStringAsFixed(4)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: Insets.allLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics),
                const SizedBox(width: 12),
                Text(
                  'Trip Progress',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _tripProgress,
              backgroundColor: theme.colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(_tripProgress * 100).toInt()}% completed',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_currentStatus == TripExecutionStatus.planned) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startTrip,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Trip'),
            ),
          ),
        ] else if (_currentStatus == TripExecutionStatus.active) ...[
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _checkIn,
                  icon: const Icon(Icons.location_on),
                  label: const Text('Check In'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _checkOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Check Out'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _endTrip,
              icon: const Icon(Icons.stop),
              label: const Text('End Trip'),
            ),
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loadTripData,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Status'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUpdatesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Live Updates',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<TripUpdate>>(
          stream: _executionService.getTripUpdatesStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Card(
                child: Padding(
                  padding: Insets.allMd,
                  child: Text(
                    'No updates yet. Updates will appear here when you start your trip.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              );
            }

            final updates = snapshot.data!.take(5).toList();

            return Column(
              children: updates
                  .map(
                    (update) => Card(
                      child: ListTile(
                        leading: Icon(_getUpdateIcon(update.type)),
                        title: Text(update.message),
                        subtitle: Text(_formatUpdateTime(update.timestamp)),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  IconData _getStatusIcon() {
    switch (_currentStatus) {
      case TripExecutionStatus.planned:
        return Icons.schedule;
      case TripExecutionStatus.active:
        return Icons.directions_walk;
      case TripExecutionStatus.paused:
        return Icons.pause;
      case TripExecutionStatus.completed:
        return Icons.check_circle;
      case TripExecutionStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusText() {
    switch (_currentStatus) {
      case TripExecutionStatus.planned:
        return 'Ready to start';
      case TripExecutionStatus.active:
        return 'Trip in progress';
      case TripExecutionStatus.paused:
        return 'Trip paused';
      case TripExecutionStatus.completed:
        return 'Trip completed';
      case TripExecutionStatus.cancelled:
        return 'Trip cancelled';
      default:
        return 'Unknown status';
    }
  }

  Color _getStatusColor() {
    switch (_currentStatus) {
      case TripExecutionStatus.planned:
        return Colors.blue;
      case TripExecutionStatus.active:
        return Colors.green;
      case TripExecutionStatus.paused:
        return Colors.orange;
      case TripExecutionStatus.completed:
        return Colors.green;
      case TripExecutionStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getUpdateIcon(TripUpdateType type) {
    switch (type) {
      case TripUpdateType.checkIn:
        return Icons.location_on;
      case TripUpdateType.checkOut:
        return Icons.logout;
      case TripUpdateType.progress:
        return Icons.trending_up;
      case TripUpdateType.location:
        return Icons.my_location;
      case TripUpdateType.weather:
        return Icons.wb_sunny;
      case TripUpdateType.delay:
        return Icons.access_time;
      case TripUpdateType.emergency:
        return Icons.emergency;
      default:
        return Icons.info;
    }
  }

  String _formatUpdateTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

// Dialog widgets
class _CheckInDialog extends StatefulWidget {
  final Position? currentPosition;

  const _CheckInDialog({this.currentPosition});

  @override
  State<_CheckInDialog> createState() => _CheckInDialogState();
}

class _CheckInDialogState extends State<_CheckInDialog> {
  final _activityController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Check In'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _activityController,
              decoration: const InputDecoration(
                labelText: 'Activity/Place',
                hintText: 'e.g., Eiffel Tower, Hotel Check-in',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'e.g., Paris, France',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Any additional notes...',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_activityController.text.isNotEmpty &&
                _locationController.text.isNotEmpty) {
              Navigator.of(context).pop({
                'activityId': DateTime.now().millisecondsSinceEpoch.toString(),
                'activityName': _activityController.text,
                'location': _locationController.text,
                'notes': _notesController.text.isNotEmpty
                    ? _notesController.text
                    : null,
              });
            }
          },
          child: const Text('Check In'),
        ),
      ],
    );
  }
}

class _CheckOutDialog extends StatefulWidget {
  @override
  State<_CheckOutDialog> createState() => _CheckOutDialogState();
}

class _CheckOutDialogState extends State<_CheckOutDialog> {
  final _notesController = TextEditingController();
  int _rating = 5;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Check Out'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How was your experience?'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () => setState(() => _rating = index + 1),
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Share your experience...',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop({
              'activityId': DateTime.now().millisecondsSinceEpoch.toString(),
              'rating': _rating,
              'notes': _notesController.text.isNotEmpty
                  ? _notesController.text
                  : null,
            });
          },
          child: const Text('Check Out'),
        ),
      ],
    );
  }
}

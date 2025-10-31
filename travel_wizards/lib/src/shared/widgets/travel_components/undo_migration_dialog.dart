import 'dart:async';
import 'package:flutter/material.dart';
import 'package:travel_wizards/src/shared/services/auth_service.dart';
import 'package:travel_wizards/src/shared/widgets/travel_components/travel_components.dart';

/// Dialog shown after successful migration to offer undo option with countdown timer.
class UndoMigrationDialog extends StatefulWidget {
  const UndoMigrationDialog({
    super.key,
    required this.previousProvider,
    required this.userId,
    required this.undoWindow,
    required this.startTime,
  });

  final String previousProvider;
  final String userId;
  final Duration undoWindow;
  final DateTime startTime;

  @override
  State<UndoMigrationDialog> createState() => _UndoMigrationDialogState();
}

class _UndoMigrationDialogState extends State<UndoMigrationDialog> {
  late Timer _timer;
  late Duration _timeRemaining;

  @override
  void initState() {
    super.initState();
    _timeRemaining = widget.undoWindow;
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      final elapsed = DateTime.now().difference(widget.startTime);
      final remaining = widget.undoWindow - elapsed;

      if (remaining <= Duration.zero) {
        timer.cancel();
        if (mounted) {
          Navigator.of(context).pop(); // Auto-close when time expires
        }
        return;
      }

      setState(() {
        _timeRemaining = remaining;
      });
    });
  }

  Future<void> _handleUndo() async {
    try {
      await AuthService.instance.rollbackProviderMigration(
        userId: widget.userId,
        previousProvider: widget.previousProvider,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Migration undone successfully')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to undo migration: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.undo_rounded, color: colorScheme.primary, size: 28),
          const SizedBox(width: 12),
          const Text('Migration Complete'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your account has been successfully migrated.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Changed your mind? You can undo this change within the time limit.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer_rounded,
                  color: colorScheme.onSecondaryContainer,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Time remaining: ${_timeRemaining.inSeconds}s',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: SecondaryButton(
              onPressed: _handleUndo,
              child: const Text('Undo Migration'),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Keep Changes'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:travel_wizards/src/shared/widgets/travel_components/travel_components.dart';

/// Dialog shown when there's a provider conflict during authentication.
/// Allows users to choose between linking accounts or using one provider exclusively.
class MigrationDialog extends StatefulWidget {
  const MigrationDialog({
    super.key,
    required this.existingProvider,
    required this.newProvider,
    required this.email,
    required this.onLinkAccounts,
    required this.onUseExisting,
    required this.onUseNew,
    required this.onCancel,
    this.showUndoOption = false,
    this.onUndo,
    this.undoTimeRemaining,
  });

  final String existingProvider;
  final String newProvider;
  final String email;
  final VoidCallback onLinkAccounts;
  final VoidCallback onUseExisting;
  final VoidCallback onUseNew;
  final VoidCallback onCancel;
  final bool showUndoOption;
  final VoidCallback? onUndo;
  final Duration? undoTimeRemaining;

  @override
  State<MigrationDialog> createState() => _MigrationDialogState();
}

class _MigrationDialogState extends State<MigrationDialog> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            widget.showUndoOption
                ? Icons.undo_rounded
                : Icons.account_circle_rounded,
            color: colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.showUndoOption
                  ? 'Migration Complete'
                  : 'Account Already Exists',
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showUndoOption) ...[
              Text(
                'Your account has been successfully migrated.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Changed your mind? You can undo this change.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              if (widget.undoTimeRemaining != null) ...[
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
                        'Time remaining: ${widget.undoTimeRemaining!.inSeconds}s',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ] else ...[
              Text(
                'An account with ${widget.email} already exists using ${widget.existingProvider}.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Text(
                'You\'re trying to sign in with ${widget.newProvider}. How would you like to proceed?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              _buildOptionCard(
                icon: Icons.link_rounded,
                title: 'Link Accounts',
                description:
                    'Connect your ${widget.newProvider} account to your existing ${widget.existingProvider} account. You\'ll be able to sign in with either method.',
                buttonText: 'Link Accounts',
                onPressed: _handleLinkAccounts,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 16),
              _buildOptionCard(
                icon: Icons.swap_horiz_rounded,
                title: 'Use ${widget.existingProvider} Instead',
                description:
                    'Continue with your existing ${widget.existingProvider} account. Your ${widget.newProvider} sign-in attempt will be cancelled.',
                buttonText: 'Continue with ${widget.existingProvider}',
                onPressed: _handleUseExisting,
                color: colorScheme.secondary,
              ),
              const SizedBox(height: 16),
              _buildOptionCard(
                icon: Icons.refresh_rounded,
                title: 'Replace with ${widget.newProvider}',
                description:
                    'Switch to ${widget.newProvider} as your primary sign-in method. Your ${widget.existingProvider} account will be updated.',
                buttonText: 'Switch to ${widget.newProvider}',
                onPressed: _handleUseNew,
                color: colorScheme.tertiary,
              ),
            ],
            if (widget.showUndoOption) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: SecondaryButton(
                  onPressed: widget.onUndo,
                  child: const Text('Undo Migration'),
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              Text(
                'Note: Account linking preserves all your data and preferences. Switching providers may require re-entering some information.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : widget.onCancel,
          child: Text(widget.showUndoOption ? 'Keep Changes' : 'Cancel'),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String description,
    required String buttonText,
    required VoidCallback onPressed,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return TravelCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: SecondaryButton(
                onPressed: _isProcessing ? null : onPressed,
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLinkAccounts() async {
    setState(() => _isProcessing = true);
    try {
      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Brief delay for UX
      widget.onLinkAccounts();
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleUseExisting() async {
    setState(() => _isProcessing = true);
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      widget.onUseExisting();
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleUseNew() async {
    setState(() => _isProcessing = true);
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      widget.onUseNew();
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}

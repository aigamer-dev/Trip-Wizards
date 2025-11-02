import 'package:flutter/material.dart';
import 'package:travel_wizards/src/shared/services/travel_agent_service.dart';

/// Options for trip generation
enum TripGenerationMethod {
  adk, // Use AI agent for suggestions
  manual, // Manual entry only
}

/// Dialog for choosing between AI-assisted or manual trip creation
class TripGenerationOptionDialog extends StatefulWidget {
  const TripGenerationOptionDialog({super.key});

  @override
  State<TripGenerationOptionDialog> createState() =>
      _TripGenerationOptionDialogState();
}

class _TripGenerationOptionDialogState
    extends State<TripGenerationOptionDialog> {
  TripGenerationMethod _selectedMethod = TripGenerationMethod.adk;
  bool _adkAvailable = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkAdkAvailability();
  }

  Future<void> _checkAdkAvailability() async {
    try {
      final available = await TravelAgentService().isAvailable();
      if (mounted) {
        setState(() {
          _adkAvailable = available;
          _checking = false;
          if (!available) {
            // If ADK is not available, default to manual
            _selectedMethod = TripGenerationMethod.manual;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _adkAvailable = false;
          _checking = false;
          _selectedMethod = TripGenerationMethod.manual;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Create Your Trip'),
      content: _checking
          ? const Center(
              child: SizedBox(
                height: 40,
                width: 40,
                child: CircularProgressIndicator(),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'How would you like to plan your trip?',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 20),
                // AI-Assisted Option
                _buildOptionCard(
                  title: '✨ AI-Powered Planning',
                  description:
                      'Get personalized suggestions from Travel Concierge AI',
                  method: TripGenerationMethod.adk,
                  enabled: _adkAvailable,
                  scheme: scheme,
                ),
                const SizedBox(height: 12),
                // Manual Option
                _buildOptionCard(
                  title: '📝 Manual Entry',
                  description: 'Fill in your trip details step by step',
                  method: TripGenerationMethod.manual,
                  enabled: true,
                  scheme: scheme,
                ),
                if (!_adkAvailable)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.warningContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: scheme.onWarningContainer,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Travel Agent service unavailable. Using manual entry.',
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onWarningContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selectedMethod),
          child: const Text('Continue'),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String description,
    required TripGenerationMethod method,
    required bool enabled,
    required ColorScheme scheme,
  }) {
    final isSelected = _selectedMethod == method;

    return Material(
      child: InkWell(
        onTap: enabled ? () => setState(() => _selectedMethod = method) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? scheme.primary : scheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? scheme.primaryContainer
                : enabled
                ? scheme.surface
                : scheme.surfaceDisabled,
          ),
          child: Row(
            children: [
              Radio<TripGenerationMethod>(
                value: method,
                groupValue: _selectedMethod,
                onChanged: enabled
                    ? (value) {
                        if (value != null) {
                          setState(() => _selectedMethod = value);
                        }
                      }
                    : null,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: enabled
                            ? isSelected
                                  ? scheme.primary
                                  : scheme.onSurface
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: enabled
                            ? scheme.onSurfaceVariant
                            : scheme.surfaceDisabled,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Extension on ColorScheme for unsupported colors
extension ColorSchemeExtension on ColorScheme {
  Color get warningContainer => brightness == Brightness.dark
      ? const Color(0xFF4A3800)
      : const Color(0xFFFFF8E1);

  Color get onWarningContainer => brightness == Brightness.dark
      ? const Color(0xFFFFD54F)
      : const Color(0xFF331B00);

  Color get surfaceDisabled => brightness == Brightness.dark
      ? surface.withOpacity(0.38)
      : surface.withOpacity(0.38);
}

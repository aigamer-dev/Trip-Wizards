import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_wizards/src/shared/services/accessibility_service.dart';
import 'package:travel_wizards/src/shared/widgets/accessibility/accessible_widgets.dart';

/// Comprehensive accessibility settings screen
class AccessibilitySettingsScreen extends StatelessWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accessibility Settings')),
      body: Consumer<AccessibilityService>(
        builder: (context, accessibilityService, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(context, 'Display & Visual'),
              const SizedBox(height: 8),
              _buildHighContrastCard(context, accessibilityService),
              const SizedBox(height: 12),
              _buildTextSizeCard(context, accessibilityService),
              const SizedBox(height: 24),

              _buildHeader(context, 'Motion & Interaction'),
              const SizedBox(height: 8),
              _buildReduceMotionCard(context, accessibilityService),
              const SizedBox(height: 12),
              _buildTouchGuidanceCard(context, accessibilityService),
              const SizedBox(height: 24),

              _buildHeader(context, 'Screen Reader & Audio'),
              const SizedBox(height: 8),
              _buildSemanticLabelsCard(context, accessibilityService),
              const SizedBox(height: 12),
              _buildScreenReaderCard(context, accessibilityService),
              const SizedBox(height: 24),

              _buildHeader(context, 'System Information'),
              const SizedBox(height: 8),
              _buildSystemInfoCard(context, accessibilityService),
              const SizedBox(height: 24),

              _buildTestingSection(context, accessibilityService),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Semantics(
      header: true,
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildHighContrastCard(
    BuildContext context,
    AccessibilityService service,
  ) {
    return AccessibleCard(
      semanticLabel: 'High contrast mode settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.contrast,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'High Contrast',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Increases contrast between text and background for better visibility.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          AccessibleSwitch(
            value: service.isHighContrastEnabled,
            onChanged: (_) => service.toggleHighContrast(),
            label: 'Enable high contrast mode',
            semanticLabel: 'High contrast mode toggle',
            hint:
                'Makes text and backgrounds more contrasted for better visibility',
          ),
        ],
      ),
    );
  }

  Widget _buildTextSizeCard(
    BuildContext context,
    AccessibilityService service,
  ) {
    return AccessibleCard(
      semanticLabel: 'Text size settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.text_fields,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Text Size',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Adjust text size for better readability.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          AccessibleSlider(
            value: service.textScaleFactor,
            min: 0.8,
            max: 2.0,
            divisions: 12,
            label: 'Text Scale Factor',
            semanticLabel: 'Text size adjustment',
            semanticFormatter: (value) => '${(value * 100).round()}% text size',
            onChanged: (value) => service.setTextScaleFactor(value),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AccessibleButton(
                onPressed: () => service.setTextScaleFactor(0.8),
                semanticLabel: 'Small text size',
                child: const Text('Small'),
              ),
              AccessibleButton(
                onPressed: () => service.setTextScaleFactor(1.0),
                semanticLabel: 'Normal text size',
                child: const Text('Normal'),
              ),
              AccessibleButton(
                onPressed: () => service.setTextScaleFactor(1.3),
                semanticLabel: 'Large text size',
                child: const Text('Large'),
              ),
              AccessibleButton(
                onPressed: () => service.setTextScaleFactor(1.6),
                semanticLabel: 'Extra large text size',
                child: const Text('XL'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReduceMotionCard(
    BuildContext context,
    AccessibilityService service,
  ) {
    return AccessibleCard(
      semanticLabel: 'Reduce motion settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.motion_photos_off,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Reduce Motion',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Reduces or removes animations that might cause discomfort.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          AccessibleSwitch(
            value: service.isReduceMotionEnabled,
            onChanged: (_) => service.toggleReduceMotion(),
            label: 'Reduce motion and animations',
            semanticLabel: 'Reduce motion toggle',
            hint:
                'Minimizes animations that might cause discomfort or distraction',
          ),
        ],
      ),
    );
  }

  Widget _buildTouchGuidanceCard(
    BuildContext context,
    AccessibilityService service,
  ) {
    return AccessibleCard(
      semanticLabel: 'Touch guidance settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.touch_app,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Touch Guidance',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Provides haptic feedback for touch interactions.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          AccessibleSwitch(
            value: service.isTouchGuidanceEnabled,
            onChanged: (_) => service.toggleTouchGuidance(),
            label: 'Enable touch guidance with haptic feedback',
            semanticLabel: 'Touch guidance toggle',
            hint:
                'Provides vibration feedback when interacting with buttons and controls',
          ),
        ],
      ),
    );
  }

  Widget _buildSemanticLabelsCard(
    BuildContext context,
    AccessibilityService service,
  ) {
    return AccessibleCard(
      semanticLabel: 'Semantic labels settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.label, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Semantic Labels',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Enables descriptive labels for screen readers and assistive technologies.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          AccessibleSwitch(
            value: service.isSemanticLabelsEnabled,
            onChanged: (_) => service.toggleSemanticLabels(),
            label: 'Enable semantic labels',
            semanticLabel: 'Semantic labels toggle',
            hint: 'Provides descriptive labels for screen readers',
          ),
        ],
      ),
    );
  }

  Widget _buildScreenReaderCard(
    BuildContext context,
    AccessibilityService service,
  ) {
    return AccessibleCard(
      semanticLabel: 'Screen reader information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.record_voice_over,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Screen Reader',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            service.isScreenReaderEnabled
                ? 'Screen reader is currently active on your device.'
                : 'No screen reader detected. Enable TalkBack (Android) or VoiceOver (iOS) in system settings.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (service.isScreenReaderEnabled) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Screen reader support is active',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSystemInfoCard(
    BuildContext context,
    AccessibilityService service,
  ) {
    return AccessibleCard(
      semanticLabel: 'System accessibility information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'System Information',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            'Screen Reader',
            service.isScreenReaderEnabled ? 'Active' : 'Inactive',
          ),
          _buildInfoRow(
            context,
            'System High Contrast',
            service.isHighContrastEnabled ? 'Enabled' : 'Disabled',
          ),
          _buildInfoRow(
            context,
            'System Text Scale',
            '${(service.textScaleFactor * 100).round()}%',
          ),
          _buildInfoRow(
            context,
            'Reduce Motion',
            service.isReduceMotionEnabled ? 'Enabled' : 'Disabled',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTestingSection(
    BuildContext context,
    AccessibilityService service,
  ) {
    return AccessibleCard(
      semanticLabel: 'Accessibility testing tools',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bug_report,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Testing Tools',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tools to test and validate accessibility features.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          AccessibleButton(
            onPressed: () => _testScreenReaderAnnouncement(service),
            semanticLabel: 'Test screen reader announcement',
            child: const Text('Test Screen Reader'),
          ),
          const SizedBox(height: 8),
          AccessibleButton(
            onPressed: () => _testHapticFeedback(service),
            semanticLabel: 'Test haptic feedback',
            child: const Text('Test Haptic Feedback'),
          ),
          const SizedBox(height: 8),
          AccessibleButton(
            onPressed: () => _showContrastTestDialog(context),
            semanticLabel: 'Test color contrast',
            child: const Text('Test Color Contrast'),
          ),
        ],
      ),
    );
  }

  void _testScreenReaderAnnouncement(AccessibilityService service) {
    service.announceToScreenReader(
      'This is a test announcement for screen readers.',
    );
  }

  void _testHapticFeedback(AccessibilityService service) {
    service.provideHapticFeedback();
  }

  void _showContrastTestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Color Contrast Test'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black,
              child: const Text(
                'White text on black background',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[300],
              child: const Text(
                'Dark text on light background',
                style: TextStyle(color: Colors.black),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue,
              child: const Text(
                'White text on blue background',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        actions: [
          AccessibleButton(
            onPressed: () => Navigator.of(context).pop(),
            semanticLabel: 'Close contrast test dialog',
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

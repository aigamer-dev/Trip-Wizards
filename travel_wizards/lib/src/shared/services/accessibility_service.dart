import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';

/// Comprehensive accessibility service for managing accessibility features
/// throughout the Travel Wizards application.
class AccessibilityService extends ChangeNotifier {
  static AccessibilityService? _instance;
  static AccessibilityService get instance =>
      _instance ??= AccessibilityService._();

  AccessibilityService._();

  // Accessibility features state
  bool _isScreenReaderEnabled = false;
  bool _isHighContrastEnabled = false;
  bool _isLargeTextEnabled = false;
  double _textScaleFactor = 1.0;
  bool _isReduceMotionEnabled = false;
  bool _isSemanticLabelsEnabled = true;
  bool _isTouchGuidanceEnabled = false;
  SemanticsHandle? _semanticsHandle;

  // Getters
  bool get isScreenReaderEnabled => _isScreenReaderEnabled;
  bool get isHighContrastEnabled => _isHighContrastEnabled;
  bool get isLargeTextEnabled => _isLargeTextEnabled;
  double get textScaleFactor => _textScaleFactor;
  bool get isReduceMotionEnabled => _isReduceMotionEnabled;
  bool get isSemanticLabelsEnabled => _isSemanticLabelsEnabled;
  bool get isTouchGuidanceEnabled => _isTouchGuidanceEnabled;

  /// Initialize accessibility service and detect system accessibility settings
  Future<void> initialize() async {
    await _detectSystemAccessibilitySettings();
    _setupSemanticsBinding();
    notifyListeners();
  }

  /// Detect system accessibility settings
  Future<void> _detectSystemAccessibilitySettings() async {
    try {
      // Check if screen reader is enabled
      _isScreenReaderEnabled =
          SemanticsBinding.instance.accessibilityFeatures.accessibleNavigation;

      // Check if high contrast is enabled
      _isHighContrastEnabled =
          SemanticsBinding.instance.accessibilityFeatures.highContrast;

      // Check if large text is enabled
      _isLargeTextEnabled =
          SemanticsBinding.instance.accessibilityFeatures.accessibleNavigation;

      // Get text scale factor from system
      _textScaleFactor =
          WidgetsBinding.instance.platformDispatcher.textScaleFactor;

      // Check if reduce motion is enabled
      _isReduceMotionEnabled =
          SemanticsBinding.instance.accessibilityFeatures.reduceMotion;

      // Check if touch guidance is enabled
      _isTouchGuidanceEnabled =
          SemanticsBinding.instance.accessibilityFeatures.accessibleNavigation;
    } catch (e) {
      debugPrint('Error detecting accessibility settings: $e');
    }
  }

  /// Setup semantics binding for accessibility events
  void _setupSemanticsBinding() {
    if (kIsWeb) {
      // Flutter web semantics are still experimental and may assert when forced.
      return;
    }

    _semanticsHandle = SemanticsBinding.instance.ensureSemantics();
  }

  /// Dispose of resources
  @override
  void dispose() {
    _semanticsHandle?.dispose();
    _semanticsHandle = null;
    super.dispose();
  }

  /// Toggle high contrast mode
  void toggleHighContrast() {
    _isHighContrastEnabled = !_isHighContrastEnabled;
    notifyListeners();
    _announceAccessibilityChange(
      'High contrast ${_isHighContrastEnabled ? 'enabled' : 'disabled'}',
    );
  }

  /// Toggle large text mode
  void toggleLargeText() {
    _isLargeTextEnabled = !_isLargeTextEnabled;
    _textScaleFactor = _isLargeTextEnabled ? 1.3 : 1.0;
    notifyListeners();
    _announceAccessibilityChange(
      'Large text ${_isLargeTextEnabled ? 'enabled' : 'disabled'}',
    );
  }

  /// Set custom text scale factor
  void setTextScaleFactor(double factor) {
    _textScaleFactor = factor.clamp(0.8, 2.0);
    _isLargeTextEnabled = _textScaleFactor > 1.0;
    notifyListeners();
    _announceAccessibilityChange(
      'Text size changed to ${(_textScaleFactor * 100).round()}%',
    );
  }

  /// Toggle reduce motion mode
  void toggleReduceMotion() {
    _isReduceMotionEnabled = !_isReduceMotionEnabled;
    notifyListeners();
    _announceAccessibilityChange(
      'Reduce motion ${_isReduceMotionEnabled ? 'enabled' : 'disabled'}',
    );
  }

  /// Toggle semantic labels
  void toggleSemanticLabels() {
    _isSemanticLabelsEnabled = !_isSemanticLabelsEnabled;
    notifyListeners();
    _announceAccessibilityChange(
      'Semantic labels ${_isSemanticLabelsEnabled ? 'enabled' : 'disabled'}',
    );
  }

  /// Toggle touch guidance
  void toggleTouchGuidance() {
    _isTouchGuidanceEnabled = !_isTouchGuidanceEnabled;
    notifyListeners();
    _announceAccessibilityChange(
      'Touch guidance ${_isTouchGuidanceEnabled ? 'enabled' : 'disabled'}',
    );
  }

  /// Announce accessibility change to screen readers
  void _announceAccessibilityChange(String message) {
    if (_isScreenReaderEnabled) {
      SemanticsService.announce(message, TextDirection.ltr);
    }
  }

  /// Create accessibility-optimized theme
  ThemeData createAccessibleTheme(ThemeData baseTheme) {
    if (!_isHighContrastEnabled && _textScaleFactor == 1.0) {
      return baseTheme;
    }

    final colorScheme = _isHighContrastEnabled
        ? _createHighContrastColorScheme(baseTheme.colorScheme)
        : baseTheme.colorScheme;

    return baseTheme.copyWith(
      colorScheme: colorScheme,
      textTheme: _createAccessibleTextTheme(baseTheme.textTheme),
      elevatedButtonTheme: _createAccessibleButtonTheme(
        baseTheme.elevatedButtonTheme,
      ),
      outlinedButtonTheme: _createAccessibleOutlinedButtonTheme(
        baseTheme.outlinedButtonTheme,
      ),
      textButtonTheme: _createAccessibleTextButtonTheme(
        baseTheme.textButtonTheme,
      ),
    );
  }

  /// Create high contrast color scheme
  ColorScheme _createHighContrastColorScheme(ColorScheme base) {
    return base.copyWith(
      // High contrast colors for better visibility
      primary: const Color(0xFF000000),
      onPrimary: const Color(0xFFFFFFFF),
      secondary: const Color(0xFF1976D2),
      onSecondary: const Color(0xFFFFFFFF),
      surface: const Color(0xFFFFFFFF),
      onSurface: const Color(0xFF000000),
      error: const Color(0xFFD32F2F),
      onError: const Color(0xFFFFFFFF),
      outline: const Color(0xFF000000),
    );
  }

  /// Create accessible text theme with adjusted scaling
  TextTheme _createAccessibleTextTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: (base.displayLarge?.fontSize ?? 32) * _textScaleFactor,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontSize: (base.displayMedium?.fontSize ?? 28) * _textScaleFactor,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontSize: (base.displaySmall?.fontSize ?? 24) * _textScaleFactor,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: (base.headlineLarge?.fontSize ?? 22) * _textScaleFactor,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: (base.headlineMedium?.fontSize ?? 20) * _textScaleFactor,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: (base.headlineSmall?.fontSize ?? 18) * _textScaleFactor,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: (base.titleLarge?.fontSize ?? 16) * _textScaleFactor,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: (base.titleMedium?.fontSize ?? 14) * _textScaleFactor,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: (base.titleSmall?.fontSize ?? 12) * _textScaleFactor,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: (base.bodyLarge?.fontSize ?? 16) * _textScaleFactor,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: (base.bodyMedium?.fontSize ?? 14) * _textScaleFactor,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: (base.bodySmall?.fontSize ?? 12) * _textScaleFactor,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: (base.labelLarge?.fontSize ?? 14) * _textScaleFactor,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: (base.labelMedium?.fontSize ?? 12) * _textScaleFactor,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: (base.labelSmall?.fontSize ?? 10) * _textScaleFactor,
      ),
    );
  }

  /// Create accessible button theme with proper contrast and size
  ElevatedButtonThemeData _createAccessibleButtonTheme(
    ElevatedButtonThemeData? base,
  ) {
    return ElevatedButtonThemeData(
      style: (base?.style ?? ElevatedButton.styleFrom()).copyWith(
        minimumSize: WidgetStateProperty.all(
          Size(48 * _textScaleFactor, 48 * _textScaleFactor),
        ),
        padding: WidgetStateProperty.all(EdgeInsets.all(16 * _textScaleFactor)),
      ),
    );
  }

  /// Create accessible outlined button theme
  OutlinedButtonThemeData _createAccessibleOutlinedButtonTheme(
    OutlinedButtonThemeData? base,
  ) {
    return OutlinedButtonThemeData(
      style: (base?.style ?? OutlinedButton.styleFrom()).copyWith(
        minimumSize: WidgetStateProperty.all(
          Size(48 * _textScaleFactor, 48 * _textScaleFactor),
        ),
        padding: WidgetStateProperty.all(EdgeInsets.all(16 * _textScaleFactor)),
      ),
    );
  }

  /// Create accessible text button theme
  TextButtonThemeData _createAccessibleTextButtonTheme(
    TextButtonThemeData? base,
  ) {
    return TextButtonThemeData(
      style: (base?.style ?? TextButton.styleFrom()).copyWith(
        minimumSize: WidgetStateProperty.all(
          Size(48 * _textScaleFactor, 48 * _textScaleFactor),
        ),
        padding: WidgetStateProperty.all(EdgeInsets.all(16 * _textScaleFactor)),
      ),
    );
  }

  /// Announce screen reader message
  void announceToScreenReader(String message) {
    if (_isScreenReaderEnabled && _isSemanticLabelsEnabled) {
      SemanticsService.announce(message, TextDirection.ltr);
    }
  }

  /// Provide haptic feedback for accessibility actions
  void provideHapticFeedback() {
    if (_isTouchGuidanceEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  /// Get animation duration based on reduce motion setting
  Duration getAnimationDuration(Duration defaultDuration) {
    return _isReduceMotionEnabled ? Duration.zero : defaultDuration;
  }

  /// Check if minimum touch target size is met
  bool isMinimumTouchTargetSize(Size size) {
    const minSize = 48.0;
    return size.width >= minSize && size.height >= minSize;
  }

  /// Validate color contrast ratio
  bool hasValidContrast(Color foreground, Color background) {
    final foregroundLuminance = foreground.computeLuminance();
    final backgroundLuminance = background.computeLuminance();

    final lighter = foregroundLuminance > backgroundLuminance
        ? foregroundLuminance
        : backgroundLuminance;
    final darker = foregroundLuminance > backgroundLuminance
        ? backgroundLuminance
        : foregroundLuminance;

    final contrastRatio = (lighter + 0.05) / (darker + 0.05);

    // WCAG AA compliance requires 4.5:1 for normal text, 3:1 for large text
    return contrastRatio >= 4.5;
  }
}

/// Widget that provides accessibility context to child widgets
class AccessibilityProvider extends StatelessWidget {
  final Widget child;

  const AccessibilityProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AccessibilityService>.value(
      value: AccessibilityService.instance,
      child: child,
    );
  }
}

/// Mixin for accessibility helpers in widgets
mixin AccessibilityMixin {
  /// Get accessibility service from context
  AccessibilityService getAccessibilityService(BuildContext context) {
    return Provider.of<AccessibilityService>(context, listen: false);
  }

  /// Create semantic wrapper for widgets
  Widget wrapWithSemantics({
    required Widget child,
    String? label,
    String? hint,
    String? value,
    bool? button,
    bool? link,
    bool? header,
    bool? focused,
    bool? selected,
    VoidCallback? onTap,
    String? customSemanticLabel,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      value: value,
      button: button ?? false,
      link: link ?? false,
      header: header ?? false,
      focused: focused ?? false,
      selected: selected ?? false,
      onTap: onTap,
      child: customSemanticLabel != null
          ? ExcludeSemantics(child: child)
          : child,
    );
  }

  /// Create accessible button with proper semantics
  Widget createAccessibleButton({
    required Widget child,
    required VoidCallback? onPressed,
    required BuildContext context,
    String? semanticLabel,
    String? tooltip,
    ButtonStyle? style,
  }) {
    final accessibilityService = getAccessibilityService(context);

    return Tooltip(
      message: tooltip ?? '',
      child: Semantics(
        label: semanticLabel,
        button: true,
        enabled: onPressed != null,
        child: ElevatedButton(
          onPressed: onPressed == null
              ? null
              : () {
                  accessibilityService.provideHapticFeedback();
                  onPressed();
                },
          style: style,
          child: child,
        ),
      ),
    );
  }

  /// Create accessible text field with proper semantics
  Widget createAccessibleTextField({
    required TextEditingController controller,
    required String label,
    required BuildContext context,
    String? hint,
    String? semanticLabel,
    bool required = false,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return Semantics(
      label: semanticLabel ?? label,
      textField: true,
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
          hintText: hint,
        ),
        keyboardType: keyboardType,
        onChanged: onChanged,
      ),
    );
  }
}

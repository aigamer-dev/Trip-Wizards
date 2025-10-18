import 'package:flutter/widgets.dart';

/// Legacy offline settings screen kept as a stub to maintain backward compatibility.
@Deprecated(
  'Offline settings have been removed; this stub prevents stale route access.',
)
class OfflineSettingsScreen extends StatelessWidget {
  const OfflineSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    throw UnsupportedError(
      'Offline settings screen has been removed from the app.',
    );
  }
}

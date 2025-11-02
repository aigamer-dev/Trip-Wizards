import 'dart:async';

import 'travel_wizards_service_registry.dart';

@Deprecated('Use TravelWizardsServiceRegistry.initialize() instead.')
Future<void> setupServiceLocator() => TravelWizardsServiceRegistry.initialize();

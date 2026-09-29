library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/navigation_launcher_service.dart';

final driverNavigationLauncherProvider = Provider<NavigationLauncherService>(
  (ref) => const NavigationLauncherService(),
);

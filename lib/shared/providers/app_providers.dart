/// Providers Riverpod globaux de l'application.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/router/passenger_router.dart';
import '../../core/router/driver_router.dart';
import '../../features/driver/settings/providers/driver_settings_provider.dart';
import '../../features/passenger/settings/providers/passenger_settings_provider.dart';

/// ThemeMode selon le paramètre dark mode de l'utilisateur connecté.
final themeModeProvider = Provider<ThemeMode>((ref) {
  if (AppConfig.instance.isDriver) {
    final settings = ref.watch(driverSettingsProvider);
    return settings.darkModeEnabled ? ThemeMode.dark : ThemeMode.light;
  }
  final settings = ref.watch(passengerSettingsProvider);
  return settings.darkModeEnabled ? ThemeMode.dark : ThemeMode.light;
});

/// Provider du GoRouter (singleton).
final appRouterProvider = Provider<GoRouter>((ref) {
  final config = AppConfig.instance;

  if (config.isDriver) {
    return createDriverRouter(ref);
  } else {
    return createPassengerRouter(ref);
  }
});

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../features/passenger/auth/providers/passenger_auth_provider.dart';
import '../models/auth_state.dart';
import 'main_app_zone_provider.dart';

final passengerDeviceStatusAlertAuthProvider = Provider<AuthStatus>((ref) {
  return ref.watch(passengerAuthProvider.select((state) => state.status));
});

final deviceStatusAlertVisibilityProvider = Provider<bool>((ref) {
  final config = AppConfig.instance;
  if (config.isDriver) {
    return ref.watch(mainAppZoneProvider);
  }

  final authStatus = ref.watch(passengerDeviceStatusAlertAuthProvider);
  return authStatus == AuthStatus.authenticated;
});

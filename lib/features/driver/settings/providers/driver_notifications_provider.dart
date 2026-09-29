import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'driver_settings_provider.dart';

final driverNotificationsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final service = ref.watch(driverSettingsServiceProvider);
      return service.getOwnNotifications();
    });

class DriverNotificationsController extends StateNotifier<bool> {
  DriverNotificationsController(this._ref) : super(false);

  final Ref _ref;

  Future<void> markAsRead(List<int> ids) async {
    if (ids.isEmpty || state) return;
    state = true;
    try {
      final service = _ref.read(driverSettingsServiceProvider);
      await service.markNotificationsAsRead(ids);
      _ref.invalidate(driverNotificationsProvider);
    } finally {
      state = false;
    }
  }
}

final driverNotificationsControllerProvider =
    StateNotifierProvider<DriverNotificationsController, bool>(
      (ref) => DriverNotificationsController(ref),
    );

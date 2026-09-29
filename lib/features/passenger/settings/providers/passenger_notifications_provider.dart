import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'passenger_settings_provider.dart';

final passengerNotificationsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final service = ref.watch(passengerSettingsServiceProvider);
      return service.getOwnNotifications();
    });

class PassengerNotificationsController extends StateNotifier<bool> {
  PassengerNotificationsController(this._ref) : super(false);

  final Ref _ref;

  Future<void> markAsRead(List<int> ids) async {
    if (ids.isEmpty || state) return;
    state = true;
    try {
      final service = _ref.read(passengerSettingsServiceProvider);
      await service.markNotificationsAsRead(ids);
      _ref.invalidate(passengerNotificationsProvider);
    } finally {
      state = false;
    }
  }
}

final passengerNotificationsControllerProvider =
    StateNotifierProvider<PassengerNotificationsController, bool>(
      (ref) => PassengerNotificationsController(ref),
    );

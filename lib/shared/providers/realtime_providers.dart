library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/realtime/realtime_events.dart';
import '../../core/realtime/realtime_service.dart';
import '../../core/realtime/socket_health_state.dart';
import '../../core/realtime/socket_io_realtime_service.dart';

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = SocketIoRealtimeService();
  ref.onDispose(service.dispose);
  return service;
});

final realtimeHealthStateProvider = StateProvider<SocketHealthState>(
  (ref) => SocketHealthState.offline,
);

final driverRideStatusRealtimeProvider =
    StateProvider<DriverRideStatusRealtimeEvent?>((ref) => null);

final driverRealtimeOffersEnabledProvider = Provider<bool>((ref) => true);

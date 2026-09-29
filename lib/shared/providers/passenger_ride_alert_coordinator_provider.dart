library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/services/app_alert_service.dart';
import '../../core/services/passenger_ride_alert_sound_service.dart';
import '../../domain/models/active_ride.dart';
import '../../domain/models/ride_status.dart';
import '../../features/passenger/booking/providers/active_ride_check_provider.dart';
import '../../features/passenger/booking/providers/active_ride_provider.dart';
import '../../features/passenger/booking/providers/booking_flow_provider.dart';
import '../../features/passenger/settings/providers/passenger_settings_provider.dart';
import 'app_alert_provider.dart';
import 'passenger_ride_alert_sound_provider.dart';

final passengerRideAlertCoordinatorProvider = Provider<void>((ref) {
  if (!AppConfig.instance.isPassenger) return;

  final controller = _PassengerRideAlertCoordinator(
    alertService: ref.read(appAlertServiceProvider),
    soundService: ref.read(passengerRideAlertSoundServiceProvider),
  );

  ref.onDispose(controller.dispose);

  ref.listen<AsyncValue<ActiveRide?>>(activeRideCheckProvider, (_, next) {
    controller.onHydrationUpdated(
      hydration: next,
      ride: ref.read(activeRideControllerProvider),
      flowState: ref.read(bookingFlowProvider),
    );
  });

  ref.listen<ActiveRide?>(activeRideControllerProvider, (_, next) {
    final settings = ref.read(passengerSettingsProvider);
    controller.onRideChanged(
      ride: next,
      flowState: ref.read(bookingFlowProvider),
      settingsLoaded: !settings.isLoading,
      notificationsEnabled: settings.notificationsEnabled,
      soundsEnabled: settings.soundsEnabled,
    );
  });

  ref.listen<BookingFlowState>(bookingFlowProvider, (_, next) {
    final settings = ref.read(passengerSettingsProvider);
    controller.onFlowChanged(
      flowState: next,
      ride: ref.read(activeRideControllerProvider),
      settingsLoaded: !settings.isLoading,
      notificationsEnabled: settings.notificationsEnabled,
      soundsEnabled: settings.soundsEnabled,
    );
  });

  controller.initialize(
    hydration: ref.read(activeRideCheckProvider),
    ride: ref.read(activeRideControllerProvider),
    flowState: ref.read(bookingFlowProvider),
  );
});

class _PassengerRideAlertCoordinator {
  _PassengerRideAlertCoordinator({
    required AppAlertService alertService,
    required PassengerRideAlertSoundService soundService,
  }) : _alertService = alertService,
       _soundService = soundService;

  final AppAlertService _alertService;
  final PassengerRideAlertSoundService _soundService;

  bool _isHydrating = true;
  bool _disposed = false;
  String? _rideId;
  String? _lastAlertKey;

  void initialize({
    required AsyncValue<ActiveRide?> hydration,
    required ActiveRide? ride,
    required BookingFlowState flowState,
  }) {
    _rideId = ride?.rideId;
    _primeSnapshot(ride: ride, flowState: flowState);
    _resolveHydration(hydration, ride: ride, flowState: flowState);
  }

  void onHydrationUpdated({
    required AsyncValue<ActiveRide?> hydration,
    required ActiveRide? ride,
    required BookingFlowState flowState,
  }) {
    if (_disposed) return;
    _resolveHydration(hydration, ride: ride, flowState: flowState);
  }

  void onRideChanged({
    required ActiveRide? ride,
    required BookingFlowState flowState,
    required bool settingsLoaded,
    required bool notificationsEnabled,
    required bool soundsEnabled,
  }) {
    if (_disposed) return;
    final nextRideId = ride?.rideId;
    if (_rideId != nextRideId) {
      _rideId = nextRideId;
      _lastAlertKey = null;
    }
    if (_isHydrating) {
      _primeSnapshot(ride: ride, flowState: flowState);
      return;
    }
    if (!settingsLoaded) return;
    _emitAlert(
      _buildAlert(flowState: flowState, ride: ride, rideId: _rideId),
      notificationsEnabled: notificationsEnabled,
      soundsEnabled: soundsEnabled,
    );
  }

  void onFlowChanged({
    required BookingFlowState flowState,
    required ActiveRide? ride,
    required bool settingsLoaded,
    required bool notificationsEnabled,
    required bool soundsEnabled,
  }) {
    if (_disposed) return;
    _rideId = ride?.rideId ?? _rideId;
    if (_isHydrating) {
      _primeSnapshot(ride: ride, flowState: flowState);
      return;
    }
    if (!settingsLoaded) return;
    final alert = _buildAlert(
      flowState: flowState,
      ride: ride,
      rideId: _rideId,
    );
    _emitAlert(
      alert,
      notificationsEnabled: notificationsEnabled,
      soundsEnabled: soundsEnabled,
    );
  }

  void _emitAlert(
    _PassengerRideAlert? alert, {
    required bool notificationsEnabled,
    required bool soundsEnabled,
  }) {
    if (alert == null || alert.key == _lastAlertKey) return;
    _lastAlertKey = alert.key;
    if (notificationsEnabled) {
      _alertService.showInfo(alert.message);
    }
    if (soundsEnabled) {
      unawaited(_soundService.playAlert());
    }
  }

  void _resolveHydration(
    AsyncValue<ActiveRide?> hydration, {
    required ActiveRide? ride,
    required BookingFlowState flowState,
  }) {
    if (_disposed || hydration.isLoading) return;
    _primeSnapshot(ride: ride, flowState: flowState);
    _isHydrating = false;
  }

  void _primeSnapshot({
    required ActiveRide? ride,
    required BookingFlowState flowState,
  }) {
    _rideId = ride?.rideId ?? _rideId;
    _lastAlertKey = _buildAlert(
      flowState: flowState,
      ride: ride,
      rideId: _rideId,
    )?.key;
  }

  _PassengerRideAlert? _buildAlert({
    required BookingFlowState flowState,
    required ActiveRide? ride,
    required String? rideId,
  }) {
    if (rideId == null || rideId.isEmpty) return null;
    final rideStatus = ride?.status;
    final message = switch (rideStatus) {
      RideStatus.accepted => 'Chauffeur trouvé',
      RideStatus.arrived => 'Votre chauffeur est arrivé',
      RideStatus.inProgress => 'Début de la course',
      RideStatus.completed => 'Course terminée',
      _ => switch (flowState) {
        BookingFlowState.driverAssigned => 'Chauffeur trouvé',
        BookingFlowState.arrived => 'Votre chauffeur est arrivé',
        BookingFlowState.inProgress => 'Début de la course',
        BookingFlowState.completed => 'Course terminée',
        _ => null,
      },
    };
    if (message == null) return null;
    final statusKey = rideStatus?.name ?? flowState.name;
    return _PassengerRideAlert(key: '$rideId:$statusKey', message: message);
  }

  void dispose() {
    _disposed = true;
  }
}

class _PassengerRideAlert {
  const _PassengerRideAlert({required this.key, required this.message});

  final String key;
  final String message;
}

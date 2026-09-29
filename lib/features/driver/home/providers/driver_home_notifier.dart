library;

import 'dart:async';
import 'dart:collection';

import 'package:flutter_riverpod/legacy.dart';

import 'package:flutter/foundation.dart';

import '../../../../core/realtime/realtime_events.dart';
import '../../../../core/utils/constants.dart';
import '../../../../domain/models/ride_status.dart';
import '../../../../core/utils/map_parsing_utils.dart';
import '../../../../domain/models/driver_ride.dart';
import '../../../../domain/usecases/driver/rides/accept_driver_ride.dart';
import '../../../../domain/usecases/driver/rides/cancel_driver_ride.dart';
import '../../../../domain/usecases/driver/rides/complete_driver_ride.dart';
import '../../../../domain/usecases/driver/rides/fetch_available_driver_rides.dart';
import '../../../../domain/usecases/driver/rides/get_driver_active_ride.dart';
import '../../../../domain/usecases/driver/rides/mark_driver_ride_arrived.dart';
import '../../../../domain/usecases/driver/rides/start_driver_ride.dart';
import '../../../../data/sources/local_storage.dart';
import '../../../../domain/usecases/driver/status/update_driver_status.dart';
import '../../auth/providers/driver_admin_status_gate.dart';
import 'driver_home_action_executor.dart';
import 'driver_home_arrival_detection.dart';
import 'driver_home_critical_actions.dart';
import 'driver_home_live_location.dart';
import 'driver_home_live_stats_tracker.dart';
import 'driver_home_pre_arrival_policy.dart';
import 'driver_home_ride_loader.dart';
import 'driver_home_state.dart';

part 'driver_home_notifier_helpers.dart';
part 'driver_home_notifier_lifecycle.dart';

class DriverHomeNotifier extends StateNotifier<DriverHomeState>
    with
        DriverHomeCriticalActions,
        DriverHomeLiveLocation,
        DriverHomeArrivalDetection {
  DriverHomeNotifier({
    required AcceptDriverRideUseCase acceptRideUseCase,
    required MarkDriverRideArrivedUseCase markArrivedUseCase,
    required StartDriverRideUseCase startRideUseCase,
    required CompleteDriverRideUseCase completeRideUseCase,
    required CancelDriverRideUseCase cancelRideUseCase,
    required FetchAvailableDriverRidesUseCase fetchAvailableRidesUseCase,
    required GetDriverActiveRideUseCase getActiveRideUseCase,
    required UpdateDriverStatusUseCase updateDriverStatusUseCase,
    Duration pollingInterval = const Duration(seconds: 4),
  }) : _actionExecutor = DriverHomeActionExecutor(
         acceptRideUseCase: acceptRideUseCase,
         markArrivedUseCase: markArrivedUseCase,
         startRideUseCase: startRideUseCase,
         completeRideUseCase: completeRideUseCase,
         cancelRideUseCase: cancelRideUseCase,
       ),
       _rideLoader = DriverHomeRideLoader(
         fetchAvailableRidesUseCase: fetchAvailableRidesUseCase,
         getActiveRideUseCase: getActiveRideUseCase,
       ),
       _updateDriverStatusUseCase = updateDriverStatusUseCase,
       _pollingInterval = pollingInterval,
       super(const DriverHomeState());
  final DriverHomeActionExecutor _actionExecutor;
  final DriverHomeRideLoader _rideLoader;
  final DriverHomeLiveStatsTracker _statsTracker = DriverHomeLiveStatsTracker();
  final UpdateDriverStatusUseCase _updateDriverStatusUseCase;
  final Duration _pollingInterval;
  Map<String, dynamic>? _userData;
  Timer? _pollingTimer;
  bool _pollingPausedByIncomingRequest = false;
  bool _hasRestoredOnlineStatus = false;
  bool _appClosingSyncInFlight = false;
  int? _ignoredRideIdsDriverId;

  static String _onlineKey(int? id) => 'driver_is_online_$id';
  static const int _maxIgnoredIncomingRideIds = 500;
  DriverHomeState get _currentState => state;
  @override
  VoidCallback? onRideCompleted;
  @override
  DriverHomeActionExecutor get actionExecutor => _actionExecutor;
  @override
  DriverHomeRideLoader get rideLoader => _rideLoader;
  @override
  Map<String, dynamic>? get userData => _userData;
  @override
  int? get driverId => toInt(_userData?['driverId']);
  int? get userId => toInt(_userData?['userId']);

  DriverRide? get activeRide => state.activeRide;
  bool get isOnline => state.isOnline;
  @override
  DriverHomeState withLiveStats(DriverHomeState nextState) {
    return applyArrivalDetectionToState(
      applyRealtimeLocationToState(_statsTracker.applyTo(nextState)),
    );
  }

  @override
  void recordCompletedRide(DriverRide ride) {
    _statsTracker.recordCompletedRide(ride);
  }

  void seedTodayRides(List<DriverRide> rides) {
    DriverHomeNotifierLifecycle(this).seedTodayRides(rides);
  }

  void syncUserData(Map<String, dynamic>? userData) {
    DriverHomeNotifierLifecycle(this).syncUserData(userData);
  }

  Future<void> setOnline(bool value) {
    return DriverHomeNotifierLifecycle(this).setOnline(value);
  }

  Future<void> restoreOnlineStatus() {
    return DriverHomeNotifierLifecycle(this).restoreOnlineStatus();
  }

  Future<void> handleAppClosing() {
    return DriverHomeNotifierLifecycle(this).handleAppClosing();
  }

  Future<void> declineRideLocally(String rideId) async {
    final trimmedRideId = rideId.trim();
    if (trimmedRideId.isEmpty) {
      return;
    }

    final ignoredRideIds = _appendIgnoredIncomingRideId(
      state.ignoredIncomingRideIds,
      trimmedRideId,
    );
    _applyIgnoredIncomingRideIds(ignoredRideIds);
    await _saveIgnoredIncomingRideIds(ignoredRideIds);
  }

  Future<void> refreshHome() async {
    if (!state.isOnline || state.isRefreshing || state.isSubmittingAction) {
      return;
    }
    final currentDriverId = driverId;
    if (currentDriverId == null) {
      _setRefreshError('Impossible d\'identifier le chauffeur connecté.');
      return;
    }

    _setState(state.copyWith(isRefreshing: true, errorMessage: null));
    final hadActiveRide = state.activeRide != null;
    final driverPos = state.currentDriverLocation;
    final destination = state.activeRide?.destinationLocation;
    final isPreArrival =
        hadActiveRide &&
        driverPos != null &&
        destination != null &&
        DriverHomePreArrivalPolicy.isInPreArrivalZone(
          driverLocation: driverPos,
          destination: destination,
        );
    final result = await _rideLoader.refresh(
      driverId: currentDriverId,
      activeRideId: state.activeRide?.rideId,
      driverLat: driverPos?.latitude,
      driverLng: driverPos?.longitude,
      fetchAvailableRides: isPreArrival,
    );
    if (hadActiveRide && !result.hasError && result.activeRide == null) {
      final queued = state.queuedRide;
      if (queued != null) {
        _setState(
          state.copyWith(
            status: DriverHomeStatus.ready,
            isRefreshing: false,
            activeRide: queued,
            queuedRide: null,
            availableRides: const [],
            isPreArrivalOffersActive: false,
            errorMessage: null,
          ),
        );
        return;
      }
      final availableResult = await _rideLoader.refresh(
        driverId: currentDriverId,
        activeRideId: null,
        driverLat: state.currentDriverLocation?.latitude,
        driverLng: state.currentDriverLocation?.longitude,
      );
      _driverHomeApplyRideLoadResult(this, availableResult);
      return;
    }
    _driverHomeApplyRideLoadResult(this, result);
  }

  Future<void> applyRealtimeRideStatus(
    DriverRideStatusRealtimeEvent event,
  ) async {
    final currentRide = state.activeRide;
    if (currentRide == null || currentRide.rideId != event.rideId) {
      return;
    }
    if (!event.isCancelled && !event.isCompleted) {
      return;
    }

    final queued = state.queuedRide;
    _setState(
      state.copyWith(
        status: DriverHomeStatus.ready,
        isRefreshing: false,
        isSubmittingAction: false,
        activeRide: queued,
        queuedRide: null,
        availableRides: const [],
        isPreArrivalOffersActive: false,
        errorMessage: null,
      ),
    );

    if (event.isCompleted) {
      onRideCompleted?.call();
    }

    if (queued != null) return;

    if (!state.isOnline || driverId == null) {
      return;
    }
    await refreshHome();
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void pausePollingForIncomingRequest() {
    if (_pollingPausedByIncomingRequest || !state.isOnline) {
      return;
    }
    _pollingPausedByIncomingRequest = true;
    stopPolling();
  }

  Future<void> resumePollingAfterIncomingDecision({
    bool refreshNow = false,
  }) async {
    if (!_pollingPausedByIncomingRequest || !state.isOnline) {
      return;
    }
    _pollingPausedByIncomingRequest = false;
    _driverHomeStartPolling(this);
    if (refreshNow) {
      await refreshHome();
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }

  void _setRefreshError(String message) {
    _setState(
      state.copyWith(
        status: state.hasActiveRide || state.hasAvailableRides
            ? DriverHomeStatus.ready
            : DriverHomeStatus.error,
        isRefreshing: false,
        errorMessage: message,
      ),
    );
  }

  void _setState(DriverHomeState nextState) {
    state = withLiveStats(nextState);
  }

  List<DriverRide> _filterIgnoredAvailableRides(
    List<DriverRide> rides, {
    List<String>? ignoredRideIds,
  }) {
    final currentIgnoredRideIds =
        ignoredRideIds ?? state.ignoredIncomingRideIds;
    if (rides.isEmpty || currentIgnoredRideIds.isEmpty) {
      return rides;
    }

    final ignoredRideIdSet = currentIgnoredRideIds.toSet();
    return rides
        .where((ride) => !ignoredRideIdSet.contains(ride.rideId))
        .toList(growable: false);
  }

  void _applyIgnoredIncomingRideIds(List<String> ignoredRideIds) {
    final filteredAvailableRides = _filterIgnoredAvailableRides(
      state.availableRides,
      ignoredRideIds: ignoredRideIds,
    );
    _setState(
      state.copyWith(
        ignoredIncomingRideIds: ignoredRideIds,
        availableRides: filteredAvailableRides,
        isPreArrivalOffersActive:
            state.isPreArrivalOffersActive && filteredAvailableRides.isNotEmpty,
      ),
    );
  }

  List<String> _appendIgnoredIncomingRideId(
    List<String> ignoredRideIds,
    String rideId,
  ) {
    return _normalizeIgnoredIncomingRideIds([
      ...ignoredRideIds.where((id) => id != rideId),
      rideId,
    ]);
  }

  List<String> _normalizeIgnoredIncomingRideIds(Iterable<String> rawIds) {
    final queue = Queue<String>();
    for (final rawId in rawIds) {
      final rideId = rawId.trim();
      if (rideId.isEmpty) {
        continue;
      }
      queue.remove(rideId);
      queue.addLast(rideId);
      while (queue.length > _maxIgnoredIncomingRideIds) {
        queue.removeFirst();
      }
    }
    return List<String>.unmodifiable(queue);
  }

  Future<void> _restoreIgnoredIncomingRideIds() async {
    final currentDriverId = driverId;
    if (currentDriverId == null) {
      _ignoredRideIdsDriverId = null;
      _applyIgnoredIncomingRideIds(const []);
      return;
    }

    _ignoredRideIdsDriverId = currentDriverId;
    final storage = LocalStorage.instance;
    if (!storage.isInitialized) {
      _applyIgnoredIncomingRideIds(const []);
      return;
    }

    final ignoredRideIds = _normalizeIgnoredIncomingRideIds(
      storage.getStringList(_ignoredRideIdsKey(currentDriverId)) ?? const [],
    );
    if (_ignoredRideIdsDriverId != currentDriverId) {
      return;
    }
    _applyIgnoredIncomingRideIds(ignoredRideIds);
  }

  Future<void> _saveIgnoredIncomingRideIds(List<String> ignoredRideIds) async {
    final currentDriverId = driverId;
    final storage = LocalStorage.instance;
    if (currentDriverId == null || !storage.isInitialized) {
      return;
    }

    await storage.setStringList(
      _ignoredRideIdsKey(currentDriverId),
      ignoredRideIds,
    );
  }

  String _ignoredRideIdsKey(int driverId) {
    return '${AppConstants.driverIgnoredRideIdsKeyPrefix}$driverId';
  }
}

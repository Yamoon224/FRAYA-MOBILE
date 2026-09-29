library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/utils/map_parsing_utils.dart';
import '../../../../domain/models/driver_ride.dart';
import '../../../../domain/models/ride_status.dart';
import '../../auth/providers/driver_admin_status_gate.dart';
import 'driver_home_action_executor.dart';
import 'driver_home_ride_loader.dart';
import 'driver_home_state.dart';

mixin DriverHomeCriticalActions on StateNotifier<DriverHomeState> {
  DriverHomeActionExecutor get actionExecutor;
  DriverHomeRideLoader get rideLoader;
  Map<String, dynamic>? get userData;
  int? get driverId;
  DriverHomeState withLiveStats(DriverHomeState nextState);
  void recordCompletedRide(DriverRide ride);
  VoidCallback? get onRideCompleted;

  Future<bool> acceptRide(String rideId) async {
    final gate = DriverAdminStatusGate.fromUserData(userData);
    final currentDriverId = driverId;
    final currentVehicleId = toInt(userData?['vehicleId']);

    if (rideId.trim().isEmpty) {
      return _rejectAction('Course introuvable.');
    }
    if (currentDriverId == null) {
      return _rejectAction('Impossible d\'identifier le chauffeur connecté.');
    }
    if (!gate.canGoOnline) {
      return _rejectAction(
        gate.blockingMessage ??
            'Une validation admin est requise avant de conduire.',
      );
    }
    if (currentVehicleId == null) {
      return _rejectAction(
        'Aucun véhicule approuvé n\'est disponible pour accepter cette course.',
      );
    }

    if (state.hasQueuedRide) {
      return _rejectAction(
        'Une autre course en attente est deja associee a ce chauffeur.',
      );
    }

    final isQueuedAccept =
        state.isPreArrivalOffersActive && state.activeRide != null;

    return _runCriticalAction(
      rideId: rideId,
      isQueuedAccept: isQueuedAccept,
      action: () => actionExecutor.acceptRide(
        rideId: rideId,
        driverId: currentDriverId,
        vehicleId: currentVehicleId,
      ),
    );
  }

  Future<bool> markArrived({
    required String rideId,
    required double driverLat,
    required double driverLng,
  }) {
    if (rideId.trim().isEmpty) {
      return _rejectAction('Course introuvable.');
    }
    return _runCriticalAction(
      rideId: rideId,
      action: () => actionExecutor.markArrived(
        rideId: rideId,
        driverLat: driverLat,
        driverLng: driverLng,
      ),
    );
  }

  Future<bool> startRide(String rideId) {
    if (rideId.trim().isEmpty) {
      return _rejectAction('Course introuvable.');
    }
    return _runCriticalAction(
      rideId: rideId,
      action: () => actionExecutor.startRide(rideId: rideId),
    );
  }

  Future<bool> completeRide({
    required String rideId,
    required double finalDistanceKm,
    required int finalDurationMin,
    required int finalPrice,
    int additionnalFreeSeconds = 0,
  }) {
    if (rideId.trim().isEmpty) {
      return _rejectAction('Course introuvable.');
    }
    final completedRide = state.activeRide?.rideId == rideId
        ? state.activeRide?.copyWith(
            status: RideStatus.completed,
            finalPrice: finalPrice.toDouble(),
            estimatedDistanceKm: finalDistanceKm,
            estimatedDurationMin: finalDurationMin,
            updatedAt: DateTime.now(),
          )
        : null;
    return _runCriticalAction(
      rideId: rideId,
      completedRide: completedRide,
      action: () => actionExecutor.completeRide(
        rideId: rideId,
        finalDistanceKm: finalDistanceKm,
        finalDurationMin: finalDurationMin,
        finalPrice: finalPrice,
        additionnalFreeSeconds: additionnalFreeSeconds,
      ),
    );
  }

  Future<bool> cancelRide({required String rideId, String? reason}) {
    if (rideId.trim().isEmpty) {
      return _rejectAction('Course introuvable.');
    }
    return _runCriticalAction(
      rideId: rideId,
      action: () => actionExecutor.cancelRide(rideId: rideId, reason: reason),
    );
  }

  Future<bool> _runCriticalAction({
    required String rideId,
    required Future<String?> Function() action,
    DriverRide? completedRide,
    bool isQueuedAccept = false,
  }) async {
    if (state.isSubmittingAction) {
      return false;
    }

    state = withLiveStats(
      state.copyWith(isSubmittingAction: true, errorMessage: null),
    );
    final errorMessage = await action();
    if (errorMessage == null && completedRide != null) {
      recordCompletedRide(completedRide);
      onRideCompleted?.call();
    }
    await _resyncAfterAction(rideId, isQueuedAccept: isQueuedAccept);

    state = withLiveStats(
      state.copyWith(
        isSubmittingAction: false,
        errorMessage: errorMessage ?? state.errorMessage,
      ),
    );
    return errorMessage == null;
  }

  Future<void> _resyncAfterAction(
    String rideId, {
    bool isQueuedAccept = false,
  }) async {
    final currentDriverId = driverId;
    if (currentDriverId == null) {
      state = withLiveStats(
        state.copyWith(
          status: DriverHomeStatus.error,
          isRefreshing: false,
          errorMessage: 'Impossible d\'identifier le chauffeur connecté.',
        ),
      );
      return;
    }

    state = withLiveStats(state.copyWith(isRefreshing: true));
    final result = await rideLoader.refresh(
      driverId: currentDriverId,
      activeRideId: rideId,
      driverLat: state.currentDriverLocation?.latitude,
      driverLng: state.currentDriverLocation?.longitude,
    );

    if (result.hasError) {
      state = withLiveStats(
        state.copyWith(
          status: state.hasActiveRide || state.hasAvailableRides
              ? DriverHomeStatus.ready
              : DriverHomeStatus.error,
          isRefreshing: false,
          errorMessage: result.errorMessage,
        ),
      );
      return;
    }

    final isTerminal =
        result.activeRide == null ||
        result.activeRide!.status == RideStatus.completed ||
        result.activeRide!.status == RideStatus.cancelled;

    // Acceptation en file d'attente : la nouvelle course va en queuedRide
    if (isQueuedAccept && !isTerminal) {
      state = withLiveStats(
        state.copyWith(
          status: DriverHomeStatus.ready,
          isRefreshing: false,
          queuedRide: result.activeRide,
          availableRides: const [],
          isPreArrivalOffersActive: false,
          errorMessage: null,
        ),
      );
      return;
    }

    if (isTerminal) {
      await _promoteQueuedRideOrLoadAvailable(currentDriverId);
      return;
    }

    state = withLiveStats(
      state.copyWith(
        status: DriverHomeStatus.ready,
        isRefreshing: false,
        activeRide: result.activeRide,
        availableRides: _filterIgnoredAvailableRides(result.availableRides),
        errorMessage: null,
      ),
    );
  }

  Future<void> _promoteQueuedRideOrLoadAvailable(int currentDriverId) async {
    final queued = state.queuedRide;
    if (queued != null) {
      state = withLiveStats(
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

    final availableResult = await _reloadAvailableRides(currentDriverId);
    if (availableResult.hasError) {
      state = withLiveStats(
        state.copyWith(
          status: state.hasActiveRide || state.hasAvailableRides
              ? DriverHomeStatus.ready
              : DriverHomeStatus.error,
          isRefreshing: false,
          errorMessage: availableResult.errorMessage,
        ),
      );
      return;
    }

    state = withLiveStats(
      state.copyWith(
        status: DriverHomeStatus.ready,
        isRefreshing: false,
        activeRide: null,
        availableRides: _filterIgnoredAvailableRides(
          availableResult.availableRides,
        ),
        errorMessage: null,
      ),
    );
  }

  Future<DriverHomeRideLoadResult> _reloadAvailableRides(int currentDriverId) {
    return rideLoader.refresh(
      driverId: currentDriverId,
      activeRideId: null,
      driverLat: state.currentDriverLocation?.latitude,
      driverLng: state.currentDriverLocation?.longitude,
    );
  }

  Future<bool> _rejectAction(String message) async {
    state = withLiveStats(state.copyWith(errorMessage: message));
    return false;
  }

  List<DriverRide> _filterIgnoredAvailableRides(List<DriverRide> rides) {
    if (rides.isEmpty || state.ignoredIncomingRideIds.isEmpty) {
      return rides;
    }

    final ignoredRideIds = state.ignoredIncomingRideIds.toSet();
    return rides
        .where((ride) => !ignoredRideIds.contains(ride.rideId))
        .toList(growable: false);
  }
}

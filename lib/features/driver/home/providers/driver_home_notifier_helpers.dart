part of 'driver_home_notifier.dart';

Future<void> _driverHomeLoadOnlineState(DriverHomeNotifier notifier) async {
  final currentDriverId = notifier.driverId;
  if (currentDriverId == null) {
    notifier._statsTracker.syncOnline(false);
    notifier._setState(
      notifier._currentState.copyWith(
        status: DriverHomeStatus.error,
        isOnline: false,
        canGoOnline: false,
        errorMessage: 'Impossible d\'identifier le chauffeur connecté.',
      ),
    );
    return;
  }

  notifier._setState(
    notifier._currentState.copyWith(isRefreshing: true, errorMessage: null),
  );
  final result = await notifier._rideLoader.loadInitial(
    currentDriverId,
    driverLat: notifier._currentState.currentDriverLocation?.latitude,
    driverLng: notifier._currentState.currentDriverLocation?.longitude,
  );
  _driverHomeApplyRideLoadResult(notifier, result);
}

void _driverHomeApplyRideLoadResult(
  DriverHomeNotifier notifier,
  DriverHomeRideLoadResult result,
) {
  if (result.hasError) {
    notifier._setRefreshError(result.errorMessage!);
    return;
  }

  final availableRides = notifier._filterIgnoredAvailableRides(
    result.availableRides,
  );
  final isPreArrival = result.activeRide != null && availableRides.isNotEmpty;

  notifier._setState(
    notifier._currentState.copyWith(
      status: DriverHomeStatus.ready,
      isRefreshing: false,
      activeRide: result.activeRide,
      availableRides: availableRides,
      isPreArrivalOffersActive: isPreArrival,
      errorMessage: null,
    ),
  );
}

void _driverHomeStartPolling(DriverHomeNotifier notifier) {
  notifier.stopPolling();
  if (!notifier._currentState.isOnline ||
      notifier._pollingPausedByIncomingRequest) {
    return;
  }
  notifier._pollingTimer = Timer.periodic(notifier._pollingInterval, (_) {
    unawaited(notifier.refreshHome());
  });
}

Future<bool> _driverHomeSyncBackendStatus(
  DriverHomeNotifier notifier,
  bool isOnline,
) async {
  if (notifier.userId == null) {
    notifier._setState(
      notifier._currentState.copyWith(
        status: DriverHomeStatus.error,
        errorMessage: 'Impossible d\'identifier le chauffeur connecté.',
      ),
    );
    return false;
  }

  final result = await notifier._updateDriverStatusUseCase(
    UpdateDriverStatusParams(isOnline: isOnline),
  );
  return result.fold(
    (failure) {
      notifier._setState(
        notifier._currentState.copyWith(
          status:
              notifier._currentState.hasActiveRide ||
                  notifier._currentState.hasAvailableRides
              ? DriverHomeStatus.ready
              : DriverHomeStatus.error,
          errorMessage: failure.message,
        ),
      );
      return false;
    },
    (_) {
      return true;
    },
  );
}

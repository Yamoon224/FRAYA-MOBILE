part of 'driver_home_notifier.dart';

extension DriverHomeNotifierLifecycle on DriverHomeNotifier {
  void seedTodayRides(List<DriverRide> rides) {
    for (final ride in rides) {
      if (ride.status == RideStatus.completed) {
        _statsTracker.recordCompletedRide(ride);
      }
    }
    _setState(_currentState);
  }

  void syncUserData(Map<String, dynamic>? userData) {
    final previousDriverId = driverId;
    _userData = userData == null ? null : Map<String, dynamic>.from(userData);
    if (_userData == null) {
      _clearSessionState();
      return;
    }

    final gate = DriverAdminStatusGate.fromUserData(_userData);
    if (!gate.canGoOnline) {
      _statsTracker.syncOnline(false);
      stopPolling();
    }
    _applyUserGate(gate);
    if (driverId != previousDriverId) {
      _applyIgnoredIncomingRideIds(const []);
    }
    unawaited(_restoreIgnoredIncomingRideIds());

    if (!_hasRestoredOnlineStatus) {
      _hasRestoredOnlineStatus = true;
      Future.microtask(restoreOnlineStatus);
    }
  }

  Future<void> setOnline(bool value) async {
    if (_userData == null) {
      _setState(
        _currentState.copyWith(
          status: DriverHomeStatus.error,
          isOnline: false,
          canGoOnline: false,
          errorMessage: 'Session chauffeur introuvable.',
        ),
      );
      return;
    }

    final gate = DriverAdminStatusGate.fromUserData(_userData);
    if (value && !gate.canGoOnline) {
      _blockOnlineFromGate(gate);
      return;
    }
    if (!value) {
      if (_currentState.activeRide != null) {
        _blockOfflineDuringActiveRide();
        return;
      }
      await _disableOnline();
      return;
    }
    await _enableOnline();
  }

  Future<void> restoreOnlineStatus() async {
    if (_userData == null || !_currentState.canGoOnline) return;
    final saved = _readSavedOnlineStatus();
    if (saved) await setOnline(true);
  }

  Future<void> handleAppClosing() async {
    if (_appClosingSyncInFlight) return;
    if (!_currentState.isOnline) {
      await _clearSavedOnlineStatus();
      return;
    }
    if (_currentState.activeRide != null) return;

    _appClosingSyncInFlight = true;
    await _rememberOnlineStatus();
    stopPolling();
    try {
      final disabled = await _driverHomeSyncBackendStatus(this, false);
      if (!disabled) return;
      _statsTracker.syncOnline(false);
      _setState(
        _currentState.copyWith(
          status: DriverHomeStatus.idle,
          isOnline: false,
          isRefreshing: false,
          errorMessage: null,
        ),
      );
    } finally {
      _appClosingSyncInFlight = false;
    }
  }

  void _clearSessionState() {
    _statsTracker.clear();
    _pollingPausedByIncomingRequest = false;
    _hasRestoredOnlineStatus = false;
    stopPolling();
    _setState(
      _currentState.copyWith(
        status: DriverHomeStatus.idle,
        isOnline: false,
        canGoOnline: false,
        errorMessage: null,
        availableRides: const [],
        ignoredIncomingRideIds: const [],
        activeRide: null,
        queuedRide: null,
        isPreArrivalOffersActive: false,
        currentDriverLocation: null,
      ),
    );
    _ignoredRideIdsDriverId = null;
  }

  void _applyUserGate(DriverAdminStatusResult gate) {
    final current = _currentState;
    _setState(
      current.copyWith(
        status: gate.canGoOnline
            ? (current.isOnline ? current.status : DriverHomeStatus.idle)
            : DriverHomeStatus.blocked,
        isOnline: gate.canGoOnline ? current.isOnline : false,
        canGoOnline: gate.canGoOnline,
        errorMessage: gate.canGoOnline ? null : gate.blockingMessage,
        driverRating: toDouble(_userData?['rating']),
        monthlyEarnings: toDouble(_userData?['monthlyEarnings']),
      ),
    );
  }

  void _blockOnlineFromGate(DriverAdminStatusResult gate) {
    _statsTracker.syncOnline(false);
    stopPolling();
    _setState(
      _currentState.copyWith(
        status: DriverHomeStatus.blocked,
        isOnline: false,
        canGoOnline: false,
        errorMessage:
            gate.blockingMessage ??
            'Une validation admin est requise avant de conduire.',
      ),
    );
  }

  void _blockOfflineDuringActiveRide() {
    _setState(
      _currentState.copyWith(
        errorMessage:
            'Vous ne pouvez pas passer hors ligne pendant une course en cours.',
      ),
    );
  }

  Future<void> _disableOnline() async {
    _pollingPausedByIncomingRequest = false;
    final disabled = await _driverHomeSyncBackendStatus(this, false);
    if (!disabled) return;
    _statsTracker.syncOnline(false);
    stopPolling();
    _setState(
      _currentState.copyWith(
        status: DriverHomeStatus.idle,
        isOnline: false,
        canGoOnline: true,
        isRefreshing: false,
        errorMessage: null,
      ),
    );
    await _clearSavedOnlineStatus();
  }

  Future<void> _enableOnline() async {
    final enabled = await _driverHomeSyncBackendStatus(this, true);
    if (!enabled) return;
    _statsTracker.syncOnline(true);
    _setState(
      _currentState.copyWith(
        status: DriverHomeStatus.loading,
        isOnline: true,
        canGoOnline: true,
        errorMessage: null,
      ),
    );
    await _rememberOnlineStatus();
    await _driverHomeLoadOnlineState(this);
    _driverHomeStartPolling(this);
  }

  bool _readSavedOnlineStatus() {
    final storage = LocalStorage.instance;
    if (!storage.isInitialized) return false;
    return storage.getBool(DriverHomeNotifier._onlineKey(userId)) ?? false;
  }

  Future<void> _rememberOnlineStatus() async {
    final storage = LocalStorage.instance;
    if (!storage.isInitialized) return;
    await storage.setBool(DriverHomeNotifier._onlineKey(userId), true);
  }

  Future<void> _clearSavedOnlineStatus() async {
    final storage = LocalStorage.instance;
    if (!storage.isInitialized) return;
    await storage.remove(DriverHomeNotifier._onlineKey(userId));
  }
}

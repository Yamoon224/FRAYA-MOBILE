import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;

import '../../../../core/config/app_config.dart';
import '../../../../core/utils/constants.dart';
import '../../../../data/sources/local_storage.dart';
import '../../../../domain/models/ride_status.dart';
import '../../../../domain/usecases/passenger/cancel_ride.dart';
import '../../../../domain/usecases/passenger/get_active_ride.dart';
import '../../../../shared/models/auth_state.dart';
import '../../auth/providers/passenger_auth_provider.dart';
import 'booking_dependencies.dart';
import 'booking_flow_utils.dart';
import 'passenger_booking_session_store.dart';

const kPendingSearchTimeout = Duration(minutes: 2);

final pendingSearchTimeoutProvider = Provider<Duration>(
  (_) => kPendingSearchTimeout,
);

final pendingSearchTimeoutEventProvider = StateProvider<int>((_) => 0);

final pendingSearchSessionStoreProvider = Provider<PendingSearchSessionStore>(
  (_) => PendingSearchSessionStore(LocalStorage.instance),
);

final pendingSearchCleanupControllerProvider =
    Provider<PendingSearchCleanupController>(
      (ref) => PendingSearchCleanupController(ref),
    );

final pendingSearchStartupCleanupProvider = FutureProvider<void>((ref) async {
  final auth = ref.read(passengerAuthProvider);
  final store = ref.read(pendingSearchSessionStoreProvider);
  final bookingStore = ref.read(passengerBookingSessionStoreProvider);
  final session = store.read();
  final legacyRideId = LocalStorage.instance.isInitialized
      ? LocalStorage.instance.getString(AppConstants.activeRideIdKey)
      : null;
  final rideId = session?.rideId ?? legacyRideId;
  if (rideId == null || rideId.trim().isEmpty) return;

  if (auth.status != AuthStatus.authenticated || auth.userData == null) {
    store.clear();
    bookingStore.clear();
    return;
  }

  final userId = BookingFlowUtils.parseUserId(auth.userData!);
  if (userId == null) return;

  final rideResult = await ref.read(getActiveRideUseCaseProvider)(
    GetActiveRideParams(userId: userId, rideId: rideId),
  );
  final ride = rideResult.fold((_) => null, (value) => value);
  if (ride == null ||
      ride.status == RideStatus.completed ||
      ride.status == RideStatus.cancelled) {
    store.clear();
    bookingStore.clear();
    if (legacyRideId == rideId) {
      await LocalStorage.instance.remove(AppConstants.activeRideIdKey);
    }
    return;
  }

  if (ride.status == RideStatus.pending) {
    final timeout = ref.read(pendingSearchTimeoutProvider);
    final expired =
        session == null ||
        DateTime.now().difference(session.startedAt) >= timeout;
    if (!expired) return;

    final result = await ref.read(cancelRideUseCaseProvider)(
      CancelRideParams(rideId: rideId, reason: 'Nettoyage au lancement'),
    );
    if (result.isRight()) {
      await store.clear();
      await bookingStore.clear();
      if (legacyRideId == rideId) {
        await LocalStorage.instance.remove(AppConstants.activeRideIdKey);
      }
    }
    return;
  }

  store.clear();
});

final passengerPendingSearchLifecycleProvider =
    Provider<PassengerPendingSearchLifecycleCoordinator>((ref) {
      final coordinator = PassengerPendingSearchLifecycleCoordinator(ref);
      ref.onDispose(coordinator.dispose);
      return coordinator;
    });

class PendingSearchSession {
  const PendingSearchSession({required this.rideId, required this.startedAt});

  final String rideId;
  final DateTime startedAt;
}

class PendingSearchSessionStore {
  const PendingSearchSessionStore(this._storage);

  final LocalStorage _storage;

  PendingSearchSession? read() {
    if (!_storage.isInitialized) return null;
    final rideId = _storage.getString(AppConstants.pendingSearchRideIdKey);
    final startedAtMs = _storage.getInt(AppConstants.pendingSearchStartedAtKey);
    if (rideId == null || rideId.trim().isEmpty || startedAtMs == null) {
      return null;
    }
    return PendingSearchSession(
      rideId: rideId,
      startedAt: DateTime.fromMillisecondsSinceEpoch(startedAtMs),
    );
  }

  Future<void> save(String rideId, {DateTime? startedAt}) async {
    if (!_storage.isInitialized || rideId.trim().isEmpty) return;
    await _storage.setString(AppConstants.pendingSearchRideIdKey, rideId);
    await _storage.setInt(
      AppConstants.pendingSearchStartedAtKey,
      (startedAt ?? DateTime.now()).millisecondsSinceEpoch,
    );
  }

  Future<void> clear() async {
    if (!_storage.isInitialized) return;
    await _storage.remove(AppConstants.pendingSearchRideIdKey);
    await _storage.remove(AppConstants.pendingSearchStartedAtKey);
  }
}

class PendingSearchCleanupController {
  PendingSearchCleanupController(this._ref);

  final Ref _ref;
  String? _lifecycleCancelInFlightForRideId;

  Future<bool> cancelPendingSearch({
    required String reason,
    bool clearOnFailure = true,
  }) async {
    final store = _ref.read(pendingSearchSessionStoreProvider);
    final session = store.read();
    if (session == null) return true;

    final result = await _ref.read(cancelRideUseCaseProvider)(
      CancelRideParams(rideId: session.rideId, reason: reason),
    );
    final success = result.fold((_) => false, (_) => true);
    if (success || clearOnFailure) {
      await store.clear();
    }
    return success;
  }

  Future<void> cancelPendingSearchBeforeLogout() async {
    await cancelPendingSearch(
      reason: 'Déconnexion passager',
      clearOnFailure: true,
    );
  }

  Future<void> cancelPendingSearchForLifecycle() async {
    final session = _ref.read(pendingSearchSessionStoreProvider).read();
    if (session == null) return;
    if (_lifecycleCancelInFlightForRideId == session.rideId) return;
    _lifecycleCancelInFlightForRideId = session.rideId;
    await cancelPendingSearch(
      reason: 'Application fermee',
      clearOnFailure: false,
    );
  }
}

class PassengerPendingSearchLifecycleCoordinator with WidgetsBindingObserver {
  PassengerPendingSearchLifecycleCoordinator(this._ref) {
    if (!AppConfig.instance.isPassenger) return;
    WidgetsBinding.instance.addObserver(this);
  }

  final Ref _ref;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.detached) {
      return;
    }
    unawaited(
      _ref
          .read(pendingSearchCleanupControllerProvider)
          .cancelPendingSearchForLifecycle(),
    );
  }

  void dispose() {
    if (!AppConfig.instance.isPassenger) return;
    WidgetsBinding.instance.removeObserver(this);
  }
}

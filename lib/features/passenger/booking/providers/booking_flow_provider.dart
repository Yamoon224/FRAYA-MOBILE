import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/constants.dart';
import '../../../../data/sources/local_storage.dart';
import '../../../../domain/models/active_ride.dart';
import '../../../../domain/models/ride_status.dart';
import '../../../../domain/repositories/booking_repository.dart';
import '../../../../domain/usecases/passenger/cancel_ride.dart';
import '../../../../domain/usecases/passenger/get_active_ride.dart';
import '../../../../shared/models/auth_state.dart';
import '../../../../shared/providers/location_provider.dart';
import '../../../../shared/providers/places_provider.dart';
import '../../../../shared/providers/realtime_providers.dart';
import '../../auth/providers/passenger_auth_provider.dart';
import '../models/booking_flow_state.dart';
import 'active_ride_check_provider.dart';
import 'active_ride_location_merge.dart';
import 'active_ride_provider.dart';
import 'booking_dependencies.dart'
    show
        bookingActiveRideCancelledHomeEventProvider,
        bookingErrorProvider,
        bookingRemoteRideCancelledEventProvider,
        bookingRetryCountProvider,
        cancelRideUseCaseProvider,
        getActiveRideUseCaseProvider,
        passengerBookingRepositoryProvider,
        requestRideUseCaseProvider;
import 'booking_polling_mixin.dart';
import 'booking_route_refresh_provider.dart';
import 'booking_status_mapper.dart';
import 'booking_flow_utils.dart';
import 'payment_method_provider.dart';
import 'passenger_booking_session_store.dart';
import 'pending_search_session_provider.dart';
import 'ride_categories_provider.dart';
import 'route_directions_provider.dart';
export '../models/booking_flow_state.dart';
part 'booking_flow_provider.g.dart';

@riverpod
BookingRepository bookingRepository(Ref ref) =>
    ref.watch(passengerBookingRepositoryProvider);

@riverpod
class BookingFlow extends _$BookingFlow with BookingPollingMixin {
  int? _currentUserId;
  String? _activeRideId;
  int _retryCount = 0;
  bool _isRequestSubmitting = false;
  bool _isCancelSubmitting = false;
  Timer? _pendingSearchTimer;
  @override
  BookingFlowState build() {
    ref.keepAlive();
    ref.onDispose(() {
      stopPolling();
      _stopPendingSearchTimer();
    });

    ref.listen(activeRideCheckProvider, (_, next) {
      final ride = next.asData?.value;
      if (ride != null && state == BookingFlowState.idle) {
        restoreFromActiveRide(ride);
      }
    });

    ref.listen<AuthState>(passengerAuthProvider, (previous, next) {
      if (previous?.status == AuthStatus.authenticated &&
          next.status != AuthStatus.authenticated) {
        Future.microtask(reset);
      }
    });

    // Si BookingFlow est initialisé tardivement (après que le router a déjà
    // redirigé), activeRideCheckProvider a déjà résolu et ref.listen ne fire
    // pas pour la valeur courante. On lit donc la valeur présente explicitement.
    final existing = ref.read(activeRideCheckProvider).asData?.value;
    if (existing != null) {
      Future.microtask(() {
        if (state == BookingFlowState.idle) restoreFromActiveRide(existing);
      });
    }

    return BookingFlowState.idle;
  }

  void goToRoutePreview() => state = BookingFlowState.routePreview;
  Future<void> startSearching() async {
    if (_isRequestSubmitting) return;
    _isRequestSubmitting = true;
    state = BookingFlowState.searching;
    try {
      final destination = ref.read(selectedDestinationProvider);
      final manualPickup = ref.read(selectedPickupProvider);
      final currentAddress = ref.read(formattedAddressProvider);
      final currentLocation = ref.read(currentLocationProvider).asData?.value;
      final originSnapshot = ref.read(bookingOriginSnapshotProvider);
      final category = ref.read(selectedCategoryProvider);
      final paymentMethod = ref.read(selectedPaymentMethodProvider);
      final authState = ref.read(passengerAuthProvider);
      final directions = ref.read(routeDirectionsProvider).asData?.value;
      final route = directions == null || directions.routes.isEmpty
          ? null
          : directions.mainRoute;
      final pickupLat =
          manualPickup?.latitude ??
          originSnapshot?.latitude ??
          currentLocation?.latitude;
      final pickupLng =
          manualPickup?.longitude ??
          originSnapshot?.longitude ??
          currentLocation?.longitude;
      if (destination == null ||
          pickupLat == null ||
          pickupLng == null ||
          category == null ||
          authState.userData == null) {
        state = BookingFlowState.routePreview;
        return;
      }
      _currentUserId = BookingFlowUtils.parseUserId(authState.userData!);
      if (_currentUserId == null) throw StateError('User ID introuvable');
      final result = await ref.read(requestRideUseCaseProvider)(
        BookingFlowUtils.buildRideRequestParams(
          userId: _currentUserId!,
          destination: destination,
          pickupLat: pickupLat,
          pickupLng: pickupLng,
          category: category,
          manualPickupName: manualPickup?.address ?? manualPickup?.name,
          currentAddress: currentAddress,
          paymentMethod: paymentMethod,
          activeRoute: route,
        ),
      );
      await _handleRideResponse(result);
    } catch (error) {
      _handleRideRequestError(error);
    } finally {
      _isRequestSubmitting = false;
    }
  }

  Future<void> retrySearching() async {
    ref.read(bookingRetryCountProvider.notifier).state = ++_retryCount;
    await startSearching();
  }

  Future<void> cancelExistingAndRetry() async {
    if (_isCancelSubmitting || _currentUserId == null) return;
    _isCancelSubmitting = true;
    state = BookingFlowState.searching;
    try {
      final rideResult = await ref.read(getActiveRideUseCaseProvider)(
        GetActiveRideParams(userId: _currentUserId!),
      );
      final activeRide = rideResult.fold((_) => null, (ride) => ride);
      if (_cannotCancelRide(activeRide)) {
        ref.read(bookingErrorProvider.notifier).state =
            'La course ne peut plus être annulée car le chauffeur est déjà arrivé.';
        state = BookingFlowState.activeRideConflict;
        return;
      }
      final rideId = activeRide?.rideId;
      if (rideId != null) {
        final cancelResult = await ref.read(cancelRideUseCaseProvider)(
          CancelRideParams(rideId: rideId, reason: 'Nouvelle demande'),
        );
        if (!_resolveCancelResult(cancelResult)) {
          state = BookingFlowState.activeRideConflict;
          return;
        }
      }
    } finally {
      _isCancelSubmitting = false;
    }
    await startSearching();
  }

  Future<void> cancelSearching({String? reason}) async {
    if (_isCancelSubmitting) return;
    _isCancelSubmitting = true;
    try {
      final activeRide = ref.read(activeRideControllerProvider);
      final shouldReturnHomeAfterCancel = _isActiveRideCancellation(activeRide);
      if (_cannotCancelRide(activeRide) || _cannotCancelFlowState(state)) {
        ref.read(bookingErrorProvider.notifier).state =
            'La course ne peut plus être annulée car le chauffeur est déjà arrivé.';
        return;
      }
      stopPolling();
      _stopPendingSearchTimer();
      final rideId = activeRide?.rideId ?? _activeRideId;
      if (rideId != null && rideId.isNotEmpty) {
        final cancelResult = await ref.read(cancelRideUseCaseProvider)(
          CancelRideParams(rideId: rideId, reason: reason),
        );
        if (!_resolveCancelResult(cancelResult, resumePollingOnFailure: true)) {
          return;
        }
      }
      _clearPendingSearchSession();
      _clearActiveRideId();
      _clearPassengerBookingSession();
      ref.read(activeRideControllerProvider.notifier).clear();
      ref.read(completedRideControllerProvider.notifier).clear();
      state = BookingFlowState.routePreview;
      if (shouldReturnHomeAfterCancel) {
        state = BookingFlowState.idle;
        _emitActiveRideCancelledHomeEvent();
      }
    } finally {
      _isCancelSubmitting = false;
    }
  }

  Future<void> _handleRideResponse(Either<Failure, String> result) async {
    final failure = result.fold((value) => value, (_) => null);
    if (failure is ActiveRideConflictFailure) {
      state = BookingFlowState.activeRideConflict;
      return;
    }
    if (failure != null) throw StateError(failure.message);
    _activeRideId = result.fold((_) => '', (rideId) => rideId);
    if (_activeRideId != null && _activeRideId!.isNotEmpty) {
      _savePassengerBookingSession(_activeRideId!);
      _clearRideSearchFields();
      _ensurePendingSearchSession(_activeRideId!);
    }
    await _refreshRideStatus();
    _startPolling();
  }

  void _handleRideRequestError(Object error) {
    log.error('Erreur requestRide: $error');
    ref.read(bookingErrorProvider.notifier).state =
        BookingFlowUtils.toUserMessage(error);
    if (_retryCount < 3) {
      state = BookingFlowState.searchFailed;
      return;
    }
    _retryCount = 0;
    ref.read(bookingRetryCountProvider.notifier).state = 0;
    state = BookingFlowState.routePreview;
  }

  bool _resolveCancelResult(
    Either<Failure, bool> result, {
    bool resumePollingOnFailure = false,
  }) {
    return result.fold((failure) {
      log.error('Erreur cancelRide: ${failure.message}');
      ref.read(bookingErrorProvider.notifier).state = failure.message;
      if (resumePollingOnFailure) _startPolling();
      return false;
    }, (_) => true);
  }

  bool _cannotCancelRide(ActiveRide? ride) {
    return ride?.status == RideStatus.arrived ||
        ride?.status == RideStatus.inProgress ||
        ride?.status == RideStatus.completed;
  }

  bool _cannotCancelFlowState(BookingFlowState flowState) {
    return flowState == BookingFlowState.arrived ||
        flowState == BookingFlowState.inProgress ||
        flowState == BookingFlowState.completed;
  }

  bool _isActiveRideCancellation(ActiveRide? ride) {
    return _isActiveRideStatus(ride?.status) || _isActiveRideFlowState(state);
  }

  bool _isActiveRideFlowState(BookingFlowState flowState) {
    return flowState == BookingFlowState.driverAssigned ||
        flowState == BookingFlowState.arrived ||
        flowState == BookingFlowState.inProgress;
  }

  bool _isActiveRideStatus(RideStatus? status) {
    return status == RideStatus.accepted ||
        status == RideStatus.arrived ||
        status == RideStatus.inProgress;
  }

  void _emitActiveRideCancelledHomeEvent() {
    ref.read(bookingActiveRideCancelledHomeEventProvider.notifier).state++;
  }

  void _emitRemoteRideCancelledEvent() {
    ref.read(bookingRemoteRideCancelledEventProvider.notifier).state++;
  }

  Future<void> _refreshRideStatus() async {
    if (isRefreshing || _currentUserId == null) return;
    isRefreshing = true;
    try {
      final rideResult = await ref.read(getActiveRideUseCaseProvider)(
        GetActiveRideParams(userId: _currentUserId!, rideId: _activeRideId),
      );
      final ride = rideResult.fold(
        (f) => throw StateError(f.message),
        (r) => r,
      );
      if (ride != null) {
        _applyBackendStatus(ride);
      } else if (_activeRideId != null) {
        final shouldReturnHome = _isActiveRideFlowState(state);
        // Plus de course active côté serveur → terminée ou annulée
        _activeRideId = null;
        _clearActiveRideId();
        _clearPendingSearchSession();
        _clearPassengerBookingSession();
        _stopPendingSearchTimer();
        stopPolling();
        ref.read(activeRideControllerProvider.notifier).clear();
        ref.invalidate(activeRideCheckProvider);
        state = BookingFlowState.completed;
        if (shouldReturnHome) {
          state = BookingFlowState.idle;
          _emitRemoteRideCancelledEvent();
        }
      }
    } catch (error) {
      log.error('Erreur refreshStatus: $error');
    } finally {
      isRefreshing = false;
    }
  }

  void restoreFromActiveRide(ActiveRide ride) {
    if (ride.rideId.isEmpty) return;
    _activeRideId = ride.rideId;
    _currentUserId = BookingFlowUtils.parseUserId(
      ref.read(passengerAuthProvider).userData!,
    );
    _applyBackendStatus(ride);
    _clearRideSearchFields();
    _startPolling();
    Future.microtask(hardRefreshStatus);
  }

  void _applyBackendStatus(ActiveRide backendRide) {
    final ride = _mergeWithRealtimeLocation(backendRide);
    final shouldReturnHomeForCancellation =
        ride.status == RideStatus.cancelled &&
        (_isActiveRideFlowState(state) ||
            _isActiveRideStatus(
              ref.read(activeRideControllerProvider)?.status,
            ));

    if (ride.rideId.isNotEmpty) {
      if (ride.status == RideStatus.completed) {
        ref.read(completedRideControllerProvider.notifier).initialize(ride);
        ref.read(activeRideControllerProvider.notifier).clear();
      } else if (ride.status == RideStatus.cancelled) {
        ref.read(activeRideControllerProvider.notifier).clear();
        ref.read(completedRideControllerProvider.notifier).clear();
      } else {
        ref.read(activeRideControllerProvider.notifier).initialize(ride);
        ref.read(completedRideControllerProvider.notifier).clear();
      }
      _activeRideId = ride.rideId;
    }
    state = BookingStatusMapper.mapBackendStatus(ride.status);
    if (ride.status == RideStatus.pending) {
      _clearActiveRideId();
      _ensurePendingSearchSession(ride.rideId);
      _startPendingSearchTimer();
      return;
    }
    if (ride.status == RideStatus.accepted ||
        ride.status == RideStatus.arrived ||
        ride.status == RideStatus.inProgress) {
      _stopPendingSearchTimer();
      _clearPendingSearchSession();
      _saveActiveRideId(ride.rideId);
    }
    if (ride.status == RideStatus.completed ||
        ride.status == RideStatus.cancelled) {
      _activeRideId = null;
      _clearActiveRideId();
      _clearPendingSearchSession();
      _clearPassengerBookingSession();
      _stopPendingSearchTimer();
      stopPolling();
      ref.invalidate(activeRideCheckProvider);
      if (ride.status == RideStatus.cancelled) {
        ref.read(activeRideControllerProvider.notifier).clear();
        if (shouldReturnHomeForCancellation) {
          state = BookingFlowState.idle;
          _emitRemoteRideCancelledEvent();
        }
      }
    }
  }

  ActiveRide _mergeWithRealtimeLocation(ActiveRide backendRide) {
    return mergeBackendRideWithRealtimeLocation(
      backendRide: backendRide,
      currentRide: ref.read(activeRideControllerProvider),
      socketHealth: ref.read(realtimeHealthStateProvider),
    );
  }

  void _saveActiveRideId(String rideId) => LocalStorage.instance.isInitialized
      ? LocalStorage.instance.setString(AppConstants.activeRideIdKey, rideId)
      : Future<bool>.value(false);

  void _clearActiveRideId() {
    if (!LocalStorage.instance.isInitialized) return;
    LocalStorage.instance.remove(AppConstants.activeRideIdKey);
  }

  void _ensurePendingSearchSession(String rideId) {
    if (rideId.trim().isEmpty) return;
    final store = ref.read(pendingSearchSessionStoreProvider);
    final current = store.read();
    if (current?.rideId == rideId) return;
    store.save(rideId);
  }

  void _clearPendingSearchSession() {
    ref.read(pendingSearchSessionStoreProvider).clear();
  }

  void _savePassengerBookingSession(String rideId) {
    ref
        .read(passengerBookingSessionStoreProvider)
        .save(
          PassengerBookingSession(
            pickup: ref.read(selectedPickupProvider),
            destination: ref.read(selectedDestinationProvider),
            createdAt: DateTime.now(),
            rideId: rideId,
            categoryId: ref.read(selectedCategoryProvider)?.id,
            paymentMethod: ref.read(selectedPaymentMethodProvider),
            routeIndex: 0,
          ),
        );
  }

  void _clearPassengerBookingSession() {
    ref.read(passengerBookingSessionStoreProvider).clear();
  }

  void _clearRideSearchFields() {
    ref.read(selectedDestinationProvider.notifier).clear();
    ref.read(selectedPickupProvider.notifier).clear();
    ref.read(allowBaseCategoriesForUnpricedDestinationProvider.notifier).state =
        false;
  }

  void _startPendingSearchTimer() {
    _pendingSearchTimer?.cancel();
    final session = ref.read(pendingSearchSessionStoreProvider).read();
    if (session == null) return;
    final timeout = ref.read(pendingSearchTimeoutProvider);
    final elapsed = DateTime.now().difference(session.startedAt);
    final remaining = timeout - elapsed;
    if (remaining <= Duration.zero) {
      unawaited(_expirePendingSearch());
      return;
    }
    _pendingSearchTimer = Timer(remaining, () {
      unawaited(_expirePendingSearch());
    });
  }

  void _stopPendingSearchTimer() {
    _pendingSearchTimer?.cancel();
    _pendingSearchTimer = null;
  }

  Future<void> _expirePendingSearch() async {
    if (_isCancelSubmitting || state != BookingFlowState.searching) return;
    final session = ref.read(pendingSearchSessionStoreProvider).read();
    final rideId = session?.rideId ?? _activeRideId;
    if (rideId == null || rideId.isEmpty) return;
    _isCancelSubmitting = true;
    stopPolling();
    try {
      final latest = await _loadActiveRide(rideId);
      if (latest != null && latest.status != RideStatus.pending) {
        _applyBackendStatus(latest);
        return;
      }
      if (latest == null) {
        _finishExpiredPendingSearch();
        return;
      }
      final cancelResult = await ref.read(cancelRideUseCaseProvider)(
        CancelRideParams(rideId: rideId, reason: 'Recherche expiree'),
      );
      final cancelled = cancelResult.fold((_) => false, (_) => true);
      if (!cancelled) {
        await _refreshRideStatus();
        if (state == BookingFlowState.searching) _startPolling();
        return;
      }
      _finishExpiredPendingSearch();
    } finally {
      _isCancelSubmitting = false;
    }
  }

  Future<ActiveRide?> _loadActiveRide(String rideId) async {
    final userId = _currentUserId;
    if (userId == null) return null;
    final result = await ref.read(getActiveRideUseCaseProvider)(
      GetActiveRideParams(userId: userId, rideId: rideId),
    );
    return result.fold((_) => null, (ride) => ride);
  }

  void _finishExpiredPendingSearch() {
    _stopPendingSearchTimer();
    _clearPendingSearchSession();
    _clearActiveRideId();
    _clearPassengerBookingSession();
    ref.read(activeRideControllerProvider.notifier).clear();
    ref.read(completedRideControllerProvider.notifier).clear();
    _activeRideId = null;
    state = BookingFlowState.routePreview;
    ref.read(pendingSearchTimeoutEventProvider.notifier).state++;
  }

  void resetToIdle() {
    stopPolling();
    _stopPendingSearchTimer();
    _clearActiveRideId();
    _clearPendingSearchSession();
    _clearPassengerBookingSession();
    _activeRideId = null;
    _retryCount = 0;
    _isRequestSubmitting = false;
    _isCancelSubmitting = false;
    ref.read(bookingRetryCountProvider.notifier).state = 0;
    ref.read(activeRideControllerProvider.notifier).clear();
    ref.read(completedRideControllerProvider.notifier).clear();
    ref.read(bookingErrorProvider.notifier).state = null;
    ref.read(categoryAutoSelectionEnabledProvider.notifier).state = true;
    ref.read(allowBaseCategoriesForUnpricedDestinationProvider.notifier).state =
        false;
    ref.invalidate(selectedCategoryProvider);
    ref.read(selectedPaymentMethodProvider.notifier).state = PaymentMethod.cash;
    state = BookingFlowState.idle;
  }

  void prepareRoutePreviewForReorder() {
    stopPolling();
    _stopPendingSearchTimer();
    _clearActiveRideId();
    _clearPendingSearchSession();
    _clearPassengerBookingSession();
    _activeRideId = null;
    _retryCount = 0;
    _isRequestSubmitting = false;
    _isCancelSubmitting = false;
    ref.read(bookingRetryCountProvider.notifier).state = 0;
    ref.read(activeRideControllerProvider.notifier).clear();
    ref.read(completedRideControllerProvider.notifier).clear();
    ref.read(bookingErrorProvider.notifier).state = null;
    ref.read(selectedCategoryProvider.notifier).requireManualSelection();
    state = BookingFlowState.routePreview;
  }

  void reset() {
    stopPolling();
    _stopPendingSearchTimer();
    _clearActiveRideId();
    _clearPendingSearchSession();
    _clearPassengerBookingSession();
    _currentUserId = null;
    _activeRideId = null;
    _retryCount = 0;
    _isRequestSubmitting = false;
    _isCancelSubmitting = false;
    ref.read(bookingRetryCountProvider.notifier).state = 0;
    ref.read(selectedDestinationProvider.notifier).clear();
    ref.read(selectedPickupProvider.notifier).clear();
    ref.read(categoryAutoSelectionEnabledProvider.notifier).state = true;
    ref.read(allowBaseCategoriesForUnpricedDestinationProvider.notifier).state =
        false;
    ref.read(selectedCategoryProvider.notifier).clear();
    ref.read(selectedPaymentMethodProvider.notifier).state = PaymentMethod.cash;
    ref.read(activeRideControllerProvider.notifier).clear();
    ref.read(completedRideControllerProvider.notifier).clear();
    ref.invalidate(activeRideCheckProvider);
    ref.read(bookingOriginSnapshotProvider.notifier).state = null;
    ref.read(bookingManualRefreshTriggerProvider.notifier).state = 0;
    state = BookingFlowState.idle;
  }

  void _startPolling() => startPolling(_refreshRideStatus);

  Future<void> hardRefreshStatus() => _refreshRideStatus();

  Future<void> handleRideAcceptedRealtime(String? rideId) async {
    if (_currentUserId == null) {
      final authData = ref.read(passengerAuthProvider).userData;
      if (authData != null) {
        _currentUserId = BookingFlowUtils.parseUserId(authData);
      }
    }
    if (_currentUserId == null) return;

    if (rideId != null && rideId.trim().isNotEmpty) {
      _activeRideId = rideId;
    }
    await _refreshRideStatus();
  }
}

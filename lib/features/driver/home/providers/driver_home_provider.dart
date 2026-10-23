library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncValueExtensions;
import 'package:flutter_riverpod/legacy.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../shared/providers/location_provider.dart';
import '../../auth/providers/driver_auth_provider.dart';
import '../../history/providers/driver_history_provider.dart';
import '../../wallet/providers/driver_wallet_provider.dart';
import 'driver_home_location_sync_policy.dart';
import 'driver_home_notifier.dart';
import 'driver_home_state.dart';
import 'driver_ride_dependencies.dart';
import 'driver_status_dependencies.dart';

final driverHomeProvider = StateNotifierProvider<DriverHomeNotifier, DriverHomeState>((
  ref,
) {
  final notifier = DriverHomeNotifier(
    acceptRideUseCase: ref.watch(acceptDriverRideUseCaseProvider),
    markArrivedUseCase: ref.watch(markDriverRideArrivedUseCaseProvider),
    startRideUseCase: ref.watch(startDriverRideUseCaseProvider),
    completeRideUseCase: ref.watch(completeDriverRideUseCaseProvider),
    cancelRideUseCase: ref.watch(cancelDriverRideUseCaseProvider),
    fetchAvailableRidesUseCase: ref.watch(
      fetchAvailableDriverRidesUseCaseProvider,
    ),
    getActiveRideUseCase: ref.watch(getDriverActiveRideUseCaseProvider),
    updateDriverStatusUseCase: ref.watch(updateDriverStatusUseCaseProvider),
  );
  LatLng? lastSentActiveRideLocation;
  DateTime? lastSentActiveRideLocationAt;
  LatLng? lastSentAvailabilityLocation;
  DateTime? lastSentAvailabilityLocationAt;
  notifier.syncUserData(ref.read(driverAuthProvider).userData);
  notifier.onRideCompleted = () {
    ref.invalidate(driverHistoryRidesProvider);
    unawaited(ref.read(driverWalletProvider.notifier).loadWallet());
  };
  ref.listen(todayDriverHistoryRidesProvider, (_, rides) {
    notifier.seedTodayRides(rides);
  });
  ref.listen(driverAuthProvider, (previous, next) {
    notifier.syncUserData(next.userData);
  });
  // Envoie la position au serveur si la règle de synchronisation l'autorise. Appelée à chaque nouvelle
  // position du GPS, mais aussi au passage en ligne et à intervalle régulier : un chauffeur à l'arrêt
  // ne reçoit aucune nouvelle position du GPS, et sans cet envoi le serveur ne saurait jamais où il est
  // (il resterait invisible pour les passagers alors qu'il est en ligne).
  void sendLocationIfDue(LatLng? location) {
    final activeRide = notifier.activeRide;
    final driverId = notifier.driverId;
    if (location == null) {
      lastSentActiveRideLocation = null;
      lastSentActiveRideLocationAt = null;
      lastSentAvailabilityLocation = null;
      lastSentAvailabilityLocationAt = null;
      return;
    }

    if (activeRide != null) {
      lastSentAvailabilityLocation = null;
      lastSentAvailabilityLocationAt = null;
      if (driverId == null) return;
      if (DriverHomeLocationSyncPolicy.shouldSend(
        previousLocation: lastSentActiveRideLocation,
        lastSentAt: lastSentActiveRideLocationAt,
        nextLocation: location,
      )) {
        lastSentActiveRideLocation = location;
        lastSentActiveRideLocationAt = DateTime.now();
        unawaited(
          ref
              .read(sendDriverLocationUseCaseProvider)
              .call(
                rideId: activeRide.rideId,
                driverId: driverId,
                lat: location.latitude,
                lng: location.longitude,
              ),
        );
      }
      return;
    }

    lastSentActiveRideLocation = null;
    lastSentActiveRideLocationAt = null;
    if (!notifier.isOnline) {
      lastSentAvailabilityLocation = null;
      lastSentAvailabilityLocationAt = null;
      return;
    }

    if (DriverHomeLocationSyncPolicy.shouldSend(
      previousLocation: lastSentAvailabilityLocation,
      lastSentAt: lastSentAvailabilityLocationAt,
      nextLocation: location,
    )) {
      lastSentAvailabilityLocation = location;
      lastSentAvailabilityLocationAt = DateTime.now();
      unawaited(
        ref
            .read(sendDriverAvailabilityLocationUseCaseProvider)
            .call(lat: location.latitude, lng: location.longitude),
      );
    }
  }

  ref.listen(currentLocationProvider, (previous, next) {
    final pos = next.asData?.value;
    final location = pos == null ? null : LatLng(pos.latitude, pos.longitude);
    notifier.syncRealtimeLocation(location, heading: pos?.heading);
    notifier.evaluateArrivalDetection();
    sendLocationIfDue(location);
  });

  // Rappel périodique tant que le chauffeur est en ligne ou en course ; arrêté dès qu'il se met hors ligne.
  Timer? locationKeepAlive;
  void stopKeepAlive() {
    locationKeepAlive?.cancel();
    locationKeepAlive = null;
  }

  void startKeepAlive() {
    locationKeepAlive ??= Timer.periodic(
      DriverHomeLocationSyncPolicy.minSendInterval,
      (_) => sendLocationIfDue(notifier.currentLocation),
    );
  }

  var wasTracking = false;
  final removeTrackingListener = notifier.addListener((state) {
    final isTracking = state.isOnline || state.activeRide != null;
    if (isTracking && !wasTracking) {
      startKeepAlive();
      sendLocationIfDue(state.currentDriverLocation);
    } else if (!isTracking && wasTracking) {
      stopKeepAlive();
    }
    wasTracking = isTracking;
  }, fireImmediately: false);
  ref.onDispose(() {
    stopKeepAlive();
    removeTrackingListener();
  });
  return notifier;
});

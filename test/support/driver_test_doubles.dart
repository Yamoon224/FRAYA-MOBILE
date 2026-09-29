import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/domain/models/driver_ride.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';
import 'package:fraya_mobile/domain/repositories/driver_auth_repository.dart';
import 'package:fraya_mobile/domain/repositories/driver_ride_repository.dart';
import 'package:fraya_mobile/domain/usecases/driver/auth/login_driver_usecase.dart';
import 'package:fraya_mobile/domain/usecases/driver/auth/logout_driver_usecase.dart';
import 'package:fraya_mobile/domain/usecases/driver/auth/refresh_driver_profile_usecase.dart';
import 'package:fraya_mobile/domain/usecases/driver/auth/register_driver_step1_usecase.dart';
import 'package:fraya_mobile/domain/usecases/driver/auth/register_driver_step2_usecase.dart';
import 'package:fraya_mobile/domain/usecases/driver/auth/register_driver_usecase.dart';
import 'package:fraya_mobile/domain/usecases/driver/rides/accept_driver_ride.dart';
import 'package:fraya_mobile/domain/usecases/driver/rides/cancel_driver_ride.dart';
import 'package:fraya_mobile/domain/usecases/driver/rides/complete_driver_ride.dart';
import 'package:fraya_mobile/domain/usecases/driver/rides/fetch_available_driver_rides.dart';
import 'package:fraya_mobile/domain/usecases/driver/rides/get_driver_active_ride.dart';
import 'package:fraya_mobile/domain/usecases/driver/rides/mark_driver_ride_arrived.dart';
import 'package:fraya_mobile/domain/usecases/driver/rides/start_driver_ride.dart';
import 'package:fraya_mobile/domain/usecases/driver/status/update_driver_status.dart';
import 'package:fraya_mobile/domain/repositories/driver_status_repository.dart';
import 'package:fraya_mobile/features/driver/auth/providers/driver_auth_provider.dart';
import 'package:fraya_mobile/features/driver/home/providers/driver_home_notifier.dart';
import 'package:fraya_mobile/features/driver/home/providers/driver_home_state.dart';
import 'package:fraya_mobile/shared/models/auth_state.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FakeDriverAuthRepository implements DriverAuthRepository {
  @override
  Future<Map<String, dynamic>> fetchProfile() async => const {};

  @override
  Future<Map<String, dynamic>> login(
    String phoneNumber,
    String password,
  ) async {
    fail('Unexpected driver auth login call in test.');
  }

  @override
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    fail('Unexpected driver auth register call in test.');
  }

  @override
  Future<void> registerStep1(String phoneNumber, {String? email}) async {
    fail('Unexpected driver auth registerStep1 call in test.');
  }

  @override
  Future<void> registerStep2(
    String phoneNumber,
    String verificationCode,
  ) async {
    fail('Unexpected driver auth registerStep2 call in test.');
  }
}

class FakeDriverAuthNotifier extends DriverAuthNotifier {
  FakeDriverAuthNotifier(AuthState initialState)
    : super(
        loginUseCase: LoginDriverUseCase(FakeDriverAuthRepository()),
        registerUseCase: RegisterDriverUseCase(FakeDriverAuthRepository()),
        registerStep1UseCase: RegisterDriverStep1UseCase(
          FakeDriverAuthRepository(),
        ),
        registerStep2UseCase: RegisterDriverStep2UseCase(
          FakeDriverAuthRepository(),
        ),
        logoutUseCase: LogoutDriverUseCase(),
        refreshProfileUseCase: RefreshDriverProfileUseCase(
          FakeDriverAuthRepository(),
        ),
        autoRestore: false,
      ) {
    state = initialState;
  }

  int logoutCalls = 0;
  int refreshProfileCalls = 0;

  @override
  Future<void> refreshProfile() async {
    refreshProfileCalls++;
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    await super.logout();
  }

  void setTestState(AuthState nextState) {
    state = nextState;
  }
}

class FakeDriverHomeNotifier extends DriverHomeNotifier {
  FakeDriverHomeNotifier(this.repository, DriverHomeState initialState)
    : super(
        acceptRideUseCase: AcceptDriverRideUseCase(repository),
        markArrivedUseCase: MarkDriverRideArrivedUseCase(repository),
        startRideUseCase: StartDriverRideUseCase(repository),
        completeRideUseCase: CompleteDriverRideUseCase(repository),
        cancelRideUseCase: CancelDriverRideUseCase(repository),
        fetchAvailableRidesUseCase: FetchAvailableDriverRidesUseCase(
          repository,
        ),
        getActiveRideUseCase: GetDriverActiveRideUseCase(repository),
        updateDriverStatusUseCase: UpdateDriverStatusUseCase(
          FakeDriverStatusRepository(),
        ),
      ) {
    state = initialState;
  }

  final FakeDriverRideRepository repository;
  final List<bool> toggleValues = [];

  void setTestState(DriverHomeState nextState) {
    state = nextState;
  }

  @override
  Future<void> setOnline(bool value) async {
    toggleValues.add(value);
  }
}

class FakeDriverRideRepository implements DriverRideRepository {
  List<DriverRide> historyRides = const [];
  List<DriverRide> availableRides = const [];
  DriverRide? activeRide;
  Object? historyRidesError;
  Object? availableRidesError;
  Object? activeRideError;
  Object? acceptRideError;
  Object? markArrivedError;
  Object? startRideError;
  Object? completeRideError;
  Object? cancelRideError;
  Completer<void>? pendingActionCompleter;
  int acceptRideCalls = 0;
  int markArrivedCalls = 0;
  int startRideCalls = 0;
  int completeRideCalls = 0;
  int cancelRideCalls = 0;
  int historyRidesCalls = 0;
  int? lastFinalPrice;
  int? lastAdditionnalFreeSeconds;

  @override
  Future<void> acceptRide(
    String rideId, {
    required int driverId,
    required int vehicleId,
  }) async {
    acceptRideCalls++;
    if (acceptRideError != null) {
      throw acceptRideError!;
    }
    await pendingActionCompleter?.future;
  }

  @override
  Future<void> cancelRide(String rideId, {String? reason}) async {
    cancelRideCalls++;
    if (cancelRideError != null) {
      throw cancelRideError!;
    }
    await pendingActionCompleter?.future;
  }

  @override
  Future<void> completeRide(
    String rideId, {
    required double finalDistanceKm,
    required int finalDurationMin,
    required int finalPrice,
    required int additionnalFreeSeconds,
  }) async {
    completeRideCalls++;
    lastFinalPrice = finalPrice;
    lastAdditionnalFreeSeconds = additionnalFreeSeconds;
    if (completeRideError != null) {
      throw completeRideError!;
    }
    await pendingActionCompleter?.future;
  }

  @override
  Future<List<DriverRide>> getAvailableRides({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    if (availableRidesError != null) {
      throw availableRidesError!;
    }
    return availableRides;
  }

  @override
  Future<List<DriverRide>> getHistoryRides() async {
    historyRidesCalls++;
    if (historyRidesError != null) {
      throw historyRidesError!;
    }
    return historyRides;
  }

  @override
  Future<DriverRide?> getActiveRide(int driverId, {String? rideId}) async {
    if (activeRideError != null) {
      throw activeRideError!;
    }
    return activeRide;
  }

  @override
  Future<void> markArrived(
    String rideId, {
    required double driverLat,
    required double driverLng,
  }) async {
    markArrivedCalls++;
    if (markArrivedError != null) {
      throw markArrivedError!;
    }
    await pendingActionCompleter?.future;
  }

  @override
  Future<void> startRide(String rideId) async {
    startRideCalls++;
    if (startRideError != null) {
      throw startRideError!;
    }
    await pendingActionCompleter?.future;
  }

  @override
  Future<void> sendLocation({
    required String rideId,
    required int driverId,
    required double lat,
    required double lng,
  }) async {}

  @override
  Future<void> sendAvailabilityLocation({
    required double lat,
    required double lng,
  }) async {}
}

class FakeDriverStatusRepository implements DriverStatusRepository {
  @override
  Future<void> updateStatus({required bool isOnline}) async {}

  @override
  Future<void> sendHeartbeat() async {}
}

DriverRide buildDriverRide({
  String id = 'ride-1',
  RideStatus status = RideStatus.pending,
  LatLng? driverLocation,
  DateTime? createdAt,
  DateTime? updatedAt,
  DateTime? acceptedAt,
  DateTime? arrivedAt,
  DateTime? startedAt,
  DateTime? endedAt,
  DateTime? completedAt,
  DateTime? cancelledAt,
  double estimatedPrice = 3200,
  double? finalPrice,
  double? commissionPrice,
  int estimatedDurationMin = 18,
  double? driverRatingFromPassenger,
  String? passengerCommentForDriver,
}) {
  return DriverRide(
    rideId: id,
    status: status,
    passengerName: 'Alice Kouassi',
    pickupAddress: 'Cocody Angre',
    destinationAddress: 'Plateau Centre',
    pickupLocation: const LatLng(5.4, -3.9),
    destinationLocation: const LatLng(5.32, -4.01),
    requestedRange: 'MAGIC',
    estimatedPrice: estimatedPrice,
    finalPrice: finalPrice,
    commissionPrice: commissionPrice,
    estimatedDistanceKm: 8.4,
    estimatedDurationMin: estimatedDurationMin,
    driverRatingFromPassenger: driverRatingFromPassenger,
    passengerCommentForDriver: passengerCommentForDriver,
    assignedDriverId: status == RideStatus.pending ? null : 14,
    vehicleId: status == RideStatus.pending ? null : 7,
    driverLocation: driverLocation,
    createdAt: createdAt ?? DateTime(2026, 2, 24, 10),
    updatedAt: updatedAt ?? DateTime(2026, 2, 24, 10, 5),
    acceptedAt: acceptedAt,
    arrivedAt: arrivedAt,
    startedAt: startedAt,
    endedAt: endedAt ?? completedAt ?? cancelledAt,
    completedAt: completedAt,
    cancelledAt: cancelledAt,
  );
}

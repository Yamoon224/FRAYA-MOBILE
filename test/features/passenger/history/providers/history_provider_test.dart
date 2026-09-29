import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncError, ProviderContainer, ProviderSubscription;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/config/app_config.dart';
import 'package:fraya_mobile/core/config/app_flavor.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/core/models/ride_category.dart';
import 'package:fraya_mobile/core/utils/logger.dart';
import 'package:fraya_mobile/domain/models/active_ride.dart';
import 'package:fraya_mobile/domain/models/ride_share_link.dart';
import 'package:fraya_mobile/domain/repositories/booking_repository.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/login_passenger_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/logout_passenger_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/register_step1_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/register_step2_usecase.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/register_step3_usecase.dart';
import 'package:fraya_mobile/features/passenger/auth/providers/passenger_auth_provider.dart';
import 'package:fraya_mobile/features/passenger/auth/repositories/passenger_auth_repository.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_dependencies.dart';
import 'package:fraya_mobile/features/passenger/history/providers/history_provider.dart';
import 'package:fraya_mobile/shared/models/auth_state.dart';

void main() {
  AppConfig.instance.init(flavor: AppFlavor.dev);
  AppLogger.instance.init();

  test('rideHistory keeps only completed and cancelled rides', () async {
    final container = _createContainer(
      repository: _FakeBookingRepository(
        rides: [
          _rideMap(id: 'completed', status: 'COMPLETED'),
          _rideMap(id: 'cancelled', status: 'CANCELLED_PASSENGER'),
          _rideMap(id: 'searching', status: 'SEARCHING'),
          _rideMap(id: 'started', status: 'IN_PROGRESS'),
        ],
      ),
    );
    addTearDown(container.dispose);

    final rides = await container.read(rideHistoryProvider.future);

    expect(rides.map((ride) => ride.id), ['completed', 'cancelled']);
  });

  test(
    'historyStats excludes cancelled rides from totals and ratings',
    () async {
      final container = _createContainer(
        repository: _FakeBookingRepository(
          rides: [
            _rideMap(
              id: 'completed-1',
              status: 'COMPLETED',
              finalPrice: 1200,
              driverRating: 5,
            ),
            _rideMap(
              id: 'completed-2',
              status: 'FINISHED',
              finalPrice: 1800,
              driverRating: 3,
            ),
            _rideMap(
              id: 'cancelled-passenger',
              status: 'CANCELLED_PASSENGER',
              finalPrice: 10000,
              driverRating: 1,
            ),
            _rideMap(
              id: 'cancelled-driver',
              status: 'CANCELLED_DRIVER',
              finalPrice: 9000,
              driverRating: 5,
            ),
          ],
        ),
      );
      addTearDown(container.dispose);

      final rides = await container.read(rideHistoryProvider.future);
      final stats = await container.read(historyStatsProvider.future);

      expect(rides.map((ride) => ride.id), [
        'completed-1',
        'completed-2',
        'cancelled-passenger',
        'cancelled-driver',
      ]);
      expect(stats['totalRides'], 2);
      expect(stats['totalSpent'], 3000);
      expect(stats['avgRating'], 4.0);
    },
  );

  test('rideHistory propagates repository errors', () async {
    final container = _createContainer(
      repository: _FakeBookingRepository(
        error: const NetworkException(message: 'Timeout historique'),
      ),
    );
    addTearDown(container.dispose);

    final completer = Completer<Object>();
    late ProviderSubscription subscription;
    subscription = container.listen(
      rideHistoryProvider,
      (previous, next) {
        switch (next) {
          case AsyncError(:final error):
            if (!completer.isCompleted) completer.complete(error);
            subscription.close();
        }
      },
      fireImmediately: true,
      weak: false,
    );

    final error = await completer.future.timeout(const Duration(seconds: 2));

    expect(error, isA<NetworkException>());
  });

  test('rideHistory returns empty list for empty payload', () async {
    final container = _createContainer(
      repository: _FakeBookingRepository(rides: const []),
    );
    addTearDown(container.dispose);

    final rides = await container.read(rideHistoryProvider.future);

    expect(rides, isEmpty);
  });
}

ProviderContainer _createContainer({
  required BookingRepository repository,
  AuthState? authState,
}) {
  final state =
      authState ??
      AuthState(status: AuthStatus.authenticated, userData: {'id': 7});
  FlutterSecureStorage.setMockInitialValues({
    'access_token': 'passenger-token',
    'auth_user_data': '{"id":7}',
  });
  return ProviderContainer(
    retry: (retryCount, error) => null,
    overrides: [
      passengerAuthProvider.overrideWith(
        (ref) => _TestPassengerAuthNotifier(state),
      ),
      passengerBookingRepositoryProvider.overrideWithValue(repository),
    ],
  );
}

Map<String, dynamic> _rideMap({
  required String id,
  required String status,
  int finalPrice = 2500,
  int? driverRating,
}) {
  return {
    'id': id,
    'status': status,
    'departureAddress': 'Cocody',
    'arrivalAddress': 'Plateau',
    'createdAt': '2026-05-20T10:00:00.000Z',
    'requestedRange': 'MAGIC',
    'finalPrice': finalPrice,
    'driverRating': driverRating,
  };
}

class _TestPassengerAuthNotifier extends PassengerAuthNotifier {
  _TestPassengerAuthNotifier(AuthState initialState)
    : super(
        loginUsecase: LoginPassengerUsecase(PassengerAuthRepository()),
        registerStep1Usecase: RegisterStep1Usecase(PassengerAuthRepository()),
        registerStep2Usecase: RegisterStep2Usecase(PassengerAuthRepository()),
        registerStep3Usecase: RegisterStep3Usecase(PassengerAuthRepository()),
        logoutUsecase: LogoutPassengerUsecase(),
      ) {
    state = initialState;
  }

  @override
  set state(AuthState value) {
    if (_sameState(super.state, value)) return;
    super.state = value;
  }

  bool _sameState(AuthState left, AuthState right) {
    return left.status == right.status &&
        left.errorMessage == right.errorMessage &&
        _sameUserData(left.userData, right.userData);
  }

  bool _sameUserData(Map<String, dynamic>? left, Map<String, dynamic>? right) {
    if (identical(left, right)) return true;
    if (left == null || right == null) return left == right;
    if (left.length != right.length) return false;
    for (final entry in left.entries) {
      if (right[entry.key] != entry.value) return false;
    }
    return true;
  }
}

class _FakeBookingRepository implements BookingRepository {
  _FakeBookingRepository({this.rides = const [], this.error});

  final List<Map<String, dynamic>> rides;
  final Object? error;

  @override
  Future<List<Map<String, dynamic>>> getUserRides(int userId) async {
    if (error != null) throw error!;
    return rides;
  }

  @override
  Future<List<RideCategory>> getRideCategories() async => const [];

  @override
  Future<Map<String, RidePriceEstimate>> calculateRidePrices(
    CalculateRidePricesParams params,
  ) async => const {};

  @override
  Future<int?> calculateRidePrice(CalculateRidePriceParams params) async =>
      null;

  @override
  Future<String> requestRide(RequestRideParams params) async => '';

  @override
  Future<bool> cancelRide(String rideId, {String? reason}) async => false;

  @override
  Future<ActiveRide?> getActiveRide(int userId, {String? rideId}) async => null;

  @override
  Future<RideShareLink> createRideShareLink({
    required String rideId,
    int expiresIn = 60,
  }) async => RideShareLink(
    token: 'fake-token',
    url: 'https://example.com/ride/$rideId',
    expiresAt: DateTime.now().add(Duration(minutes: expiresIn)),
    isValid: true,
  );

  @override
  Future<RateRideOutcome> rateRide({
    required String rideId,
    required int rating,
    String? comment,
    double? tip,
  }) async => RateRideOutcome.submitted;

  @override
  Future<bool> triggerSos({
    required String rideId,
    required int userId,
    required double lat,
    required double lng,
    String? notes,
  }) async => false;

  @override
  Future<bool> createSupportTicket({
    required String rideId,
    required int userId,
    required String category,
    String? description,
  }) async => false;
}

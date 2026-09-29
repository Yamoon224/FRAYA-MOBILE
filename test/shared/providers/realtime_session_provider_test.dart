import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/config/app_config.dart';
import 'package:fraya_mobile/core/config/app_flavor.dart';
import 'package:fraya_mobile/core/realtime/realtime_events.dart';
import 'package:fraya_mobile/core/realtime/realtime_service.dart';
import 'package:fraya_mobile/core/realtime/socket_health_state.dart';
import 'package:fraya_mobile/core/services/auth_session_notifier.dart';
import 'package:fraya_mobile/core/utils/constants.dart';
import 'package:fraya_mobile/data/sources/local_storage.dart';
import 'package:fraya_mobile/domain/models/active_ride.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';
import 'package:fraya_mobile/features/driver/auth/providers/driver_auth_provider.dart';
import 'package:fraya_mobile/features/driver/home/providers/driver_home_provider.dart';
import 'package:fraya_mobile/features/driver/home/providers/driver_home_state.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/active_ride_provider.dart';
import 'package:fraya_mobile/shared/models/auth_state.dart';
import 'package:fraya_mobile/shared/providers/realtime_providers.dart';
import 'package:fraya_mobile/shared/providers/realtime_session_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../support/driver_test_doubles.dart';

class _FakeRealtimeService implements RealtimeService {
  final _nearbyController =
      StreamController<NearbyDriverMovingEvent>.broadcast();
  final _rideAcceptedController =
      StreamController<RideAcceptedEvent>.broadcast();
  final _positionController =
      StreamController<RidePositionUpdateEvent>.broadcast();
  final _driverRideStatusController =
      StreamController<DriverRideStatusRealtimeEvent>.broadcast();
  final _healthController = StreamController<SocketHealthState>.broadcast();
  final passengerTokens = <String>[];
  final driverTokens = <String>[];
  final joinedRideIds = <int>[];

  void emitPosition(RidePositionUpdateEvent event) {
    _positionController.add(event);
  }

  void emitHealth(SocketHealthState health) {
    _healthController.add(health);
  }

  @override
  Stream<NearbyDriverMovingEvent> get nearbyDriverMovingStream =>
      _nearbyController.stream;

  @override
  Stream<RideAcceptedEvent> get rideAcceptedStream =>
      _rideAcceptedController.stream;

  @override
  Stream<RidePositionUpdateEvent> get ridePositionUpdateStream =>
      _positionController.stream;

  @override
  Stream<DriverRideStatusRealtimeEvent> get driverRideStatusStream =>
      _driverRideStatusController.stream;

  @override
  Stream<DriverRideStatusRealtimeEvent> get passengerRideLifecycleStream =>
      const Stream<DriverRideStatusRealtimeEvent>.empty();

  @override
  Stream<NewRideOfferEvent> get newRideOfferStream =>
      const Stream<NewRideOfferEvent>.empty();

  @override
  Stream<void> get forceLogoutStream => const Stream<void>.empty();

  @override
  Stream<SocketHealthState> get healthStream => _healthController.stream;

  @override
  Future<void> connectPassenger({
    required String token,
    required int userId,
  }) async {
    passengerTokens.add(token);
  }

  @override
  Future<void> connectDriver({
    required String token,
    required int userId,
  }) async {
    driverTokens.add(token);
  }

  @override
  Future<void> disconnect() async {}

  @override
  void joinRide(int rideId) {
    joinedRideIds.add(rideId);
  }

  @override
  void dispose() {
    _nearbyController.close();
    _rideAcceptedController.close();
    _positionController.close();
    _driverRideStatusController.close();
    _healthController.close();
  }
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    AppConfig.instance.init(flavor: AppFlavor.passenger);
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({
      AppConstants.accessTokenKey: 'old-token',
      AppConstants.authUserDataKey: '{"id":7}',
    });
    await LocalStorage.instance.init();
  });

  test('reconnects passenger realtime with the refreshed token', () async {
    final fakeRealtime = _FakeRealtimeService();
    final container = ProviderContainer(
      overrides: [realtimeServiceProvider.overrideWithValue(fakeRealtime)],
    );
    addTearDown(container.dispose);
    addTearDown(fakeRealtime.dispose);

    container.read(realtimeSessionProvider);
    await _waitFor(() => fakeRealtime.passengerTokens.isNotEmpty);

    await LocalStorage.instance.setSecure(
      AppConstants.accessTokenKey,
      'new-token',
    );
    AuthSessionNotifier.instance.notifyTokenRefreshed();
    await _waitFor(() => fakeRealtime.passengerTokens.length >= 2);

    expect(
      fakeRealtime.passengerTokens,
      containsAll(['old-token', 'new-token']),
    );
    expect(fakeRealtime.passengerTokens.last, 'new-token');
  });

  test(
    'reconnects passenger realtime on resumed when socket is offline',
    () async {
      final fakeRealtime = _FakeRealtimeService();
      final container = ProviderContainer(
        overrides: [realtimeServiceProvider.overrideWithValue(fakeRealtime)],
      );
      addTearDown(container.dispose);
      addTearDown(fakeRealtime.dispose);

      container.read(realtimeSessionProvider);
      await _waitFor(() => fakeRealtime.passengerTokens.isNotEmpty);

      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await _waitFor(() => fakeRealtime.passengerTokens.length >= 2);

      expect(fakeRealtime.passengerTokens.last, 'old-token');
    },
  );

  test('force reconnect signal reconnects passenger realtime', () async {
    final fakeRealtime = _FakeRealtimeService();
    final container = ProviderContainer(
      overrides: [realtimeServiceProvider.overrideWithValue(fakeRealtime)],
    );
    addTearDown(container.dispose);
    addTearDown(fakeRealtime.dispose);

    container.read(realtimeSessionProvider);
    await _waitFor(() => fakeRealtime.passengerTokens.isNotEmpty);
    final initialConnectCount = fakeRealtime.passengerTokens.length;

    container.read(realtimeSessionReconnectSignalProvider.notifier).state++;
    await _waitFor(
      () => fakeRealtime.passengerTokens.length > initialConnectCount,
    );

    expect(fakeRealtime.passengerTokens.last, 'old-token');
  });

  test(
    'driver joins the active ride room after connect and ride change',
    () async {
      AppConfig.instance.init(flavor: AppFlavor.driver);
      FlutterSecureStorage.setMockInitialValues({
        AppConstants.driverAccessTokenKey: 'driver-token',
        AppConstants.driverAuthUserDataKey: '{"driverId":14}',
      });
      await LocalStorage.instance.init();

      final fakeRealtime = _FakeRealtimeService();
      final repository = FakeDriverRideRepository();
      final authNotifier = FakeDriverAuthNotifier(
        AuthState(
          status: AuthStatus.authenticated,
          userData: const {'driverId': 14, 'id': 14},
        ),
      );
      final homeNotifier = FakeDriverHomeNotifier(
        repository,
        DriverHomeState(
          status: DriverHomeStatus.ready,
          activeRide: buildDriverRide(id: '42', status: RideStatus.accepted),
        ),
      );
      final container = ProviderContainer(
        overrides: [
          realtimeServiceProvider.overrideWithValue(fakeRealtime),
          driverAuthProvider.overrideWith((ref) => authNotifier),
          driverHomeProvider.overrideWith((ref) => homeNotifier),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(fakeRealtime.dispose);

      container.read(realtimeSessionProvider);
      await _waitFor(() => fakeRealtime.driverTokens.isNotEmpty);
      await _waitFor(() => fakeRealtime.joinedRideIds.contains(42));

      final initialJoinCount = fakeRealtime.joinedRideIds.length;
      fakeRealtime.emitHealth(SocketHealthState.connected);
      await _waitFor(
        () => fakeRealtime.joinedRideIds.length > initialJoinCount,
      );
      expect(fakeRealtime.joinedRideIds.last, 42);

      homeNotifier.setTestState(
        homeNotifier.state.copyWith(
          activeRide: buildDriverRide(id: '77', status: RideStatus.accepted),
        ),
      );
      await _waitFor(() => fakeRealtime.joinedRideIds.contains(77));

      expect(fakeRealtime.driverTokens.last, 'driver-token');
      expect(fakeRealtime.joinedRideIds, containsAllInOrder([42, 77]));
    },
  );

  test('updates only the matching active ride from position events', () async {
    final fakeRealtime = _FakeRealtimeService();
    final container = ProviderContainer(
      overrides: [realtimeServiceProvider.overrideWithValue(fakeRealtime)],
    );
    addTearDown(container.dispose);
    addTearDown(fakeRealtime.dispose);

    container.read(realtimeSessionProvider);
    container
        .read(activeRideControllerProvider.notifier)
        .initialize(_activeRide);

    fakeRealtime.emitPosition(
      RidePositionUpdateEvent(rideId: '99', latitude: 5.30, longitude: -4.00),
    );
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(activeRideControllerProvider)?.driverLocation,
      const LatLng(5.35, -4.02),
    );

    fakeRealtime.emitPosition(
      RidePositionUpdateEvent(rideId: '42', latitude: 5.32, longitude: -3.98),
    );
    await _waitFor(
      () =>
          container.read(activeRideControllerProvider)?.driverLocation ==
          const LatLng(5.32, -3.98),
    );
  });
}

const _activeRide = ActiveRide(
  rideId: '42',
  driverName: 'Jean',
  driverPhoto: 'assets/images/driver_placeholder.png',
  driverRating: 4.8,
  carModel: 'Toyota',
  carPlate: 'AB-123-CD',
  driverLocation: LatLng(5.35, -4.02),
  pickupLocation: LatLng(5.31, -4.01),
  destinationLocation: LatLng(5.25, -3.93),
  status: RideStatus.inProgress,
  estimatedPrice: 2500,
);

Future<void> _waitFor(bool Function() condition) async {
  for (var i = 0; i < 40; i++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
  fail('Condition not met before timeout.');
}

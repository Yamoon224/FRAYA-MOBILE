import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/config/app_config.dart';
import 'package:fraya_mobile/core/config/app_flavor.dart';
import 'package:fraya_mobile/core/models/places_models.dart';
import 'package:fraya_mobile/core/realtime/realtime_events.dart';
import 'package:fraya_mobile/core/realtime/realtime_service.dart';
import 'package:fraya_mobile/core/realtime/socket_health_state.dart';
import 'package:fraya_mobile/data/sources/remote/booking_remote_data_source.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_flow_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/ride_categories_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/route_directions_provider.dart';
import 'package:fraya_mobile/features/passenger/map/providers/nearby_drivers_provider.dart';
import 'package:fraya_mobile/shared/models/device_status_snapshot.dart';
import 'package:fraya_mobile/shared/providers/app_resume_refresh_provider.dart';
import 'package:fraya_mobile/shared/providers/device_status_provider.dart';
import 'package:fraya_mobile/shared/providers/location_provider.dart';
import 'package:fraya_mobile/shared/providers/places_provider.dart';
import 'package:fraya_mobile/shared/providers/realtime_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('appResumeRefreshThresholdProvider defaults to 10 seconds in debug', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(appResumeRefreshThresholdProvider),
      const Duration(seconds: 10),
    );
  });

  test('appResumeRefreshThresholdProvider can be overridden', () {
    final container = ProviderContainer(
      overrides: [
        appResumeRefreshThresholdProvider.overrideWithValue(
          const Duration(minutes: 3),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(appResumeRefreshThresholdProvider),
      const Duration(minutes: 3),
    );
  });

  group('AppResumeRefreshLifecycleCoordinator', () {
    test('ignores 9 second background sessions', () async {
      var now = DateTime(2026, 7, 10, 12);
      var refreshCount = 0;
      var dismissCount = 0;
      final coordinator = AppResumeRefreshLifecycleCoordinator(
        threshold: () => const Duration(seconds: 10),
        refreshAfterLongBackground: () async => refreshCount++,
        dismissTransientAlerts: () => dismissCount++,
        now: () => now,
      );

      coordinator.didChangeAppLifecycleState(AppLifecycleState.paused);
      now = now.add(const Duration(seconds: 9));
      coordinator.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      expect(refreshCount, 0);
      expect(dismissCount, 0);
    });

    test('refreshes once after 10 second threshold is reached', () async {
      var now = DateTime(2026, 7, 10, 12);
      var refreshCount = 0;
      var dismissCount = 0;
      final coordinator = AppResumeRefreshLifecycleCoordinator(
        threshold: () => const Duration(seconds: 10),
        refreshAfterLongBackground: () async => refreshCount++,
        dismissTransientAlerts: () => dismissCount++,
        now: () => now,
      );

      coordinator.didChangeAppLifecycleState(AppLifecycleState.inactive);
      coordinator.didChangeAppLifecycleState(AppLifecycleState.paused);
      now = now.add(const Duration(seconds: 10));
      coordinator.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      expect(refreshCount, 1);
      expect(dismissCount, 1);
    });

    test('does not start a duplicate refresh while one is running', () async {
      var now = DateTime(2026, 7, 10, 12);
      var refreshCount = 0;
      final refreshCompleter = Completer<void>();
      final coordinator = AppResumeRefreshLifecycleCoordinator(
        threshold: () => const Duration(seconds: 10),
        refreshAfterLongBackground: () {
          refreshCount++;
          return refreshCompleter.future;
        },
        dismissTransientAlerts: () {},
        now: () => now,
      );

      coordinator.didChangeAppLifecycleState(AppLifecycleState.paused);
      now = now.add(const Duration(seconds: 10));
      coordinator.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      coordinator.didChangeAppLifecycleState(AppLifecycleState.paused);
      now = now.add(const Duration(seconds: 10));
      coordinator.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      expect(refreshCount, 1);
      expect(coordinator.isRefreshInFlight, isTrue);

      refreshCompleter.complete();
      await Future<void>.delayed(Duration.zero);
      expect(coordinator.isRefreshInFlight, isFalse);
    });

    test(
      'forwards detached without treating background as app closing',
      () async {
        var detachedCount = 0;
        final coordinator = AppResumeRefreshLifecycleCoordinator(
          threshold: () => const Duration(seconds: 10),
          refreshAfterLongBackground: () async {},
          dismissTransientAlerts: () {},
          handleAppDetached: () async => detachedCount++,
        );

        coordinator.didChangeAppLifecycleState(AppLifecycleState.inactive);
        coordinator.didChangeAppLifecycleState(AppLifecycleState.paused);
        await Future<void>.delayed(Duration.zero);
        expect(detachedCount, 0);

        coordinator.didChangeAppLifecycleState(AppLifecycleState.detached);
        await Future<void>.delayed(Duration.zero);
        expect(detachedCount, 1);
      },
    );

    test('forwards resume after any background duration', () async {
      var resumedCount = 0;
      final coordinator = AppResumeRefreshLifecycleCoordinator(
        threshold: () => const Duration(minutes: 3),
        refreshAfterLongBackground: () async {},
        dismissTransientAlerts: () {},
        handleAppResumed: () async => resumedCount++,
      );

      coordinator.didChangeAppLifecycleState(AppLifecycleState.paused);
      coordinator.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      expect(resumedCount, 1);
    });
  });

  test(
    'passenger resume refresh updates transient data without clearing route inputs',
    () async {
      AppConfig.instance.init(flavor: AppFlavor.passenger);
      final fakeRealtime = _FakeRealtimeService();
      final fakeDataSource = _FakeBookingRemoteDataSource();
      final container = ProviderContainer(
        overrides: [
          realtimeServiceProvider.overrideWithValue(fakeRealtime),
          nearbyDriversDataSourceProvider.overrideWithValue(fakeDataSource),
          deviceStatusProvider.overrideWith(
            (ref) => Stream<DeviceStatusSnapshot>.value(
              DeviceStatusSnapshot.initial(),
            ),
          ),
          bookingFlowProvider.overrideWith(_RoutePreviewBookingFlow.new),
          routeDirectionsProvider.overrideWith((ref) async => null),
          rideCategoriesProvider.overrideWith((ref) async => const []),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(fakeRealtime.dispose);
      final locationRefreshSub = container.listen(
        passengerLocationSnapshotRefreshTriggerProvider,
        (_, _) {},
      );
      final flowSub = container.listen(bookingFlowProvider, (_, _) {});
      addTearDown(locationRefreshSub.close);
      addTearDown(flowSub.close);
      final flow =
          container.read(bookingFlowProvider.notifier)
              as _RoutePreviewBookingFlow;

      final pickup = _place('pickup');
      final destination = _place('destination');
      container.read(selectedPickupProvider.notifier).setPlace(pickup);
      container
          .read(selectedDestinationProvider.notifier)
          .setPlace(destination);

      await container
          .read(appResumeRefreshActionsProvider)
          .refreshAfterLongBackground();

      expect(
        container.read(passengerLocationSnapshotRefreshTriggerProvider),
        1,
      );
      expect(container.read(selectedPickupProvider)?.placeId, pickup.placeId);
      expect(
        container.read(selectedDestinationProvider)?.placeId,
        destination.placeId,
      );
      expect(fakeDataSource.nearbyFetchCount, greaterThanOrEqualTo(1));
      expect(flow.hardRefreshCount, 1);
    },
  );
}

PlaceDetails _place(String id) {
  return PlaceDetails(
    placeId: id,
    name: id,
    address: 'Cocody',
    latitude: 5.35,
    longitude: -4.01,
  );
}

class _RoutePreviewBookingFlow extends BookingFlow {
  int hardRefreshCount = 0;

  @override
  BookingFlowState build() => BookingFlowState.routePreview;

  @override
  Future<void> hardRefreshStatus() async {
    hardRefreshCount++;
  }
}

class _FakeBookingRemoteDataSource extends BookingRemoteDataSource {
  _FakeBookingRemoteDataSource() : super(dio: Dio());

  int nearbyFetchCount = 0;

  @override
  Future<List<Map<String, dynamic>>> getNearbyDrivers() async {
    nearbyFetchCount++;
    return const [];
  }
}

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
  }) async {}

  @override
  Future<void> connectDriver({
    required String token,
    required int userId,
  }) async {}

  @override
  Future<void> disconnect() async {}

  @override
  void joinRide(int rideId) {}

  @override
  void dispose() {
    _nearbyController.close();
    _rideAcceptedController.close();
    _positionController.close();
    _driverRideStatusController.close();
    _healthController.close();
  }
}

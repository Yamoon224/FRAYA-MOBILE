import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/realtime/realtime_events.dart';
import 'package:fraya_mobile/core/realtime/realtime_service.dart';
import 'package:fraya_mobile/core/realtime/socket_health_state.dart';
import 'package:fraya_mobile/data/sources/remote/booking_remote_data_source.dart';
import 'package:fraya_mobile/features/passenger/map/providers/nearby_drivers_provider.dart';
import 'package:fraya_mobile/shared/providers/realtime_providers.dart';

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

  void emitNearby({
    required String driverId,
    required double lat,
    required double lng,
    double? bearing,
    String? vehicleColorRaw,
  }) {
    _nearbyController.add(
      NearbyDriverMovingEvent(
        driverId: driverId,
        latitude: lat,
        longitude: lng,
        bearing: bearing,
        vehicleColorRaw: vehicleColorRaw,
      ),
    );
  }

  void emitHealth(SocketHealthState state) => _healthController.add(state);

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

class _FakeNearbyDriversDataSource extends BookingRemoteDataSource {
  _FakeNearbyDriversDataSource() : super(dio: Dio());

  @override
  Future<List<Map<String, dynamic>>> getNearbyDrivers() async => const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'updates nearby drivers from realtime stream with deduplication',
    () async {
      final fakeRealtime = _FakeRealtimeService();
      final container = ProviderContainer(
        overrides: [
          realtimeServiceProvider.overrideWithValue(fakeRealtime),
          nearbyDriversDataSourceProvider.overrideWithValue(
            _FakeNearbyDriversDataSource(),
          ),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(fakeRealtime.dispose);

      final sub = container.listen(nearbyDriversProvider, (previous, next) {});
      addTearDown(sub.close);

      fakeRealtime.emitHealth(SocketHealthState.connected);
      fakeRealtime.emitNearby(
        driverId: 'd-1',
        lat: 5.35,
        lng: -4.01,
        bearing: 30,
        vehicleColorRaw: 'Bleu',
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      var drivers = container.read(nearbyDriversProvider);
      expect(drivers.length, 1);
      expect(drivers.first.id, 'd-1');
      expect(drivers.first.vehicleColorRaw, 'Bleu');

      fakeRealtime.emitNearby(
        driverId: 'd-1',
        lat: 5.36,
        lng: -4.02,
        bearing: 45,
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      drivers = container.read(nearbyDriversProvider);
      expect(drivers.length, 1);
      expect(drivers.first.bearing, 45);
      expect(drivers.first.vehicleColorRaw, 'Bleu');
    },
  );
}

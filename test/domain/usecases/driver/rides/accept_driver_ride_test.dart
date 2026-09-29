import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/core/error/failures.dart';
import 'package:fraya_mobile/domain/models/driver_ride.dart';
import 'package:fraya_mobile/domain/repositories/driver_ride_repository.dart';
import 'package:fraya_mobile/domain/usecases/driver/rides/accept_driver_ride.dart';

class RecordingDriverRideRepository implements DriverRideRepository {
  String? acceptedRideId;
  int? acceptedDriverId;
  int? acceptedVehicleId;
  Object? error;

  @override
  Future<void> acceptRide(
    String rideId, {
    required int driverId,
    required int vehicleId,
  }) async {
    if (error != null) {
      throw error!;
    }
    acceptedRideId = rideId;
    acceptedDriverId = driverId;
    acceptedVehicleId = vehicleId;
  }

  @override
  Future<void> cancelRide(String rideId, {String? reason}) {
    throw UnimplementedError();
  }

  @override
  Future<void> completeRide(
    String rideId, {
    required double finalDistanceKm,
    required int finalDurationMin,
    required int finalPrice,
    required int additionnalFreeSeconds,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<DriverRide?> getActiveRide(int driverId, {String? rideId}) {
    throw UnimplementedError();
  }

  @override
  Future<List<DriverRide>> getHistoryRides() {
    throw UnimplementedError();
  }

  @override
  Future<List<DriverRide>> getAvailableRides({
    required double lat,
    required double lng,
    required double radiusKm,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> markArrived(
    String rideId, {
    required double driverLat,
    required double driverLng,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> startRide(String rideId) {
    throw UnimplementedError();
  }

  @override
  Future<void> sendLocation({
    required String rideId,
    required int driverId,
    required double lat,
    required double lng,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> sendAvailabilityLocation({
    required double lat,
    required double lng,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  group('AcceptDriverRideUseCase', () {
    test('forwards rideId driverId and vehicleId', () async {
      final repository = RecordingDriverRideRepository();
      final useCase = AcceptDriverRideUseCase(repository);

      final result = await useCase(
        const AcceptDriverRideParams(rideId: '14', driverId: 9, vehicleId: 1),
      );

      expect(result.isRight(), isTrue);
      expect(repository.acceptedRideId, '14');
      expect(repository.acceptedDriverId, 9);
      expect(repository.acceptedVehicleId, 1);
    });

    test('maps server exceptions to clear french failures', () async {
      final repository = RecordingDriverRideRepository()
        ..error = const ServerException(
          message:
              'Cette course n\'est plus disponible. Actualisez la liste des demandes.',
          statusCode: 409,
        );
      final useCase = AcceptDriverRideUseCase(repository);

      final result = await useCase(
        const AcceptDriverRideParams(rideId: '14', driverId: 9, vehicleId: 1),
      );

      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(
          failure.message,
          'Cette course n\'est plus disponible. Actualisez la liste des demandes.',
        );
      }, (_) => fail('Expected a failure'));
    });
  });
}

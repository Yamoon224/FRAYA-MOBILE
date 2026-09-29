import '../../../repositories/driver_ride_repository.dart';

class SendDriverLocationUseCase {
  const SendDriverLocationUseCase(this._repository);

  final DriverRideRepository _repository;

  Future<void> call({
    required String rideId,
    required int driverId,
    required double lat,
    required double lng,
  }) {
    return _repository.sendLocation(
      rideId: rideId,
      driverId: driverId,
      lat: lat,
      lng: lng,
    );
  }
}

class SendDriverAvailabilityLocationUseCase {
  const SendDriverAvailabilityLocationUseCase(this._repository);

  final DriverRideRepository _repository;

  Future<void> call({required double lat, required double lng}) {
    return _repository.sendAvailabilityLocation(lat: lat, lng: lng);
  }
}

library;

import '../../../../domain/usecases/driver/rides/accept_driver_ride.dart';
import '../../../../domain/usecases/driver/rides/cancel_driver_ride.dart';
import '../../../../domain/usecases/driver/rides/complete_driver_ride.dart';
import '../../../../domain/usecases/driver/rides/mark_driver_ride_arrived.dart';
import '../../../../domain/usecases/driver/rides/start_driver_ride.dart';

class DriverHomeActionExecutor {
  DriverHomeActionExecutor({
    required AcceptDriverRideUseCase acceptRideUseCase,
    required MarkDriverRideArrivedUseCase markArrivedUseCase,
    required StartDriverRideUseCase startRideUseCase,
    required CompleteDriverRideUseCase completeRideUseCase,
    required CancelDriverRideUseCase cancelRideUseCase,
  }) : _acceptRideUseCase = acceptRideUseCase,
       _markArrivedUseCase = markArrivedUseCase,
       _startRideUseCase = startRideUseCase,
       _completeRideUseCase = completeRideUseCase,
       _cancelRideUseCase = cancelRideUseCase;

  final AcceptDriverRideUseCase _acceptRideUseCase;
  final MarkDriverRideArrivedUseCase _markArrivedUseCase;
  final StartDriverRideUseCase _startRideUseCase;
  final CompleteDriverRideUseCase _completeRideUseCase;
  final CancelDriverRideUseCase _cancelRideUseCase;

  Future<String?> acceptRide({
    required String rideId,
    required int driverId,
    required int vehicleId,
  }) async {
    final result = await _acceptRideUseCase(
      AcceptDriverRideParams(
        rideId: rideId,
        driverId: driverId,
        vehicleId: vehicleId,
      ),
    );
    return _mapResult(result);
  }

  Future<String?> markArrived({
    required String rideId,
    required double driverLat,
    required double driverLng,
  }) async {
    final result = await _markArrivedUseCase(
      MarkDriverRideArrivedParams(
        rideId: rideId,
        driverLat: driverLat,
        driverLng: driverLng,
      ),
    );
    return _mapResult(result);
  }

  Future<String?> startRide({required String rideId}) async {
    final result = await _startRideUseCase(
      StartDriverRideParams(rideId: rideId),
    );
    return _mapResult(result);
  }

  Future<String?> completeRide({
    required String rideId,
    required double finalDistanceKm,
    required int finalDurationMin,
    required int finalPrice,
    int additionnalFreeSeconds = 0,
  }) async {
    final result = await _completeRideUseCase(
      CompleteDriverRideParams(
        rideId: rideId,
        finalDistanceKm: finalDistanceKm,
        finalDurationMin: finalDurationMin,
        finalPrice: finalPrice,
        additionnalFreeSeconds: additionnalFreeSeconds,
      ),
    );
    return _mapResult(result);
  }

  Future<String?> cancelRide({required String rideId, String? reason}) async {
    final result = await _cancelRideUseCase(
      CancelDriverRideParams(rideId: rideId, reason: reason),
    );
    return _mapResult(result);
  }

  String? _mapResult(dynamic result) {
    return result.fold((failure) => failure.message, (_) => null);
  }
}

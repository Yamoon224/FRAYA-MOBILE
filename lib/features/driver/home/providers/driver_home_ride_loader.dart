library;

import '../../../../core/utils/constants.dart';
import '../../../../domain/models/driver_ride.dart';
import '../../../../domain/usecases/driver/rides/fetch_available_driver_rides.dart';
import '../../../../domain/usecases/driver/rides/get_driver_active_ride.dart';

class DriverHomeRideLoadResult {
  const DriverHomeRideLoadResult({
    this.activeRide,
    this.availableRides = const [],
    this.errorMessage,
  });

  final DriverRide? activeRide;
  final List<DriverRide> availableRides;
  final String? errorMessage;

  bool get hasError => errorMessage != null && errorMessage!.trim().isNotEmpty;
}

class DriverHomeRideLoader {
  DriverHomeRideLoader({
    required FetchAvailableDriverRidesUseCase fetchAvailableRidesUseCase,
    required GetDriverActiveRideUseCase getActiveRideUseCase,
  }) : _fetchAvailableRidesUseCase = fetchAvailableRidesUseCase,
       _getActiveRideUseCase = getActiveRideUseCase;

  final FetchAvailableDriverRidesUseCase _fetchAvailableRidesUseCase;
  final GetDriverActiveRideUseCase _getActiveRideUseCase;

  Future<DriverHomeRideLoadResult> loadInitial(
    int driverId, {
    double? driverLat,
    double? driverLng,
  }) async {
    final result = await _getActiveRideUseCase(
      GetDriverActiveRideParams(driverId: driverId),
    );

    return result.fold((_) => _loadAvailableRides(driverLat, driverLng), (
      ride,
    ) async {
      if (ride != null) {
        return DriverHomeRideLoadResult(activeRide: ride);
      }
      return _loadAvailableRides(driverLat, driverLng);
    });
  }

  Future<DriverHomeRideLoadResult> refresh({
    required int driverId,
    String? activeRideId,
    double? driverLat,
    double? driverLng,
    bool fetchAvailableRides = false,
  }) async {
    if (activeRideId == null || activeRideId.trim().isEmpty) {
      return _loadAvailableRides(driverLat, driverLng);
    }

    final result = await _getActiveRideUseCase(
      GetDriverActiveRideParams(driverId: driverId, rideId: activeRideId),
    );

    return result.fold(
      (failure) {
        return DriverHomeRideLoadResult(errorMessage: failure.message);
      },
      (ride) async {
        if (ride == null) return _loadAvailableRides(driverLat, driverLng);
        if (!fetchAvailableRides) {
          return DriverHomeRideLoadResult(activeRide: ride);
        }
        final availResult = await _loadAvailableRides(driverLat, driverLng);
        return DriverHomeRideLoadResult(
          activeRide: ride,
          availableRides: availResult.availableRides,
        );
      },
    );
  }

  Future<DriverHomeRideLoadResult> _loadAvailableRides(
    double? driverLat,
    double? driverLng,
  ) async {
    final lat = driverLat ?? AppConstants.abidjanLat;
    final lng = driverLng ?? AppConstants.abidjanLng;
    final result = await _fetchAvailableRidesUseCase(
      FetchAvailableDriverRidesParams(
        lat: lat,
        lng: lng,
        radiusKm: AppConstants.driverAvailableRidesRadiusKm,
      ),
    );
    return result.fold(
      (failure) {
        return DriverHomeRideLoadResult(errorMessage: failure.message);
      },
      (rides) {
        return DriverHomeRideLoadResult(availableRides: rides);
      },
    );
  }
}

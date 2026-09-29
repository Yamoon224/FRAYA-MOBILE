library;

import '../../domain/models/driver_ride.dart';

const _driverHistoryStatuses = {
  'COMPLETED',
  'FINISHED',
  'DONE',
  'CANCELLED_PASSENGER',
  'CANCELLED_DRIVER',
};

List<DriverRide> filterDriverHistoryRidesFromRaw(
  List<Map<String, dynamic>> rawRides,
) {
  final rides = rawRides.where((map) {
    final status =
        (map['statusRace'] ?? map['status'] ?? map['rideStatus'] ?? '')
            .toString()
            .trim()
            .toUpperCase();
    return _driverHistoryStatuses.contains(status);
  }).map(DriverRide.fromMap).toList();
  rides.sort(compareDriverRidesByHistoryDate);
  return rides;
}

List<DriverRide> filterAvailableDriverRides(List<DriverRide> rides) {
  final availableRides = rides.where((ride) {
    if (ride.rideId.isEmpty || !ride.isPending) {
      return false;
    }
    return ride.assignedDriverId == null;
  }).toList();
  availableRides.sort(compareDriverRidesByRecency);
  return availableRides;
}

DriverRide? selectActiveDriverRide(
  List<DriverRide> rides,
  int driverId, {
  String? rideId,
}) {
  if (rideId != null && rideId.isNotEmpty) {
    final requestedRide = _findRideById(rides, rideId);
    if (requestedRide != null) {
      return requestedRide;
    }
  }

  final activeRides = rides.where((ride) {
    return ride.assignedDriverId == driverId && ride.isActiveForDriver;
  }).toList();
  if (activeRides.isEmpty) {
    return null;
  }
  activeRides.sort(compareDriverRidesByRecency);
  return activeRides.first;
}

int compareDriverRidesByHistoryDate(DriverRide a, DriverRide b) {
  final bDate = b.historyDate;
  final aDate = a.historyDate;
  if (aDate != null && bDate != null) {
    return bDate.compareTo(aDate);
  }
  if (bDate != null) {
    return 1;
  }
  if (aDate != null) {
    return -1;
  }
  return b.rideId.compareTo(a.rideId);
}

int compareDriverRidesByRecency(DriverRide a, DriverRide b) {
  final bDate = b.updatedAt ?? b.createdAt;
  final aDate = a.updatedAt ?? a.createdAt;
  if (aDate != null && bDate != null) {
    return bDate.compareTo(aDate);
  }
  if (bDate != null) {
    return 1;
  }
  if (aDate != null) {
    return -1;
  }
  return b.rideId.compareTo(a.rideId);
}

DriverRide? _findRideById(List<DriverRide> rides, String rideId) {
  for (final ride in rides) {
    if (ride.rideId == rideId && ride.isActiveForDriver) {
      return ride;
    }
  }
  return null;
}

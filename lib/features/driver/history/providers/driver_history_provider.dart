library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../domain/models/driver_ride.dart';
import '../../../../domain/models/ride_status.dart';
import '../../../../features/driver/home/providers/driver_ride_dependencies.dart';
import '../models/driver_history_stats.dart';

final driverHistoryRidesProvider = FutureProvider<List<DriverRide>>((
  ref,
) async {
  final useCase = ref.read(getDriverHistoryRidesUseCaseProvider);
  final result = await useCase();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (rides) => rides,
  );
});

final todayDriverHistoryRidesProvider = Provider<List<DriverRide>>((ref) {
  final rides = ref.watch(driverHistoryRidesProvider).asData?.value ?? const [];
  final today = _startOfDay(DateTime.now());
  return rides
      .where(
        (ride) =>
            ride.historyDate != null && _startOfDay(ride.historyDate!) == today,
      )
      .toList();
});

final allDriverHistoryRidesProvider = Provider<List<DriverRide>>((ref) {
  return ref.watch(driverHistoryRidesProvider).asData?.value ?? const [];
});

final todayDriverHistoryStatsProvider = Provider<DriverHistoryStats>((ref) {
  final rides = ref.watch(todayDriverHistoryRidesProvider);
  return buildDriverHistoryStats(rides);
});

final allDriverHistoryStatsProvider = Provider<DriverHistoryStats>((ref) {
  final rides = ref.watch(allDriverHistoryRidesProvider);
  return buildDriverHistoryStats(rides);
});

DriverHistoryStats buildDriverHistoryStats(List<DriverRide> rides) {
  final completedRides = rides
      .where((ride) => ride.status == RideStatus.completed)
      .toList();
  final earnings = completedRides.fold<double>(
    0,
    (sum, ride) => sum + (ride.finalPrice ?? ride.estimatedPrice),
  );
  final ratedRides = completedRides
      .where(
        (ride) =>
            ride.driverRatingFromPassenger != null &&
            ride.driverRatingFromPassenger! > 0,
      )
      .toList();
  final averageRating = ratedRides.isEmpty
      ? 0.0
      : ratedRides.fold<double>(
              0,
              (sum, ride) => sum + ride.driverRatingFromPassenger!,
            ) /
            ratedRides.length;
  return DriverHistoryStats(
    completedRideCount: completedRides.length,
    earnings: earnings,
    averageRating: averageRating,
    ratedRideCount: ratedRides.length,
  );
}

String formatDriverHistoryDay(DateTime date) {
  final today = _startOfDay(DateTime.now());
  final target = _startOfDay(date);
  if (target == today) {
    return 'Aujourd\'hui';
  }
  return DateFormat('EEEE dd MMM', 'fr_FR')
      .format(target)
      .replaceFirstMapped(
        RegExp(r'^[a-z]'),
        (match) => match.group(0)!.toUpperCase(),
      );
}

DateTime _startOfDay(DateTime date) {
  final localDate = date.toLocal();
  return DateTime(localDate.year, localDate.month, localDate.day);
}

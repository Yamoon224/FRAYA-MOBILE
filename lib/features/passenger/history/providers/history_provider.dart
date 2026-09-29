import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/models/ride_model.dart';
import '../../../../core/utils/logger.dart';
import '../../../../features/passenger/auth/providers/passenger_auth_provider.dart';
import '../../../../features/passenger/booking/providers/booking_dependencies.dart';

part 'history_provider.g.dart';

@riverpod
class RideHistory extends _$RideHistory {
  @override
  Future<List<Ride>> build() async {
    final authState = ref.watch(passengerAuthProvider);
    final userId = _parseUserId(authState.userData);

    if (userId == null) {
      if (authState.userData != null) {
        logger.warning(
          'RideHistory skipped: unable to parse passenger userId from auth payload.',
        );
      }
      return [];
    }

    final repository = ref.read(passengerBookingRepositoryProvider);
    logger.debug(
      'RideHistory start: loading rides for passenger userId=$userId',
    );

    try {
      final rawRides = await repository.getUserRides(userId);
      logger.debug(
        'RideHistory raw load success: received ${rawRides.length} ride(s).',
      );

      const historyStatuses = {
        'COMPLETED',
        'FINISHED',
        'CANCELLED_PASSENGER',
        'CANCELLED_DRIVER',
      };
      final rides = <Ride>[];
      final ignoredStatuses = <String, int>{};
      var missingStatusCount = 0;

      for (final rideMap in rawRides) {
        final status = _readStatus(rideMap);
        if (status.isEmpty) {
          missingStatusCount++;
          continue;
        }
        if (!historyStatuses.contains(status)) {
          ignoredStatuses[status] = (ignoredStatuses[status] ?? 0) + 1;
          continue;
        }
        rides.add(Ride.fromMap(rideMap));
      }

      if (missingStatusCount > 0) {
        logger.warning(
          'RideHistory ignored $missingStatusCount ride(s) with missing status.',
        );
      }
      if (ignoredStatuses.isNotEmpty) {
        logger.debug(
          'RideHistory ignored non-history statuses: $ignoredStatuses',
        );
      }
      logger.debug(
        'RideHistory filtered success: kept ${rides.length}/${rawRides.length} ride(s).',
      );
      return rides;
    } catch (error, stackTrace) {
      logger.warning('RideHistory load failed: $error', error, stackTrace);
      rethrow;
    }
  }

  int? _parseUserId(Map<String, dynamic>? userData) {
    if (userData == null) return null;
    final nestedUser = userData['user'] is Map
        ? Map<String, dynamic>.from(userData['user'] as Map)
        : null;
    final raw =
        userData['id'] ??
        userData['userId'] ??
        userData['sub'] ??
        userData['idUser'] ??
        userData['user_id'] ??
        userData['passengerId'] ??
        nestedUser?['id'] ??
        nestedUser?['userId'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }

  String _readStatus(Map<String, dynamic> rideMap) {
    return (rideMap['status'] ??
            rideMap['rideStatus'] ??
            rideMap['courseStatus'] ??
            rideMap['statusRace'] ??
            '')
        .toString()
        .trim()
        .toUpperCase();
  }
}

@riverpod
Future<Map<String, dynamic>> historyStats(Ref ref) async {
  final rides = await ref.watch(rideHistoryProvider.future);
  final completedRides = rides
      .where((ride) => ride.status == RideStatus.completed)
      .toList();

  final totalRides = completedRides.length;
  final totalSpent = completedRides.fold<int>(0, (sum, r) => sum + r.price);

  double avgRating = 0.0;
  // Moyenne basée uniquement sur les courses réellement notées par le passager
  // (note de course > 0), pas sur la note de profil chauffeur.
  final ratedRides = completedRides.where((r) => r.hasRated).toList();
  if (ratedRides.isNotEmpty) {
    final sumRatings = ratedRides.fold<double>(
      0,
      (sum, r) => sum + r.driverRatingFromPassenger!,
    );
    avgRating = sumRatings / ratedRides.length;
  }

  return {
    'totalRides': totalRides,
    'totalSpent': totalSpent,
    'avgRating': avgRating,
  };
}

@riverpod
List<Ride> recentRides(Ref ref) {
  final ridesAsync = ref.watch(rideHistoryProvider);
  final rides = ridesAsync.asData?.value ?? [];

  final sorted = List<Ride>.from(rides)
    ..sort((a, b) => b.date.compareTo(a.date));
  return sorted.take(3).toList();
}

@riverpod
List<Ride> allRides(Ref ref) {
  final ridesAsync = ref.watch(rideHistoryProvider);
  final rides = ridesAsync.asData?.value ?? [];

  return List<Ride>.from(rides)..sort((a, b) => b.date.compareTo(a.date));
}

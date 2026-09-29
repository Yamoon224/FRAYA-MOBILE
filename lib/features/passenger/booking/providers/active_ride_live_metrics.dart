library;

import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/utils/measurement_formatter.dart';
import '../../../../domain/models/active_ride.dart';
import '../../../../domain/models/ride_status.dart';

const arrivalProgressCompleteDistanceMeters = 5.0;

enum ActiveRideLiveMetricsSource { backend, directions, approximate }

class ActiveRideLiveMetrics {
  const ActiveRideLiveMetrics({
    required this.etaText,
    required this.distanceText,
    required this.arrivalTimeText,
    required this.lastUpdatedAt,
    required this.source,
  });

  final String etaText;
  final String distanceText;
  final String? arrivalTimeText;
  final DateTime? lastUpdatedAt;
  final ActiveRideLiveMetricsSource source;

  factory ActiveRideLiveMetrics.empty() {
    return const ActiveRideLiveMetrics(
      etaText: '--',
      distanceText: '--',
      arrivalTimeText: null,
      lastUpdatedAt: null,
      source: ActiveRideLiveMetricsSource.backend,
    );
  }
}

class ActiveRideLiveMetricsCalculator {
  const ActiveRideLiveMetricsCalculator._();

  static ActiveRideLiveMetrics fromRide(
    ActiveRide? ride, {
    required DateTime now,
    required double averageSpeedKmh,
  }) {
    if (ride == null) return ActiveRideLiveMetrics.empty();

    if (ride.status == RideStatus.accepted) {
      return _approximateApproachMetrics(
            ride,
            now: now,
            averageSpeedKmh: averageSpeedKmh,
          ) ??
          const ActiveRideLiveMetrics(
            etaText: '--',
            distanceText: '--',
            arrivalTimeText: null,
            lastUpdatedAt: null,
            source: ActiveRideLiveMetricsSource.backend,
          );
    }

    if (ride.status == RideStatus.arrived) {
      return ActiveRideLiveMetrics(
        etaText: MeasurementFormatter.formatDurationMinutes(0),
        distanceText: '0 m',
        arrivalTimeText: formatClockTime(now),
        lastUpdatedAt: now,
        source: ActiveRideLiveMetricsSource.backend,
      );
    }

    if (ride.status == RideStatus.inProgress) {
      return _approximateInProgressMetrics(
            ride,
            now: now,
            averageSpeedKmh: averageSpeedKmh,
          ) ??
          ActiveRideLiveMetrics(
            etaText: MeasurementFormatter.normalizeDuration(
              ride.estimatedDuration,
              fallback: '--',
            ),
            distanceText: MeasurementFormatter.normalizeDistance(
              ride.estimatedDistance,
              fallback: '--',
            ),
            arrivalTimeText: null,
            lastUpdatedAt: null,
            source: ActiveRideLiveMetricsSource.backend,
          );
    }

    return ActiveRideLiveMetrics(
      etaText: MeasurementFormatter.normalizeDuration(
        ride.estimatedDuration,
        fallback: '--',
      ),
      distanceText: MeasurementFormatter.normalizeDistance(
        ride.estimatedDistance,
        fallback: '--',
      ),
      arrivalTimeText: null,
      lastUpdatedAt: null,
      source: ActiveRideLiveMetricsSource.backend,
    );
  }

  static ActiveRideLiveMetrics? _approximateInProgressMetrics(
    ActiveRide ride, {
    required DateTime now,
    required double averageSpeedKmh,
  }) {
    final destination = ride.destinationLocation;
    if (destination == null || averageSpeedKmh <= 0) return null;

    final distanceMetersValue = distanceMeters(ride.driverLocation, destination);
    final durationMinutes =
        distanceMetersValue <= arrivalProgressCompleteDistanceMeters
        ? 0
        : math.max(
            1,
            ((distanceMetersValue / 1000) / averageSpeedKmh * 60).ceil(),
          );

    return ActiveRideLiveMetrics(
      etaText: MeasurementFormatter.formatDurationMinutes(durationMinutes),
      distanceText: _formatDistanceMeters(distanceMetersValue),
      arrivalTimeText: _arrivalTimeFromMinutes(now, durationMinutes),
      lastUpdatedAt: now,
      source: ActiveRideLiveMetricsSource.approximate,
    );
  }

  static String? arrivalTimeText(DateTime now, int durationSeconds) {
    if (durationSeconds < 0) return null;
    return formatClockTime(now.add(Duration(seconds: durationSeconds)));
  }

  static String formatClockTime(DateTime value) {
    final hours = value.hour.toString().padLeft(2, '0');
    final minutes = value.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  static double distanceMeters(LatLng a, LatLng b) {
    const earthRadius = 6371000.0;
    final dLat = _toRadians(b.latitude - a.latitude);
    final dLng = _toRadians(b.longitude - a.longitude);
    final sinLat = math.sin(dLat / 2);
    final sinLng = math.sin(dLng / 2);
    final haversine =
        sinLat * sinLat +
        math.cos(_toRadians(a.latitude)) *
            math.cos(_toRadians(b.latitude)) *
            sinLng *
            sinLng;
    final arc = 2 * math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));
    return earthRadius * arc;
  }

  static ActiveRideLiveMetrics? _approximateApproachMetrics(
    ActiveRide ride, {
    required DateTime now,
    required double averageSpeedKmh,
  }) {
    final pickup = ride.pickupLocation;
    if (pickup == null || averageSpeedKmh <= 0) return null;

    final distanceMetersValue = distanceMeters(ride.driverLocation, pickup);
    final durationMinutes =
        distanceMetersValue <= arrivalProgressCompleteDistanceMeters
        ? 0
        : math.max(
            1,
            ((distanceMetersValue / 1000) / averageSpeedKmh * 60).ceil(),
          );

    return ActiveRideLiveMetrics(
      etaText: MeasurementFormatter.formatDurationMinutes(durationMinutes),
      distanceText: _formatDistanceMeters(distanceMetersValue),
      arrivalTimeText: _arrivalTimeFromMinutes(now, durationMinutes),
      lastUpdatedAt: now,
      source: ActiveRideLiveMetricsSource.approximate,
    );
  }

  static String _arrivalTimeFromMinutes(DateTime now, int durationMinutes) {
    return formatClockTime(now.add(Duration(minutes: durationMinutes)));
  }

  static String _formatDistanceMeters(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    final kilometers = meters / 1000;
    return '${kilometers.toStringAsFixed(1)} km';
  }

  static double _toRadians(double value) => value * (math.pi / 180);
}

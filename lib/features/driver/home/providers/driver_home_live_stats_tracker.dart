library;

import '../../../../domain/models/driver_ride.dart';
import 'driver_home_state.dart';

class DriverHomeLiveStatsTracker {
  final Map<String, DriverRide> _knownCompletedRides = {};
  DateTime? _currentDay;
  DateTime? _onlineSince;
  Duration _onlineDuration = Duration.zero;

  void clear() {
    _knownCompletedRides.clear();
    _currentDay = null;
    _onlineSince = null;
    _onlineDuration = Duration.zero;
  }

  void syncOnline(bool isOnline, {DateTime? now}) {
    final timestamp = now ?? DateTime.now();
    _resetIfNeeded(timestamp);
    if (isOnline) {
      _onlineSince ??= timestamp;
      return;
    }
    if (_onlineSince == null) {
      return;
    }
    _onlineDuration += timestamp.difference(_onlineSince!);
    _onlineSince = null;
  }

  void recordCompletedRide(DriverRide ride) {
    _knownCompletedRides[ride.rideId] = ride;
  }

  DriverHomeState applyTo(DriverHomeState state, {DateTime? now}) {
    final timestamp = now ?? DateTime.now();
    _resetIfNeeded(timestamp);
    final liveOnlineDuration =
        _onlineSince == null
        ? _onlineDuration
        : _onlineDuration + timestamp.difference(_onlineSince!);
    final knownCompletedRides = _sortedRides(_knownCompletedRides.values);
    final todayCompletedRides = knownCompletedRides
        .where((ride) => _isSameDay(_rideDate(ride), _currentDay!))
        .toList();
    final todayEarnings = todayCompletedRides.fold<double>(
      0,
      (sum, ride) => sum + (ride.finalPrice ?? ride.estimatedPrice),
    );
    return state.copyWith(
      todayEarnings: todayEarnings,
      todayRideCount: todayCompletedRides.length,
      todayOnlineHours: liveOnlineDuration.inSeconds / Duration.secondsPerHour,
      todayCompletedRides: todayCompletedRides,
      knownCompletedRides: knownCompletedRides,
    );
  }

  void _resetIfNeeded(DateTime timestamp) {
    final day = DateTime(timestamp.year, timestamp.month, timestamp.day);
    if (_currentDay == null) {
      _currentDay = day;
      return;
    }
    if (_isSameDay(day, _currentDay!)) {
      return;
    }
    _onlineDuration = Duration.zero;
    _onlineSince = _onlineSince == null ? null : timestamp;
    _currentDay = day;
  }

  List<DriverRide> _sortedRides(Iterable<DriverRide> rides) {
    return rides.toList()
      ..sort((left, right) => _rideDate(right).compareTo(_rideDate(left)));
  }

  DateTime _rideDate(DriverRide ride) {
    return ride.updatedAt ?? ride.createdAt ?? DateTime(1970);
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}

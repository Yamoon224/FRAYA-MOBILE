library;

import '../../../../domain/models/driver_ride.dart';

class DriverHistoryDaySection {
  const DriverHistoryDaySection({
    required this.day,
    required this.title,
    required this.rides,
  });

  final DateTime day;
  final String title;
  final List<DriverRide> rides;
}

library;

class DriverEarningsSummary {
  const DriverEarningsSummary({
    required this.completedRideCount,
    required this.totalEarnings,
    required this.totalCommission,
    required this.totalNetEarnings,
    required this.totalTripMinutes,
    required this.averagePerRide,
    required this.earningsPerTripHour,
  });

  final int completedRideCount;
  final double totalEarnings;
  final double totalCommission;
  final double totalNetEarnings;
  final int totalTripMinutes;
  final double averagePerRide;
  final double earningsPerTripHour;
}

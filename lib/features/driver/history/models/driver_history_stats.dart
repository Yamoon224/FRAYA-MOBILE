library;

class DriverHistoryStats {
  const DriverHistoryStats({
    required this.completedRideCount,
    required this.earnings,
    required this.averageRating,
    required this.ratedRideCount,
  });

  final int completedRideCount;
  final double earnings;
  final double averageRating;
  final int ratedRideCount;

  bool get hasRating => ratedRideCount > 0;

  String get ratingLabel => hasRating ? averageRating.toStringAsFixed(1) : '--';
}

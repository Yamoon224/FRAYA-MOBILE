class UserStatsViewData {
  const UserStatsViewData({this.rating, this.ridesCount});

  final double? rating;
  final int? ridesCount;

  static const UserStatsViewData empty = UserStatsViewData();

  int get starCount {
    if (rating == null) return 0;
    return rating!.round().clamp(0, 5).toInt();
  }

  bool get hasRating => rating != null;
  bool get hasRidesCount => ridesCount != null;

  String get ratingLabel => hasRating ? rating!.toStringAsFixed(1) : '--';
  String get ridesCountLabel => hasRidesCount ? ridesCount.toString() : '--';

  factory UserStatsViewData.fromMap(
    Map<String, dynamic>? map, {
    List<String> ratingKeys = const ['rating'],
    List<String> ridesCountKeys = const [
      'driverCoursesCount',
      'totalCourses',
      'coursesCount',
      'ridesCount',
    ],
  }) {
    if (map == null) return empty;
    return UserStatsViewData(
      rating: _parseDouble(map, ratingKeys),
      ridesCount: _parseInt(map, ridesCountKeys),
    );
  }

  static double? _parseDouble(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static int? _parseInt(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }
}

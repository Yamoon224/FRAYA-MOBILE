import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/shared/models/user_stats_view_data.dart';

void main() {
  group('UserStatsViewData', () {
    test('parses rating and rides count from canonical keys', () {
      final stats = UserStatsViewData.fromMap({
        'rating': 4.6,
        'coursesCount': 120,
      });

      expect(stats.rating, 4.6);
      expect(stats.ridesCount, 120);
      expect(stats.ratingLabel, '4.6');
      expect(stats.ridesCountLabel, '120');
      expect(stats.starCount, 5);
    });

    test('returns neutral labels when values are missing', () {
      const stats = UserStatsViewData.empty;

      expect(stats.rating, isNull);
      expect(stats.ridesCount, isNull);
      expect(stats.ratingLabel, '--');
      expect(stats.ridesCountLabel, '--');
      expect(stats.starCount, 0);
    });

    test('handles string numeric values and clamps stars to range', () {
      final stats = UserStatsViewData.fromMap({
        'rating': '7.2',
        'ridesCount': '42',
      });

      expect(stats.rating, 7.2);
      expect(stats.ridesCount, 42);
      expect(stats.starCount, 5);
    });
  });
}

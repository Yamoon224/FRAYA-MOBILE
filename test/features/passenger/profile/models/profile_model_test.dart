import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/features/passenger/profile/models/profile_model.dart';

void main() {
  group('PassengerProfile.fromMap', () {
    test('parses nested backend payload and photo url', () {
      final profile = PassengerProfile.fromMap({
        'data': {
          'firstNames': 'Awa',
          'lastName': 'Kone',
          'phoneNumber': '+2250700000000',
          'email': 'awa@example.com',
          'rating': 4.7,
          'totalCourses': 18,
          'coursesCount': 12,
          'createdAt': '2024-01-08T10:00:00.000Z',
          'profilePhoto': '/uploads/awa.jpg',
        },
      });

      expect(profile.name, 'Awa Kone');
      expect(profile.phone, '+2250700000000');
      expect(profile.email, 'awa@example.com');
      expect(profile.rating, 4.7);
      expect(profile.ridesCount, 18);
      expect(profile.photoUrl, '/uploads/awa.jpg');
    });

    test('formats membership duration as days, months, then years', () {
      final now = DateTime.now();
      final daysProfile = PassengerProfile.fromMap({
        'createdAt': now
            .subtract(const Duration(days: 15, hours: 1))
            .toIso8601String(),
      });
      final monthsProfile = PassengerProfile.fromMap({
        'createdAt': DateTime(
          now.year,
          now.month - 3,
          1,
          now.hour,
        ).toIso8601String(),
      });
      final yearsProfile = PassengerProfile.fromMap({
        'createdAt': DateTime(
          now.year - 2,
          now.month,
          1,
          now.hour,
        ).toIso8601String(),
      });

      expect(daysProfile.membershipDurationValue, 15);
      expect(daysProfile.membershipDurationUnitLabel, 'Jours');
      expect(monthsProfile.membershipDurationValue, 3);
      expect(monthsProfile.membershipDurationUnitLabel, 'Mois');
      expect(yearsProfile.membershipDurationValue, 2);
      expect(yearsProfile.membershipDurationUnitLabel, 'Ans');
    });

    test('falls back to an empty safe profile', () {
      final profile = PassengerProfile.empty();

      expect(profile.name, 'Utilisateur');
      expect(profile.phone, '');
      expect(profile.email, '');
      expect(profile.rating, isNull);
      expect(profile.ridesCount, isNull);
      expect(profile.photoUrl, isNull);
    });
  });
}

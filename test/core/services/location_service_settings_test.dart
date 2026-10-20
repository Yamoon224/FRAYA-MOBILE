import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/services/location_service.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  group('LocationService.positionSettings', () {
    test("iPhone chauffeur : la position continue en arrière-plan", () {
      final settings = LocationService.positionSettings(isIOS: true, isDriver: true);

      expect(settings, isA<AppleSettings>());
      final apple = settings as AppleSettings;
      expect(apple.allowBackgroundLocationUpdates, isTrue);
      expect(apple.pauseLocationUpdatesAutomatically, isFalse);
      expect(apple.showBackgroundLocationIndicator, isTrue);
      expect(apple.activityType, ActivityType.automotiveNavigation);
      expect(apple.distanceFilter, 5);
    });

    test("iPhone passager : pas de position en arrière-plan", () {
      final settings = LocationService.positionSettings(isIOS: true, isDriver: false);

      expect(settings, isNot(isA<AppleSettings>()));
      expect(settings.distanceFilter, 5);
    });

    test("Android : réglages standard (le service de premier plan s'en charge)", () {
      final driver = LocationService.positionSettings(isIOS: false, isDriver: true);
      final passenger = LocationService.positionSettings(isIOS: false, isDriver: false);

      expect(driver, isNot(isA<AppleSettings>()));
      expect(passenger, isNot(isA<AppleSettings>()));
      expect(driver.accuracy, LocationAccuracy.high);
    });
  });
}

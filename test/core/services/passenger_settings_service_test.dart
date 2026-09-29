import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/services/passenger_settings_service.dart';
import 'package:fraya_mobile/data/sources/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('PassengerSettingsService local preferences', () {
    late PassengerSettingsService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await LocalStorage.instance.init();
      service = PassengerSettingsService();
    });

    test('stores and reads language', () async {
      expect(await service.getLanguage(), 'fr');

      await service.setLanguage('en');

      expect(await service.getLanguage(), 'en');
    });

    test('stores and reads dark mode toggle', () async {
      expect(await service.isDarkModeEnabled(), isFalse);

      await service.setDarkModeEnabled(true);

      expect(await service.isDarkModeEnabled(), isTrue);
    });

    test('stores and reads sounds toggle', () async {
      expect(await service.isSoundsEnabled(), isTrue);

      await service.setSoundsEnabled(false);

      expect(await service.isSoundsEnabled(), isFalse);
    });
  });
}

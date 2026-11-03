import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fraya_mobile/core/services/app_update_service.dart';

void main() {
  group('compareVersions', () {
    test('reconnaît une version plus récente, identique ou plus ancienne', () {
      expect(compareVersions('1.0.6', '1.0.5'), greaterThan(0));
      expect(compareVersions('1.1.0', '1.0.9'), greaterThan(0));
      expect(compareVersions('2.0', '1.9.9'), greaterThan(0));
      expect(compareVersions('1.0.5', '1.0.5'), 0);
      expect(compareVersions('1.0', '1.0.0'), 0);
      expect(compareVersions('1.0.4', '1.0.5'), lessThan(0));
    });

    test('ignore le numéro de build après le +', () {
      expect(compareVersions('1.0.5+16', '1.0.5+15'), 0);
    });

    test('compare les nombres et non les chaînes (1.0.10 > 1.0.9)', () {
      expect(compareVersions('1.0.10', '1.0.9'), greaterThan(0));
    });
  });

  group('rappel « Plus tard »', () {
    const update = AvailableUpdate(storeVersion: '1.0.6');
    final base = DateTime(2026, 11, 3, 10);

    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('propose la mise à jour tant que rien n\'a été repoussé', () async {
      expect(await AppUpdateService().shouldPrompt(update), isTrue);
    });

    test('ne repropose pas la même version avant 24 h', () async {
      final service = AppUpdateService();
      await service.snooze(update, now: base);
      expect(
        await service.shouldPrompt(update, now: base.add(const Duration(hours: 23))),
        isFalse,
      );
      expect(
        await service.shouldPrompt(update, now: base.add(const Duration(hours: 24))),
        isTrue,
      );
    });

    test('repropose tout de suite une version encore plus récente', () async {
      final service = AppUpdateService();
      await service.snooze(update, now: base);
      expect(
        await service.shouldPrompt(
          const AvailableUpdate(storeVersion: '1.0.7'),
          now: base.add(const Duration(hours: 1)),
        ),
        isTrue,
      );
    });
  });
}

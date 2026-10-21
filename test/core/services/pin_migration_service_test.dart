import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/services/pin_migration_service.dart';
import 'package:fraya_mobile/data/sources/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late DateTime now;
  late PinMigrationService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await LocalStorage.instance.init();
    now = DateTime(2026, 10, 21, 10);
    service = PinMigrationService(now: () => now);
  });

  test('session ouverte avant la mise à jour : statut inconnu, on pose la question', () {
    expect(service.status, PinMigrationStatus.unknown);
    expect(service.shouldPrompt(), isTrue);
  });

  test('connexion avec un ancien mot de passe : statut ancien format, invitation directe', () async {
    await service.recordLogin('Secret123');

    expect(service.status, PinMigrationStatus.legacy);
    expect(service.shouldPrompt(), isTrue);
  });

  test('connexion avec 4 chiffres : rien à proposer', () async {
    await service.recordLogin('4821');

    expect(service.status, PinMigrationStatus.done);
    expect(service.shouldPrompt(), isFalse);
  });

  test('inscription ou changement réussi : plus aucune invitation', () async {
    await service.recordLogin('Secret123');
    await service.markDone();

    expect(service.shouldPrompt(), isFalse);
  });

  test('Plus tard : on attend une semaine, puis on repose la question', () async {
    await service.recordLogin('Secret123');
    await service.snooze();

    expect(service.shouldPrompt(), isFalse);
    now = now.add(const Duration(days: 6, hours: 23));
    expect(service.shouldPrompt(), isFalse);
    now = now.add(const Duration(hours: 2));
    expect(service.shouldPrompt(), isTrue);
  });

  test('après trois Plus tard, on cesse de demander', () async {
    await service.recordLogin('Secret123');
    for (var i = 0; i < PinMigrationService.maxSnoozes; i += 1) {
      await service.snooze();
      now = now.add(PinMigrationService.snoozeDelay + const Duration(minutes: 1));
    }

    expect(service.shouldPrompt(), isFalse);
  });

  test("une nouvelle connexion repart de zéro pour l'utilisateur suivant", () async {
    await service.recordLogin('4821');
    await service.recordLogin('Secret123');

    expect(service.status, PinMigrationStatus.legacy);
    expect(service.shouldPrompt(), isTrue);
  });
}

library;

import '../../data/sources/local_storage.dart';
import '../utils/password_policy.dart';

/// Où en est l'utilisateur de cet appareil dans le passage au mot de passe à 4 chiffres.
enum PinMigrationStatus {
  /// Rien n'est connu (session ouverte avant la mise à jour) : on lui pose la question.
  unknown,

  /// Il s'est connecté avec un mot de passe qui n'a pas 4 chiffres : on le lui propose directement.
  legacy,

  /// Il utilise déjà un code à 4 chiffres, ou a répondu qu'il n'a rien à changer.
  done,
}

/// Mémorise localement (jamais le mot de passe lui-même) si l'utilisateur doit être invité à passer à un
/// code à 4 chiffres, et gère les « Plus tard ».
class PinMigrationService {
  PinMigrationService({LocalStorage? storage, DateTime Function()? now})
    : _storage = storage ?? LocalStorage.instance,
      _now = now ?? DateTime.now;

  static const String statusKey = 'pin_migration_status';
  static const String snoozeUntilKey = 'pin_migration_snooze_until';
  static const String snoozeCountKey = 'pin_migration_snooze_count';

  /// Délai avant de reposer la question après « Plus tard ».
  static const Duration snoozeDelay = Duration(days: 7);

  /// Après ce nombre de « Plus tard », on cesse de demander.
  static const int maxSnoozes = 3;

  final LocalStorage _storage;
  final DateTime Function() _now;

  PinMigrationStatus get status {
    if (!_storage.isInitialized) return PinMigrationStatus.unknown;
    return switch (_storage.getString(statusKey)) {
      'legacy' => PinMigrationStatus.legacy,
      'done' => PinMigrationStatus.done,
      _ => PinMigrationStatus.unknown,
    };
  }

  /// Une aide facultative ne doit jamais faire échouer une connexion ou une inscription.
  Future<void> _safely(Future<void> Function() action) async {
    if (!_storage.isInitialized) return;
    try {
      await action();
    } catch (_) {}
  }

  /// À appeler après une connexion réussie : le mot de passe saisi dit si le compte est déjà à 4 chiffres.
  Future<void> recordLogin(String typedPassword) => _safely(() async {
    await _storage.remove(snoozeUntilKey);
    await _storage.remove(snoozeCountKey);
    await _storage.setString(
      statusKey,
      PasswordPolicy.isValidNew(typedPassword) ? 'done' : 'legacy',
    );
  });

  /// Un code à 4 chiffres vient d'être créé ou choisi (inscription, changement de mot de passe).
  Future<void> markDone() => _safely(() async {
    await _storage.setString(statusKey, 'done');
  });

  /// « Plus tard » : on repose la question dans une semaine, trois fois au plus.
  Future<void> snooze() => _safely(() async {
    final count = (_storage.getInt(snoozeCountKey) ?? 0) + 1;
    await _storage.setInt(snoozeCountKey, count);
    await _storage.setInt(
      snoozeUntilKey,
      _now().add(snoozeDelay).millisecondsSinceEpoch,
    );
  });

  /// Faut-il proposer la transition maintenant ?
  bool shouldPrompt() {
    if (!_storage.isInitialized) return false;
    if (status == PinMigrationStatus.done) return false;
    if ((_storage.getInt(snoozeCountKey) ?? 0) >= maxSnoozes) return false;
    final until = _storage.getInt(snoozeUntilKey);
    return until == null || _now().millisecondsSinceEpoch >= until;
  }
}

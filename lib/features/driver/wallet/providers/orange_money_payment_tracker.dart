library;

import 'dart:async';

import '../../../../domain/models/orange_money_payment.dart';

/// Interroge le serveur jusqu'à ce que le paiement Orange Money soit confirmé, refusé, ou que
/// le délai soit écoulé (résultat [OrangeMoneyPaymentStatus.pending]).
class OrangeMoneyPaymentTracker {
  OrangeMoneyPaymentTracker({
    required this.check,
    required this.onOutcome,
    this.interval = const Duration(seconds: 3),
    this.timeout = const Duration(minutes: 5),
  });

  final Future<OrangeMoneyPaymentStatus> Function() check;
  final void Function(OrangeMoneyPaymentStatus outcome) onOutcome;
  final Duration interval;
  final Duration timeout;

  Timer? _poller;
  Timer? _deadline;
  bool _checking = false;
  bool _finished = false;

  bool get isFinished => _finished;

  void start() {
    if (_finished || _poller != null) return;
    _poller = Timer.periodic(interval, (_) => pollNow());
    _deadline = Timer(timeout, () => _finish(OrangeMoneyPaymentStatus.pending));
  }

  /// Vérification immédiate, sans attendre le prochain tour (ex. retour sur la page de statut).
  Future<void> pollNow() async {
    if (_finished || _checking) return;
    _checking = true;
    try {
      final status = await check();
      if (status != OrangeMoneyPaymentStatus.pending) _finish(status);
    } catch (_) {
      // Réseau instable : on réessaie au prochain tour.
    } finally {
      _checking = false;
    }
  }

  void _finish(OrangeMoneyPaymentStatus outcome) {
    if (_finished) return;
    _finished = true;
    dispose();
    onOutcome(outcome);
  }

  void dispose() {
    _poller?.cancel();
    _deadline?.cancel();
    _poller = null;
    _deadline = null;
  }
}

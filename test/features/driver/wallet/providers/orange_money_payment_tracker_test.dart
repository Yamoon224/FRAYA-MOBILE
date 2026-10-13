import 'dart:async';

import 'package:fake_async/fake_async.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/domain/models/orange_money_payment.dart';
import 'package:fraya_mobile/features/driver/wallet/providers/orange_money_payment_tracker.dart';

void main() {
  late List<OrangeMoneyPaymentStatus> outcomes;

  setUp(() => outcomes = []);

  OrangeMoneyPaymentTracker build(
    Future<OrangeMoneyPaymentStatus> Function() check, {
    Duration timeout = const Duration(minutes: 5),
  }) => OrangeMoneyPaymentTracker(
    check: check,
    onOutcome: outcomes.add,
    interval: const Duration(seconds: 3),
    timeout: timeout,
  );

  test('stops and reports success as soon as the server confirms', () {
    fakeAsync((async) {
      var calls = 0;
      final tracker = build(() async {
        calls++;
        return calls < 3
            ? OrangeMoneyPaymentStatus.pending
            : OrangeMoneyPaymentStatus.success;
      })..start();

      async.elapse(const Duration(seconds: 9));
      expect(outcomes, [OrangeMoneyPaymentStatus.success]);
      expect(calls, 3);

      async.elapse(const Duration(seconds: 30));
      expect(calls, 3, reason: 'plus aucune interrogation après la conclusion');
      expect(tracker.isFinished, isTrue);
    });
  });

  test('reports a refused payment', () {
    fakeAsync((async) {
      build(() async => OrangeMoneyPaymentStatus.failed).start();
      async.elapse(const Duration(seconds: 3));
      expect(outcomes, [OrangeMoneyPaymentStatus.failed]);
    });
  });

  test('gives up as pending after the timeout', () {
    fakeAsync((async) {
      build(
        () async => OrangeMoneyPaymentStatus.pending,
        timeout: const Duration(seconds: 20),
      ).start();
      async.elapse(const Duration(seconds: 25));
      expect(outcomes, [OrangeMoneyPaymentStatus.pending]);
    });
  });

  test('keeps polling after a network error', () {
    fakeAsync((async) {
      var calls = 0;
      build(() async {
        calls++;
        if (calls == 1) throw Exception('offline');
        return OrangeMoneyPaymentStatus.success;
      }).start();
      async.elapse(const Duration(seconds: 6));
      expect(outcomes, [OrangeMoneyPaymentStatus.success]);
    });
  });

  test('never runs two checks at the same time', () {
    fakeAsync((async) {
      var running = 0;
      var maxRunning = 0;
      final completer = Completer<OrangeMoneyPaymentStatus>();
      build(() {
        running++;
        if (running > maxRunning) maxRunning = running;
        return completer.future.whenComplete(() => running--);
      }).start();

      async.elapse(const Duration(seconds: 12));
      expect(maxRunning, 1);

      completer.complete(OrangeMoneyPaymentStatus.success);
      async.flushMicrotasks();
      expect(outcomes, [OrangeMoneyPaymentStatus.success]);
    });
  });

  test('pollNow checks immediately without waiting for the next tick', () {
    fakeAsync((async) {
      final tracker = build(() async => OrangeMoneyPaymentStatus.success)
        ..start();
      tracker.pollNow();
      async.flushMicrotasks();
      expect(outcomes, [OrangeMoneyPaymentStatus.success]);
    });
  });

  test('reports the outcome only once', () {
    fakeAsync((async) {
      final tracker = build(() async => OrangeMoneyPaymentStatus.success)
        ..start();
      tracker.pollNow();
      tracker.pollNow();
      async.elapse(const Duration(minutes: 10));
      expect(outcomes, hasLength(1));
    });
  });

  test('dispose stops all polling', () {
    fakeAsync((async) {
      var calls = 0;
      final tracker = build(() async {
        calls++;
        return OrangeMoneyPaymentStatus.pending;
      })..start();
      async.elapse(const Duration(seconds: 3));
      tracker.dispose();
      final before = calls;
      async.elapse(const Duration(minutes: 10));
      expect(calls, before);
      expect(outcomes, isEmpty);
    });
  });
}

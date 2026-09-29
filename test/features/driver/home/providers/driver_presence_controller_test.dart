import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/services/driver_presence_background_service.dart';
import 'package:fraya_mobile/domain/repositories/driver_status_repository.dart';
import 'package:fraya_mobile/domain/usecases/driver/status/send_driver_heartbeat.dart';
import 'package:fraya_mobile/domain/usecases/driver/status/update_driver_status.dart';
import 'package:fraya_mobile/features/driver/home/providers/driver_presence_controller.dart';

void main() {
  group('DriverPresenceController', () {
    late _RecordingDriverStatusRepository repository;
    late _RecordingBackgroundService backgroundService;
    late DriverPresenceController controller;

    setUp(() {
      repository = _RecordingDriverStatusRepository();
      backgroundService = _RecordingBackgroundService();
      controller = DriverPresenceController(
        sendHeartbeatUseCase: SendDriverHeartbeatUseCase(repository),
        updateStatusUseCase: UpdateDriverStatusUseCase(repository),
        backgroundService: backgroundService,
        heartbeatInterval: const Duration(milliseconds: 20),
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test(
      'starts background presence and sends heartbeat immediately',
      () async {
        await controller.syncOnline(true);

        expect(backgroundService.startCalls, 1);
        expect(repository.heartbeatCalls, 1);
      },
    );

    test('sends periodic heartbeats while online', () async {
      await controller.syncOnline(true);
      await Future<void>.delayed(const Duration(milliseconds: 55));

      expect(repository.heartbeatCalls, greaterThanOrEqualTo(3));
    });

    test('stops heartbeat and background presence when offline', () async {
      await controller.syncOnline(true);
      await controller.syncOnline(false);
      final callsAfterStop = repository.heartbeatCalls;
      await Future<void>.delayed(const Duration(milliseconds: 45));

      expect(backgroundService.stopCalls, 1);
      expect(repository.heartbeatCalls, callsAfterStop);
    });

    test('does not overlap heartbeat requests', () async {
      repository.heartbeatCompleter = Completer<void>();

      final firstSignal = controller.syncOnline(true);
      await Future<void>.delayed(const Duration(milliseconds: 45));

      expect(repository.heartbeatCalls, 1);
      repository.heartbeatCompleter!.complete();
      await firstSignal;
    });

    test('reenters online pool after a failed heartbeat', () async {
      repository.heartbeatFailuresRemaining = 1;

      await controller.syncOnline(true);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(repository.onlineValues, [true]);
      expect(repository.heartbeatCalls, greaterThanOrEqualTo(2));
    });

    test('reasserts online presence and heartbeat on resume', () async {
      await controller.syncOnline(true);

      await controller.handleAppResumed();

      expect(repository.onlineValues, [true]);
      expect(repository.heartbeatCalls, 2);
      expect(backgroundService.startCalls, 2);
    });

    test('detached stops service without clearing online intent', () async {
      await controller.syncOnline(true);
      await controller.handleAppDetached();
      final callsAfterDetach = repository.heartbeatCalls;
      await Future<void>.delayed(const Duration(milliseconds: 45));

      expect(backgroundService.stopCalls, 1);
      expect(repository.heartbeatCalls, callsAfterDetach);

      await controller.handleAppResumed();
      expect(repository.onlineValues, [true]);
      expect(repository.heartbeatCalls, callsAfterDetach + 1);
    });
  });
}

class _RecordingDriverStatusRepository implements DriverStatusRepository {
  final List<bool> onlineValues = [];
  int heartbeatCalls = 0;
  int heartbeatFailuresRemaining = 0;
  Completer<void>? heartbeatCompleter;

  @override
  Future<void> updateStatus({required bool isOnline}) async {
    onlineValues.add(isOnline);
  }

  @override
  Future<void> sendHeartbeat() async {
    heartbeatCalls++;
    if (heartbeatFailuresRemaining > 0) {
      heartbeatFailuresRemaining--;
      throw Exception('heartbeat failed');
    }
    await heartbeatCompleter?.future;
  }
}

class _RecordingBackgroundService implements DriverPresenceBackgroundService {
  int startCalls = 0;
  int stopCalls = 0;

  @override
  Future<void> start() async {
    startCalls++;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }
}

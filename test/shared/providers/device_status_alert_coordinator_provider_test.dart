import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/config/app_config.dart';
import 'package:fraya_mobile/core/config/app_flavor.dart';
import 'package:fraya_mobile/shared/models/auth_state.dart';
import 'package:fraya_mobile/shared/models/device_status_snapshot.dart';
import 'package:fraya_mobile/shared/providers/device_status_alert_coordinator_provider.dart';
import 'package:fraya_mobile/shared/providers/device_status_alert_visibility_provider.dart';
import 'package:fraya_mobile/shared/providers/device_status_provider.dart';
import 'package:fraya_mobile/shared/providers/main_app_zone_provider.dart';
import 'package:fraya_mobile/shared/providers/top_alerts_provider.dart';
import 'package:fraya_mobile/shared/widgets/global_app_alert_listener.dart';

final _testPassengerAuthStatusProvider = StateProvider<AuthStatus>(
  (ref) => AuthStatus.authenticated,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  DeviceStatusSnapshot snapshot(DeviceIssue issue) {
    return DeviceStatusSnapshot(
      issue: issue,
      title: issue == DeviceIssue.none ? '' : 'Connexion internet',
      message: issue == DeviceIssue.none ? '' : 'Pas de connexion internet.',
      checkedAt: DateTime(2026, 7, 14),
    );
  }

  test('passenger visibility does not depend on main app zone', () {
    AppConfig.instance.init(flavor: AppFlavor.passenger);
    final container = ProviderContainer(
      overrides: [
        passengerDeviceStatusAlertAuthProvider.overrideWithValue(
          AuthStatus.authenticated,
        ),
        mainAppZoneProvider.overrideWith((ref) => false),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(deviceStatusAlertVisibilityProvider), isTrue);
  });

  test('passenger visibility is disabled outside an authenticated session', () {
    AppConfig.instance.init(flavor: AppFlavor.passenger);
    final container = ProviderContainer(
      overrides: [
        passengerDeviceStatusAlertAuthProvider.overrideWithValue(
          AuthStatus.unauthenticated,
        ),
        mainAppZoneProvider.overrideWith((ref) => true),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(deviceStatusAlertVisibilityProvider), isFalse);
  });

  test('driver visibility still follows main app zone', () {
    AppConfig.instance.init(flavor: AppFlavor.driver);
    final container = ProviderContainer(
      overrides: [mainAppZoneProvider.overrideWith((ref) => false)],
    );
    addTearDown(container.dispose);

    expect(container.read(deviceStatusAlertVisibilityProvider), isFalse);
    container.read(mainAppZoneProvider.notifier).state = true;
    expect(container.read(deviceStatusAlertVisibilityProvider), isTrue);
  });

  test('coordinator shows and clears the device alert', () async {
    final statuses = StreamController<DeviceStatusSnapshot>();
    addTearDown(statuses.close);
    final container = ProviderContainer(
      overrides: [
        deviceStatusAlertVisibilityProvider.overrideWithValue(true),
        deviceStatusProvider.overrideWith((ref) => statuses.stream),
      ],
    );
    addTearDown(container.dispose);
    final alertsSubscription = container.listen(topAlertsProvider, (_, _) {});
    final coordinatorSubscription = container.listen(
      deviceStatusAlertCoordinatorProvider,
      (_, _) {},
    );
    addTearDown(alertsSubscription.close);
    addTearDown(coordinatorSubscription.close);

    statuses.add(snapshot(DeviceIssue.noInternet));
    await _flushEvents();
    expect(container.read(topAlertsProvider), hasLength(1));

    statuses.add(snapshot(DeviceIssue.none));
    await _flushEvents();
    expect(container.read(topAlertsProvider), isEmpty);
  });

  test('coordinator clears alerts when passenger session ends', () async {
    AppConfig.instance.init(flavor: AppFlavor.passenger);
    final statuses = StreamController<DeviceStatusSnapshot>();
    addTearDown(statuses.close);
    final container = ProviderContainer(
      overrides: [
        passengerDeviceStatusAlertAuthProvider.overrideWith(
          (ref) => ref.watch(_testPassengerAuthStatusProvider),
        ),
        deviceStatusProvider.overrideWith((ref) => statuses.stream),
      ],
    );
    addTearDown(container.dispose);
    final alertsSubscription = container.listen(topAlertsProvider, (_, _) {});
    final coordinatorSubscription = container.listen(
      deviceStatusAlertCoordinatorProvider,
      (_, _) {},
    );
    addTearDown(alertsSubscription.close);
    addTearDown(coordinatorSubscription.close);

    statuses.add(snapshot(DeviceIssue.noInternet));
    await _flushEvents();
    expect(container.read(topAlertsProvider), hasLength(1));

    container.read(_testPassengerAuthStatusProvider.notifier).state =
        AuthStatus.unauthenticated;
    await _flushEvents();
    expect(container.read(topAlertsProvider), isEmpty);
  });

  testWidgets('global alert remains visible above an address modal', (
    tester,
  ) async {
    final statuses = StreamController<DeviceStatusSnapshot>();
    addTearDown(statuses.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deviceStatusAlertVisibilityProvider.overrideWithValue(true),
          deviceStatusProvider.overrideWith((ref) => statuses.stream),
        ],
        child: MaterialApp(
          builder: (context, child) =>
              GlobalAppAlertListener(child: child ?? const SizedBox.shrink()),
          home: const _AddressSearchHost(),
        ),
      ),
    );

    statuses.add(snapshot(DeviceIssue.noInternet));
    await tester.pump();
    await tester.pump();
    expect(find.text('Connexion internet'), findsOneWidget);

    await tester.tap(find.text('Rechercher une adresse'));
    await tester.pumpAndSettle();

    expect(find.text('Recherche d\'adresse'), findsOneWidget);
    expect(find.text('Connexion internet'), findsOneWidget);
  });
}

Future<void> _flushEvents() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _AddressSearchHost extends StatelessWidget {
  const _AddressSearchHost();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () {
            showModalBottomSheet<void>(
              context: context,
              builder: (_) => const Center(child: Text('Recherche d\'adresse')),
            );
          },
          child: const Text('Rechercher une adresse'),
        ),
      ),
    );
  }
}

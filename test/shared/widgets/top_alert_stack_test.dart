import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/shared/models/device_status_snapshot.dart';
import 'package:fraya_mobile/shared/models/top_alert_item.dart';
import 'package:fraya_mobile/shared/providers/top_alerts_provider.dart';
import 'package:fraya_mobile/shared/widgets/top_alert_stack.dart';

void main() {
  DeviceStatusSnapshot snapshotFor(
    DeviceIssue issue,
    String title,
    String message,
  ) {
    return DeviceStatusSnapshot(
      issue: issue,
      title: title,
      message: message,
      checkedAt: DateTime(2026, 5, 29),
    );
  }

  Future<void> pumpStack(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [TopAlertsStack(source: TopAlertSource.deviceStatus)],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders icon, title and description', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container
        .read(topAlertsProvider.notifier)
        .pushOrUpdateDeviceAlert(
          snapshotFor(
            DeviceIssue.noInternet,
            'Connexion internet',
            'Pas de connexion internet.',
          ),
        );

    await pumpStack(tester, container);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    expect(find.text('Connexion internet'), findsOneWidget);
    expect(find.text('Pas de connexion internet.'), findsOneWidget);
  });

  testWidgets('dismisses alert on horizontal swipe', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container
        .read(topAlertsProvider.notifier)
        .pushOrUpdateDeviceAlert(
          snapshotFor(
            DeviceIssue.noInternet,
            'Connexion internet',
            'Pas de connexion internet.',
          ),
        );

    await pumpStack(tester, container);
    await tester.pumpAndSettle();

    await tester.drag(find.text('Connexion internet'), const Offset(300, 0));
    await tester.pumpAndSettle();

    expect(container.read(topAlertsProvider), isEmpty);
  });

  testWidgets('dismisses alert on upward swipe', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container
        .read(topAlertsProvider.notifier)
        .pushOrUpdateDeviceAlert(
          snapshotFor(
            DeviceIssue.locationServiceOff,
            'Localisation',
            'La localisation est desactivee. Activez-la pour continuer.',
          ),
        );

    await pumpStack(tester, container);
    await tester.pumpAndSettle();

    await tester.fling(find.text('Localisation'), const Offset(0, -220), 900);
    await tester.pumpAndSettle();

    expect(container.read(topAlertsProvider), isEmpty);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';
import 'package:fraya_mobile/features/driver/earnings/screens/driver_earnings_screen.dart';
import 'package:fraya_mobile/features/driver/earnings/services/driver_earnings_export_service.dart';
import 'package:fraya_mobile/features/driver/home/providers/driver_ride_dependencies.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../../support/driver_test_doubles.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  testWidgets('renders empty earnings state', (tester) async {
    final repository = FakeDriverRideRepository()..historyRides = const [];

    await _pumpEarnings(tester, repository);

    expect(find.text('Mes recettes'), findsOneWidget);
    expect(
      find.text('Aucune course terminée aujourd\'hui pour cette vue.'),
      findsOneWidget,
    );
  });

  testWidgets('renders earnings with grouped completed rides', (tester) async {
    final now = DateTime.now();
    final repository = FakeDriverRideRepository()
      ..historyRides = [
        buildDriverRide(
          id: 'ride-today',
          status: RideStatus.completed,
          finalPrice: 4750,
          completedAt: now.subtract(const Duration(hours: 1)),
          estimatedDurationMin: 25,
        ),
        buildDriverRide(
          id: 'ride-week',
          status: RideStatus.completed,
          finalPrice: 3200,
          completedAt: now.subtract(const Duration(days: 6)),
          estimatedDurationMin: 20,
        ),
      ];

    await _pumpEarnings(tester, repository);

    expect(find.textContaining('Recettes de la'), findsOneWidget);
    expect(find.text('Temps en course'), findsOneWidget);
    expect(find.text('Gain / heure de course'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Alice Kouassi'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Alice Kouassi'), findsWidgets);
  });

  testWidgets('pull refresh reloads earnings and resets period to today', (
    tester,
  ) async {
    final repository = FakeDriverRideRepository()..historyRides = const [];

    await _pumpEarnings(tester, repository);

    expect(repository.historyRidesCalls, 1);

    await tester.tap(find.text('Semaine'));
    await tester.pumpAndSettle();

    expect(
      find.text('Aucune course terminée sur les 7 derniers jours.'),
      findsOneWidget,
    );

    await tester.drag(find.byType(Scrollable).first, const Offset(0, 360));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repository.historyRidesCalls, 2);
    expect(
      find.text('Aucune course terminée aujourd\'hui pour cette vue.'),
      findsOneWidget,
    );
  });

  testWidgets('export button shows confirmation with period totals', (
    tester,
  ) async {
    final now = DateTime.now();
    final repository = FakeDriverRideRepository()
      ..historyRides = [
        buildDriverRide(
          id: 'ride-export',
          status: RideStatus.completed,
          finalPrice: 4500,
          commissionPrice: 500,
          completedAt: now.subtract(const Duration(hours: 1)),
          estimatedDurationMin: 30,
        ),
      ];

    await _pumpEarnings(tester, repository);

    await tester.tap(find.byIcon(Icons.file_download_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Exporter les recettes'), findsOneWidget);
    expect(find.text('Période'), findsOneWidget);
    expect(find.text('Courses terminées'), findsOneWidget);
    expect(find.text('1'), findsWidgets);
    expect(find.text('Total brut'), findsOneWidget);
    expect(find.text('Commission Fraya'), findsWidgets);
    expect(find.text('Gain net'), findsWidgets);
    expect(find.text('Temps total en course'), findsOneWidget);
    expect(find.text('30 min'), findsOneWidget);
    expect(find.text(DriverEarningsExportService.disclaimer), findsOneWidget);
  });

  testWidgets('export button shows info when there are no filtered rides', (
    tester,
  ) async {
    final repository = FakeDriverRideRepository()..historyRides = const [];

    await _pumpEarnings(tester, repository);

    await tester.tap(find.byIcon(Icons.file_download_outlined));
    await tester.pumpAndSettle();

    expect(
      find.text('Aucune course terminée à exporter sur cette période.'),
      findsOneWidget,
    );
    expect(find.text('Exporter les recettes'), findsNothing);
  });

  testWidgets('stays responsive on narrow screens with long values', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final now = DateTime.now();
    final repository = FakeDriverRideRepository()
      ..historyRides = [
        buildDriverRide(
          id: 'ride-compact-1',
          status: RideStatus.completed,
          finalPrice: 16950,
          startedAt: now.subtract(const Duration(minutes: 45)),
          endedAt: now.subtract(const Duration(minutes: 20)),
          completedAt: now.subtract(const Duration(minutes: 20)),
          estimatedDurationMin: 1,
        ),
      ];

    await _pumpEarnings(tester, repository);

    await tester.scrollUntilVisible(
      find.text('Debut'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final startLabel = tester.getTopLeft(find.text('Debut'));
    final endLabel = tester.getTopLeft(find.text('Fin'));

    expect(find.text('Mes recettes'), findsOneWidget);
    expect((startLabel.dy - endLabel.dy).abs(), lessThanOrEqualTo(1));
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpEarnings(
  WidgetTester tester,
  FakeDriverRideRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [driverRideRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: DriverEarningsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

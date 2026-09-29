import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';
import 'package:fraya_mobile/features/driver/history/screens/driver_history_screen.dart';
import 'package:fraya_mobile/features/driver/home/providers/driver_ride_dependencies.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../../support/driver_test_doubles.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  testWidgets('renders empty driver history state', (tester) async {
    final repository = FakeDriverRideRepository()..historyRides = const [];

    await _pumpHistory(tester, repository);

    expect(find.text('Historique'), findsNWidgets(3));
    expect(find.textContaining('Aucune course termin'), findsOneWidget);
  });

  testWidgets('renders grouped history with cancelled badge and filters', (
    tester,
  ) async {
    final now = DateTime.now();
    final repository = FakeDriverRideRepository()
      ..historyRides = [
        buildDriverRide(
          id: 'ride-completed-today',
          status: RideStatus.completed,
          finalPrice: 4700,
          startedAt: now.subtract(const Duration(hours: 1, minutes: 20)),
          endedAt: now.subtract(const Duration(hours: 1)),
          completedAt: now.subtract(const Duration(hours: 1)),
          driverRatingFromPassenger: 5,
          passengerCommentForDriver: 'Trajet impeccable',
        ),
        buildDriverRide(
          id: 'ride-cancelled-yesterday',
          status: RideStatus.cancelled,
          startedAt: now.subtract(const Duration(days: 1, minutes: 15)),
          endedAt: now.subtract(const Duration(days: 1)),
          cancelledAt: now.subtract(const Duration(days: 1)),
        ),
      ];

    await _pumpHistory(tester, repository);
    await tester.tap(find.byKey(const ValueKey('driver-history-tab-1')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Annulee'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Annulee'), findsOneWidget);
    expect(find.text('Alice Kouassi'), findsWidgets);
    expect(find.text('Date de la course'), findsWidgets);
    expect(find.text('Debut'), findsWidgets);
    expect(find.text('Fin'), findsWidgets);
    expect(find.text('Avis reçu'), findsOneWidget);
    expect(find.text('"Trajet impeccable"'), findsOneWidget);
  });

  testWidgets('renders remote history error state', (tester) async {
    final repository = FakeDriverRideRepository()
      ..historyRidesError = const ServerException(message: 'Erreur historique');

    await _pumpHistory(tester, repository);

    expect(find.text('Erreur historique'), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
  });

  testWidgets('pull refresh reloads history and resets to today tab', (
    tester,
  ) async {
    final repository = FakeDriverRideRepository()..historyRides = const [];

    await _pumpHistory(tester, repository);

    expect(repository.historyRidesCalls, 1);

    await tester.tap(find.byKey(const ValueKey('driver-history-tab-1')));
    await tester.pumpAndSettle();

    expect(find.text('Filtrer par date'), findsOneWidget);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, 360));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repository.historyRidesCalls, 2);
    expect(find.textContaining('Aucune course termin'), findsOneWidget);
    expect(find.text('Filtrer par date'), findsNothing);
  });

  testWidgets('stays responsive on narrow screens with long card content', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final now = DateTime.now();
    final repository = FakeDriverRideRepository()
      ..historyRides = [
        buildDriverRide(
          id: 'ride-completed-compact',
          status: RideStatus.completed,
          finalPrice: 16950,
          startedAt: now.subtract(const Duration(hours: 1, minutes: 20)),
          endedAt: now.subtract(const Duration(hours: 1)),
          completedAt: now.subtract(const Duration(hours: 1)),
          estimatedDurationMin: 59,
        ),
      ];

    await _pumpHistory(tester, repository);
    await tester.scrollUntilVisible(
      find.text('Alice Kouassi'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final startLabel = tester.getTopLeft(find.text('Debut'));
    final endLabel = tester.getTopLeft(find.text('Fin'));

    expect(find.text('Historique'), findsWidgets);
    expect((startLabel.dy - endLabel.dy).abs(), lessThanOrEqualTo(1));
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpHistory(
  WidgetTester tester,
  FakeDriverRideRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [driverRideRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: DriverHistoryScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

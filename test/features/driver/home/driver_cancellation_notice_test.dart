import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/domain/models/driver_ride.dart';
import 'package:fraya_mobile/features/driver/home/providers/driver_cancellation_notice_provider.dart';
import 'package:fraya_mobile/features/driver/home/widgets/driver_cancellation_notice_banner.dart';

void main() {
  group('DriverCancellationNotice.cleanReason', () {
    test('garde un vrai motif et écarte le texte par défaut du serveur', () {
      expect(
        DriverCancellationNotice.cleanReason(' Prix trop élevé '),
        'Prix trop élevé',
      );
      expect(DriverCancellationNotice.cleanReason('Course annulée'), isNull);
      expect(DriverCancellationNotice.cleanReason('  '), isNull);
      expect(DriverCancellationNotice.cleanReason(null), isNull);
    });
  });

  group('DriverCancellationNoticeBanner', () {
    Future<ProviderContainer> pump(
      WidgetTester tester,
      DriverCancellationNotice? notice,
    ) async {
      final container = ProviderContainer(
        overrides: [
          driverCancellationNoticeProvider.overrideWith((ref) => notice),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: DriverCancellationNoticeBanner()),
          ),
        ),
      );
      return container;
    }

    testWidgets('rien à afficher sans annulation', (tester) async {
      await pump(tester, null);

      expect(find.byKey(const Key('driver_cancellation_notice')), findsNothing);
    });

    testWidgets('affiche le motif donné par le passager puis se ferme', (
      tester,
    ) async {
      final container = await pump(
        tester,
        DriverCancellationNotice(
          rideId: '5',
          reason: 'Prix trop élevé',
          at: DateTime(2026),
        ),
      );

      expect(find.text('Annulée par le passager'), findsOneWidget);
      expect(find.text('Motif : Prix trop élevé'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('driver_cancellation_notice_close')),
      );
      await tester.pump();

      expect(container.read(driverCancellationNoticeProvider), isNull);
      expect(find.byKey(const Key('driver_cancellation_notice')), findsNothing);
    });

    testWidgets('dit qu aucun motif n a été indiqué', (tester) async {
      await pump(
        tester,
        DriverCancellationNotice(rideId: '5', reason: null, at: DateTime(2026)),
      );

      expect(find.text('Aucun motif indiqué'), findsOneWidget);
    });
  });

  test(
    'le chronomètre d attente part de l heure d arrivée au point de départ envoyée par le serveur',
    () {
      final ride = DriverRide.fromMap({
        'id': 5,
        'statusRace': 'WAITING_FOR_PASSENGER',
        'pickupArrivedAt': '2026-10-23T12:00:00.000Z',
      });

      expect(ride.arrivedAt, DateTime.utc(2026, 10, 23, 12));
    },
  );
}

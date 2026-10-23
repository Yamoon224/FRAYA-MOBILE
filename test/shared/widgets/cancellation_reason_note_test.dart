import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/domain/models/driver_ride.dart';
import 'package:fraya_mobile/shared/widgets/cancellation_reason_note.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  testWidgets('affiche l auteur et le motif', (tester) async {
    await _pump(
      tester,
      const CancellationReasonNote(
        cancelledBy: 'PASSENGER',
        reason: 'Prix trop élevé',
      ),
    );

    expect(find.text('Annulée par le passager'), findsOneWidget);
    expect(find.text('Motif : Prix trop élevé'), findsOneWidget);
  });

  testWidgets('dit « vous » à celui qui a annulé', (tester) async {
    await _pump(
      tester,
      const CancellationReasonNote(
        cancelledBy: 'DRIVER',
        reason: 'Panne',
        viewer: CancellationViewer.driver,
      ),
    );

    expect(find.text('Annulée par vous'), findsOneWidget);
  });

  testWidgets('indique l absence de motif et l annulation automatique', (
    tester,
  ) async {
    await _pump(
      tester,
      const CancellationReasonNote(cancelledBy: 'SYSTEM', reason: '  '),
    );

    expect(find.text('Annulée automatiquement'), findsOneWidget);
    expect(find.text('Aucun motif indiqué'), findsOneWidget);
  });

  test('libellé neutre quand l auteur est inconnu', () {
    expect(CancellationReasonNote.authorLabel(null), 'Course annulée');
    expect(
      CancellationReasonNote.authorLabel('passenger'),
      'Annulée par le passager',
    );
  });

  test('DriverRide.fromMap lit le motif et l auteur', () {
    final ride = DriverRide.fromMap({
      'id': 12,
      'statusRace': 'CANCELLED_PASSENGER',
      'cancellationReason': 'Attente trop longue',
      'cancelledBy': 'PASSENGER',
    });

    expect(ride.cancellationReason, 'Attente trop longue');
    expect(ride.cancelledBy, 'PASSENGER');
    expect(
      ride.copyWith(passengerName: 'Awa').cancellationReason,
      'Attente trop longue',
    );
  });
}

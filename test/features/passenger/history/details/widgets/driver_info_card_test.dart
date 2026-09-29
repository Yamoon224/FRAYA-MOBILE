import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/models/ride_model.dart';
import 'package:fraya_mobile/features/passenger/history/details/widgets/driver_info_card.dart';

void main() {
  testWidgets('shows rating and comment received from the driver', (
    tester,
  ) async {
    final ride = Ride.fromMap({
      'id': 'ride-42',
      'departureAddress': 'Cocody',
      'arrivalAddress': 'Plateau',
      'finalPrice': 3000,
      'dateArrival': '2026-06-06T03:16:07.678Z',
      'statusRace': 'COMPLETED',
      'requestedRange': 'MAGIC',
      'passengerRating': 4,
      'passengerComment': 'Excellent passager',
      'driverRating': 0,
      'commentDriver': null,
      'vehicle': {
        'model': 'Dzire',
        'color': 'verte',
        'licensePlate': 'AA-126-AA',
        'sidUser': {'firstNames': 'Boris', 'lastName': 'Won', 'rating': 4.8},
      },
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: DriverInfoCard(ride: ride)),
        ),
      ),
    );

    expect(find.text('Note reçue du chauffeur'), findsOneWidget);
    expect(find.text('"Excellent passager"'), findsOneWidget);
    expect(find.text('Votre évaluation'), findsNothing);
    expect(find.text('Noter'), findsOneWidget);
  });

  testWidgets(
    'shows rating and comment given to the driver when already rated',
    (tester) async {
      final ride = Ride.fromMap({
        'id': 'ride-43',
        'departureAddress': 'Cocody',
        'arrivalAddress': 'Plateau',
        'finalPrice': 3000,
        'dateArrival': '2026-06-06T03:16:07.678Z',
        'statusRace': 'COMPLETED',
        'requestedRange': 'MAGIC',
        'passengerRating': 4,
        'passengerComment': 'Excellent passager',
        'driverRating': 5,
        'commentDriver': 'Merci pour le trajet',
        'vehicle': {
          'model': 'Dzire',
          'color': 'verte',
          'licensePlate': 'AA-126-AA',
          'sidUser': {'firstNames': 'Boris', 'lastName': 'Won', 'rating': 4.8},
        },
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: DriverInfoCard(ride: ride)),
          ),
        ),
      );

      expect(find.text('Votre note au chauffeur'), findsOneWidget);
      expect(find.text('"Merci pour le trajet"'), findsOneWidget);
      expect(find.text('Noter'), findsNothing);
    },
  );
}

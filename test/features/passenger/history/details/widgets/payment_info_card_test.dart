import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/models/ride_model.dart';
import 'package:fraya_mobile/features/passenger/history/details/widgets/payment_info_card.dart';

void main() {
  testWidgets('renders without overflow on narrow screens', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final ride = Ride(
      id: 'ride-1',
      departureAddress: 'Cocody',
      arrivalAddress: 'Plateau',
      price: 345678,
      date: DateTime(2026, 6, 2, 11, 14),
      status: RideStatus.completed,
      paymentMethod: 'CASH',
      transactionId: 'TRANS-VERY-LONG-001',
      vehicleRange: 'MAGIC',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: PaymentInfoCard(ride: ride),
          ),
        ),
      ),
    );

    expect(find.text('Paiement'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

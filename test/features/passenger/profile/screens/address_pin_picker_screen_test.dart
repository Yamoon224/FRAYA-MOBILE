import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/models/places_models.dart';
import 'package:fraya_mobile/features/passenger/profile/screens/address_pin_picker_screen.dart';

void main() {
  testWidgets('confirms and returns a place from pin picker', (tester) async {
    const initialPlace = PlaceDetails(
      placeId: 'place_1',
      name: 'KFC 8eme tranche',
      address: 'Rue 12, Cocody',
      latitude: 5.325,
      longitude: -4.01,
    );

    PlaceDetails? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<PlaceDetails>(
                    MaterialPageRoute(
                      builder: (_) =>
                          const AddressPinPickerScreen(initialPlace: initialPlace),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Position precise'), findsOneWidget);
    expect(find.text('Deplace la carte pour ajuster l\'adresse'), findsOneWidget);
    expect(find.byIcon(Icons.location_on_rounded), findsOneWidget);

    await tester.tap(find.text('Confirmer cette position'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.placeId, initialPlace.placeId);
    expect(result!.latitude, closeTo(initialPlace.latitude, 0.000001));
    expect(result!.longitude, closeTo(initialPlace.longitude, 0.000001));
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/pickup_map_edit_controller.dart';
import 'package:fraya_mobile/features/passenger/booking/widgets/pickup_edit_sheet_content.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  testWidgets('shows loading text while resolving address', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PickupEditSheetContent(
            title: 'Ajuster le point de prise en charge',
            state: const MapAddressEditState(
              isEditing: true,
              isResolvingAddress: true,
              draftLatLng: LatLng(5.31, -4.01),
            ),
            onConfirm: () {},
            onOpenTextSearch: () {},
            onCancel: () {},
          ),
        ),
      ),
    );

    expect(find.text('Recherche...'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Confirmer ce point'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('shows address and enables confirm once resolved', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PickupEditSheetContent(
            title: 'Ajuster le point de prise en charge',
            state: const MapAddressEditState(
              isEditing: true,
              isResolvingAddress: false,
              draftLatLng: LatLng(5.31, -4.01),
              draftAddress: 'Rue 12, Cocody',
            ),
            onConfirm: () {},
            onOpenTextSearch: () {},
            onCancel: () {},
          ),
        ),
      ),
    );

    expect(find.text('Rue 12, Cocody'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Confirmer ce point'),
    );
    expect(button.onPressed, isNotNull);
  });
}

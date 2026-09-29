import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/features/driver/vehicle/widgets/driver_vehicle_documents_section.dart';

void main() {
  testWidgets('shows all five vehicle photo selectors', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DriverVehicleDocumentsSection(
              documents: const {},
              enabled: true,
              onSelect: (_) {},
              onRemove: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Photo avant du véhicule'), findsOneWidget);
    expect(find.text('Photo arrière du véhicule'), findsOneWidget);
    expect(find.text('Photo côté gauche du véhicule'), findsOneWidget);
    expect(find.text('Photo côté droit du véhicule'), findsOneWidget);
    expect(find.text('Photo intérieure du véhicule'), findsOneWidget);
  });
}

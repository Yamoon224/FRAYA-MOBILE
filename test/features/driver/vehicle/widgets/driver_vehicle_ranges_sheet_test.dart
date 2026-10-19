import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/domain/repositories/driver_vehicle_repository.dart';
import 'package:fraya_mobile/features/driver/vehicle/providers/driver_vehicle_dependencies.dart';
import 'package:fraya_mobile/features/driver/vehicle/widgets/driver_vehicle_document_picker_tile.dart';
import 'package:fraya_mobile/features/driver/vehicle/widgets/driver_vehicle_ranges_sheet.dart';

class _NoopRepository implements DriverVehicleRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

Future<void> _pump(WidgetTester tester, {String? secondary}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        driverVehicleRepositoryProvider.overrideWithValue(_NoopRepository()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: DriverVehicleRangesSheet(
            vehicleId: 5,
            primaryRange: 'GLADIATEUR',
            secondaryRange: secondary,
          ),
        ),
      ),
    ),
  );
}

FilledButton _submitButton(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byType(FilledButton));

void main() {
  testWidgets("n'autorise aucun envoi tant que rien ne change", (tester) async {
    await _pump(tester, secondary: 'MAGIC');

    expect(find.text('Enregistrer'), findsOneWidget);
    expect(_submitButton(tester).onPressed, isNull);
    expect(find.byType(DriverVehicleDocumentPickerTile), findsNothing);
  });

  testWidgets('une gamme déjà couverte se modifie sans photos', (tester) async {
    await _pump(tester, secondary: 'MAGIC');

    await tester.tap(find.byKey(const ValueKey('secondary-range-none')));
    await tester.pump();

    expect(find.text('Enregistrer'), findsOneWidget);
    expect(_submitButton(tester).onPressed, isNotNull);
    expect(find.byType(DriverVehicleDocumentPickerTile), findsNothing);
  });

  testWidgets('une gamme supérieure demande cinq photos et une revue', (tester) async {
    await _pump(tester);

    await tester.tap(find.byKey(const ValueKey('secondary-range-ELITE')));
    await tester.pump();

    expect(find.text('Envoyer la demande'), findsOneWidget);
    expect(find.byType(DriverVehicleDocumentPickerTile), findsNWidgets(5));
    // Sans les cinq photos, la demande ne peut pas partir.
    expect(_submitButton(tester).onPressed, isNull);
    expect(find.textContaining('administrateur'), findsOneWidget);
  });

  testWidgets("la gamme principale n'est pas proposée comme seconde gamme", (tester) async {
    await _pump(tester);

    expect(find.byKey(const ValueKey('secondary-range-GLADIATEUR')), findsNothing);
    expect(find.byKey(const ValueKey('secondary-range-MAGIC')), findsOneWidget);
    expect(find.byKey(const ValueKey('secondary-range-ELITE')), findsOneWidget);
  });
}

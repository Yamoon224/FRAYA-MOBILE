import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/features/driver/profile/models/driver_profile_view_data.dart';
import 'package:fraya_mobile/features/driver/profile/widgets/driver_profile_vehicle_card.dart';

DriverProfileVehicleViewData _vehicle({String? secondaryRange}) =>
    DriverProfileVehicleViewData(
      name: 'Toyota Corolla',
      subtitle: '2022 - Rouge',
      plate: '12ERSTDFD',
      rangeLabel: 'Magic',
      range: 'MAGIC',
      secondaryRange: secondaryRange,
    );

Future<void> _pump(WidgetTester tester, Widget card) => tester.pumpWidget(
  MaterialApp(home: Scaffold(body: SingleChildScrollView(child: card))),
);

void main() {
  testWidgets('affiche la seconde gamme quand elle existe', (tester) async {
    await _pump(
      tester,
      DriverProfileVehicleCard(vehicle: _vehicle(secondaryRange: 'GLADIATEUR')),
    );

    expect(find.byKey(const ValueKey('vehicle-secondary-range-chip')), findsOneWidget);
  });

  testWidgets("n'affiche pas de seconde gamme quand il n'y en a pas", (tester) async {
    await _pump(tester, DriverProfileVehicleCard(vehicle: _vehicle()));

    expect(find.byKey(const ValueKey('vehicle-secondary-range-chip')), findsNothing);
    expect(find.byKey(const ValueKey('vehicle-manage-ranges')), findsNothing);
  });

  testWidgets('le bouton « Gérer mes gammes » ouvre la gestion', (tester) async {
    var opened = 0;
    await _pump(
      tester,
      DriverProfileVehicleCard(
        vehicle: _vehicle(),
        onManageRanges: () => opened++,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('vehicle-manage-ranges')));

    expect(opened, 1);
  });
}

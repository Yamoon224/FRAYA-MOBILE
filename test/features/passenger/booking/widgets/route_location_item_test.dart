import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/shared/widgets/route_location_item.dart';

void main() {
  testWidgets('renders long addresses without overflow on narrow screens', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 690));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RouteLocationItem(
            label: 'Point de depart',
            location:
                '83 Rue Bertin Konan Kouadio, Cocody, Abidjan, Cote dIvoire',
            icon: Icons.location_on,
            iconBackground: Color(0xFFDDF6EA),
            iconColor: Color(0xFF16A34A),
          ),
        ),
      ),
    );

    expect(find.text('Point de depart'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

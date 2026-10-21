import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fraya_mobile/features/driver/home/widgets/driver_route_polylines.dart';
import 'package:fraya_mobile/features/driver/home/widgets/driver_route_recenter_button.dart';
import 'package:fraya_mobile/features/driver/home/widgets/driver_route_summary_chip.dart';

const _points = [LatLng(5.30, -4.00), LatLng(5.31, -4.01), LatLng(5.32, -4.02)];

void main() {
  group('buildDriverRoutePolylines', () {
    test('ne dessine rien sans point', () {
      expect(buildDriverRoutePolylines(const []), isEmpty);
    });

    test('superpose un contour blanc sous le trait bleu', () {
      final polylines = buildDriverRoutePolylines(_points);
      expect(polylines, hasLength(2));

      final outline = polylines.firstWhere(
        (p) => p.polylineId.value == 'driver_active_ride_polyline_outline',
      );
      final main = polylines.firstWhere(
        (p) => p.polylineId.value == 'driver_active_ride_polyline',
      );
      expect(outline.color, driverRouteOutlineColor);
      expect(main.color, driverRouteColor);
      expect(outline.width, greaterThan(main.width));
      expect(outline.zIndex, lessThan(main.zIndex));
      expect(main.points, _points);
      expect(main.jointType, JointType.round);
    });
  });

  group('formatRouteDistance', () {
    test('affiche des mètres sous le kilomètre', () {
      expect(formatRouteDistance(0.45), '450 m');
    });

    test('affiche des kilomètres avec une virgule', () {
      expect(formatRouteDistance(2.34), '2,3 km');
      expect(formatRouteDistance(10), '10,0 km');
    });
  });

  group('DriverRouteSummaryChip', () {
    testWidgets("indique le client comme cible avant la prise en charge", (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: DriverRouteSummaryChip(isHeadingToPickup: true, minutes: 7, kilometers: 2.3),
        ),
      ));

      expect(find.text('Vers le client · 7 min · 2,3 km'), findsOneWidget);
    });

    testWidgets('indique la destination une fois la course commencée', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: DriverRouteSummaryChip(isHeadingToPickup: false, minutes: 18, kilometers: 0.8),
        ),
      ));

      expect(find.text('Vers la destination · 18 min · 800 m'), findsOneWidget);
    });
  });

  testWidgets('le bouton recentrer appelle son action', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: DriverRouteRecenterButton(onPressed: () => taps++)),
    ));

    await tester.tap(find.byType(IconButton));

    expect(taps, 1);
  });
}

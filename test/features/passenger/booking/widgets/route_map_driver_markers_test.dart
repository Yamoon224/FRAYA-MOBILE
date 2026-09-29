import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/domain/models/active_ride.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';
import 'package:fraya_mobile/features/passenger/booking/models/booking_flow_state.dart';
import 'package:fraya_mobile/features/passenger/booking/widgets/route_map_driver_markers.dart';
import 'package:fraya_mobile/features/passenger/map/providers/nearby_drivers_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  group('buildRouteMapDriverMarkers', () {
    final fallbackIcon = BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueYellow,
    );
    final nearby = [
      NearbyDriver(id: 'n1', location: const LatLng(5.34, -4.02), bearing: 45),
      NearbyDriver(id: 'n2', location: const LatLng(5.35, -4.03), bearing: 180),
    ];

    test('searching + active ride shows nearby only', () {
      final ride = ActiveRide.mock.copyWith(status: RideStatus.pending);
      final markers = buildRouteMapDriverMarkers(
        flowState: BookingFlowState.searching,
        ride: ride,
        nearbyDrivers: nearby,
        defaultDriverCarIcon: fallbackIcon,
        nearbyDriverIcons: const {},
      );

      expect(markers.map((m) => m.markerId.value), containsAll(['n1', 'n2']));
      expect(markers.map((m) => m.markerId.value), isNot(contains('driver')));
    });

    test('driverAssigned + active ride shows assigned driver only', () {
      final markers = buildRouteMapDriverMarkers(
        flowState: BookingFlowState.driverAssigned,
        ride: ActiveRide.mock.copyWith(status: RideStatus.accepted),
        nearbyDrivers: nearby,
        defaultDriverCarIcon: fallbackIcon,
        nearbyDriverIcons: const {},
      );

      expect(markers.map((m) => m.markerId.value), contains('driver'));
      expect(markers.length, 1);
      expect(markers.single.anchor, const Offset(0.5, 0.5));
    });

    test('routePreview without active ride shows nearby markers', () {
      final markers = buildRouteMapDriverMarkers(
        flowState: BookingFlowState.routePreview,
        ride: null,
        nearbyDrivers: nearby,
        defaultDriverCarIcon: fallbackIcon,
        nearbyDriverIcons: const {},
      );

      expect(markers.map((m) => m.markerId.value), containsAll(['n1', 'n2']));
      expect(markers.map((m) => m.markerId.value), isNot(contains('driver')));
    });

    test(
      'active ride uses shared default driver icon when no custom icon is ready',
      () {
        final markers = buildRouteMapDriverMarkers(
          flowState: BookingFlowState.inProgress,
          ride: ActiveRide.mock.copyWith(status: RideStatus.inProgress),
          nearbyDrivers: nearby,
          defaultDriverCarIcon: fallbackIcon,
          nearbyDriverIcons: const {},
        );

        expect(markers.single.markerId.value, 'driver');
        expect(markers.single.icon, fallbackIcon);
      },
    );
  });
}

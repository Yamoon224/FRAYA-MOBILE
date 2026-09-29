import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/features/passenger/booking/models/booking_flow_state.dart';
import 'package:fraya_mobile/features/passenger/booking/widgets/route_map_marker_policy.dart';

void main() {
  group('resolveDriverLayerMode', () {
    test('returns nearbyOnly in searching even when active ride exists', () {
      final mode = resolveDriverLayerMode(
        flowState: BookingFlowState.searching,
        hasActiveRide: true,
      );
      expect(mode, RouteMapDriverLayerMode.nearbyOnly);
    });

    test('returns activeRideOnly in driverAssigned when active ride exists', () {
      final mode = resolveDriverLayerMode(
        flowState: BookingFlowState.driverAssigned,
        hasActiveRide: true,
      );
      expect(mode, RouteMapDriverLayerMode.activeRideOnly);
    });
  });
}

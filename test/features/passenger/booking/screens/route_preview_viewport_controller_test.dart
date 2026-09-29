import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/models/places_models.dart';
import 'package:fraya_mobile/domain/models/active_ride.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';
import 'package:fraya_mobile/features/passenger/booking/models/booking_flow_state.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/active_ride_map_route_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_route_refresh_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/screens/route_preview_viewport_controller.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  test('auto-fit is requested only once for the same viewport context', () {
    final controller = RouteViewportController();
    const target = RouteViewportTarget(
      contextKey: 'booking:5.31,-4.01:5.25,-3.93',
      origin: LatLng(5.31, -4.01),
      destination: LatLng(5.25, -3.93),
    );

    expect(controller.syncTarget(target), isTrue);
    expect(controller.hasPendingAutoFit, isTrue);

    expect(controller.syncTarget(target), isFalse);
    expect(controller.hasPendingAutoFit, isTrue);

    controller.markProgrammaticCameraMove();
    expect(controller.hasPendingAutoFit, isFalse);
    expect(controller.showResetCameraButton, isFalse);
  });

  test(
    'manual camera movement shows reset button until a programmatic fit',
    () {
      final controller = RouteViewportController();
      const target = RouteViewportTarget(
        contextKey: 'booking:5.31,-4.01:5.25,-3.93',
        origin: LatLng(5.31, -4.01),
        destination: LatLng(5.25, -3.93),
      );

      controller.syncTarget(target);
      controller.markProgrammaticCameraMove();
      controller.handleCameraIdle();

      expect(controller.handleCameraMoveStarted(), isTrue);
      expect(controller.showResetCameraButton, isTrue);

      controller.markProgrammaticCameraMove();
      expect(controller.showResetCameraButton, isFalse);
      expect(controller.handleCameraIdle(), isFalse);
    },
  );

  test('active ride live origin updates do not trigger another auto-fit', () {
    final controller = RouteViewportController();
    const firstTarget = RouteViewportTarget(
      contextKey: 'active:RIDE-1:accepted:5.34,-4.02',
      origin: LatLng(5.30, -4.00),
      destination: LatLng(5.34, -4.02),
    );
    const refreshedTarget = RouteViewportTarget(
      contextKey: 'active:RIDE-1:accepted:5.34,-4.02',
      origin: LatLng(5.31, -4.01),
      destination: LatLng(5.34, -4.02),
    );

    expect(controller.syncTarget(firstTarget), isTrue);
    controller.markProgrammaticCameraMove();
    controller.handleCameraIdle();

    expect(controller.syncTarget(refreshedTarget), isFalse);
    expect(controller.hasPendingAutoFit, isFalse);
  });

  test('active ride status change triggers a new auto-fit context', () {
    final controller = RouteViewportController();
    const acceptedTarget = RouteViewportTarget(
      contextKey: 'active:RIDE-1:accepted:5.34,-4.02',
      origin: LatLng(5.30, -4.00),
      destination: LatLng(5.34, -4.02),
    );
    const arrivedTarget = RouteViewportTarget(
      contextKey: 'active:RIDE-1:arrived:5.34,-4.02',
      origin: LatLng(5.31, -4.01),
      destination: LatLng(5.34, -4.02),
    );

    expect(controller.syncTarget(acceptedTarget), isTrue);
    controller.markProgrammaticCameraMove();
    controller.handleCameraIdle();

    expect(controller.syncTarget(arrivedTarget), isTrue);
    expect(controller.hasPendingAutoFit, isTrue);
  });

  test(
    'resolved active ride viewport key stays stable across driver location refreshes',
    () {
      final ride = ActiveRide.mock.copyWith(
        rideId: 'RIDE-1',
        status: RideStatus.accepted,
      );
      const firstQuery = ActiveRideMapRouteQuery(
        rideId: 'RIDE-1',
        target: ActiveRideMapRouteTarget.pickup,
        origin: LatLng(5.30, -4.00),
        destination: LatLng(5.34, -4.02),
      );
      const refreshedQuery = ActiveRideMapRouteQuery(
        rideId: 'RIDE-1',
        target: ActiveRideMapRouteTarget.pickup,
        origin: LatLng(5.31, -4.01),
        destination: LatLng(5.34, -4.02),
      );

      final firstTarget = resolveRoutePreviewViewportTarget(
        flowState: BookingFlowState.driverAssigned,
        bookingDirections: null,
        pickup: null,
        destination: null,
        originSnapshot: null,
        position: null,
        activeRide: ride,
        activeRideRouteQuery: firstQuery,
      );
      final refreshedTarget = resolveRoutePreviewViewportTarget(
        flowState: BookingFlowState.driverAssigned,
        bookingDirections: null,
        pickup: null,
        destination: null,
        originSnapshot: null,
        position: null,
        activeRide: ride,
        activeRideRouteQuery: refreshedQuery,
      );

      expect(firstTarget?.contextKey, refreshedTarget?.contextKey);
      expect(firstTarget?.origin, isNot(refreshedTarget?.origin));
    },
  );

  test(
    'in-progress active ride uses ride context and destination for viewport',
    () {
      final target = resolveRoutePreviewViewportTarget(
        flowState: BookingFlowState.inProgress,
        bookingDirections: null,
        pickup: _pickup,
        destination: _destination,
        originSnapshot: BookingOriginSnapshot(
          latitude: 5.30,
          longitude: -4.00,
          capturedAt: DateTime(2026),
        ),
        position: _position(latitude: 5.32, longitude: -4.03),
        activeRide: ActiveRide.mock.copyWith(
          rideId: 'RIDE-42',
          status: RideStatus.inProgress,
          pickupLocation: const LatLng(5.31, -4.01),
          destinationLocation: const LatLng(5.25, -3.93),
        ),
        activeRideRouteQuery: const ActiveRideMapRouteQuery(
          rideId: 'RIDE-42',
          target: ActiveRideMapRouteTarget.destination,
          origin: LatLng(5.29, -3.97),
          destination: LatLng(5.25, -3.93),
        ),
      );

      expect(target, isNotNull);
      expect(target?.contextKey, 'active:RIDE-42:inProgress:5.25,-3.93');
      expect(target?.origin, const LatLng(5.29, -3.97));
      expect(target?.destination, const LatLng(5.25, -3.93));
    },
  );

  test('in-progress live origin updates keep the viewport context stable', () {
    final controller = RouteViewportController();
    const firstTarget = RouteViewportTarget(
      contextKey: 'active:RIDE-42:inProgress:5.25,-3.93',
      origin: LatLng(5.29, -3.97),
      destination: LatLng(5.25, -3.93),
    );
    const refreshedTarget = RouteViewportTarget(
      contextKey: 'active:RIDE-42:inProgress:5.25,-3.93',
      origin: LatLng(5.28, -3.96),
      destination: LatLng(5.25, -3.93),
    );

    expect(controller.syncTarget(firstTarget), isTrue);
    controller.markProgrammaticCameraMove();
    controller.handleCameraIdle();

    expect(controller.syncTarget(refreshedTarget), isFalse);
    expect(controller.hasPendingAutoFit, isFalse);
  });
}

const _pickup = PlaceDetails(
  placeId: 'pickup',
  name: 'Pickup',
  address: 'Pickup',
  latitude: 5.31,
  longitude: -4.01,
);

const _destination = PlaceDetails(
  placeId: 'destination',
  name: 'Destination',
  address: 'Destination',
  latitude: 5.25,
  longitude: -3.93,
);

Position _position({required double latitude, required double longitude}) {
  return Position(
    longitude: longitude,
    latitude: latitude,
    timestamp: DateTime.now(),
    accuracy: 1,
    altitude: 1,
    altitudeAccuracy: 1,
    heading: 1,
    headingAccuracy: 1,
    speed: 1,
    speedAccuracy: 1,
  );
}

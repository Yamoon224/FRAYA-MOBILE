import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/models/directions_models.dart';
import '../../../../core/models/places_models.dart';
import '../../../../domain/models/ride_status.dart';
import '../../../../shared/providers/map_icons_provider.dart';
import '../../../../shared/widgets/map/fraya_map.dart';
import '../../map/providers/nearby_drivers_provider.dart';
import '../providers/booking_provider.dart';
import 'route_map_address_markers.dart';
import 'route_map_driver_markers.dart';
import 'route_map_polyline_builder.dart';

class RouteMapSection extends ConsumerStatefulWidget {
  const RouteMapSection({
    super.key,
    required this.directionsAsync,
    required this.position,
    required this.pickup,
    required this.destination,
    required this.onMapCreated,
    this.onPickupMarkerTap,
    this.onDestinationMarkerTap,
    this.onCameraMoveStarted,
    this.onCameraMove,
    this.onCameraIdle,
  });

  final AsyncValue<DirectionsResult?> directionsAsync;
  final Position? position;
  final PlaceDetails? pickup;
  final PlaceDetails? destination;
  final Function(GoogleMapController) onMapCreated;
  final void Function(LatLng)? onPickupMarkerTap;
  final void Function(LatLng)? onDestinationMarkerTap;
  final VoidCallback? onCameraMoveStarted;
  final void Function(CameraPosition)? onCameraMove;
  final VoidCallback? onCameraIdle;

  @override
  ConsumerState<RouteMapSection> createState() => _RouteMapSectionState();
}

class _RouteMapSectionState extends ConsumerState<RouteMapSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _posAnim;
  LatLng? _animFrom;
  LatLng? _animTo;
  double _bearingFrom = 0;
  double _bearingTo = 0;

  @override
  void initState() {
    super.initState();
    _posAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..addListener(_onAnimTick);
  }

  @override
  void dispose() {
    _posAnim.dispose();
    super.dispose();
  }

  void _onAnimTick() => setState(() {});

  // [prev] = position précédente connue (depuis le provider), utilisée comme
  // point de départ quand aucune animation n'est encore en cours.
  void _onNewDriverPosition({required LatLng? prev, required LatLng next}) {
    // Priorité : position interpolée en cours > position précédente > next (immobile)
    final current =
        (_animFrom != null ? _interpolatedPos : null) ?? prev ?? next;
    if ((current.latitude - next.latitude).abs() < 1e-7 &&
        (current.longitude - next.longitude).abs() < 1e-7) {
      return;
    }
    _bearingFrom = _interpolatedBearing;
    _bearingTo = _geodesicBearing(current, next);
    _animFrom = current;
    _animTo = next;
    _posAnim.forward(from: 0.0);
  }

  LatLng? get _interpolatedPos {
    final from = _animFrom;
    final to = _animTo;
    if (from == null || to == null) return to;
    final t = Curves.easeInOut.transform(_posAnim.value);
    return LatLng(
      lerpDouble(from.latitude, to.latitude, t)!,
      lerpDouble(from.longitude, to.longitude, t)!,
    );
  }

  double get _interpolatedBearing {
    if (_posAnim.value == 0) return _bearingFrom;
    final t = Curves.easeInOut.transform(_posAnim.value);
    var diff = _bearingTo - _bearingFrom;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    return (_bearingFrom + diff * t + 360) % 360;
  }

  static double _geodesicBearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * math.pi / 180;
    final lat2 = to.latitude * math.pi / 180;
    final dLng = (to.longitude - from.longitude) * math.pi / 180;
    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  FrayaMap _buildMap({
    required Set<Marker> markers,
    Set<Polyline> polylines = const {},
    LatLng? initialTarget,
    double? initialZoom,
    bool myLocationEnabled = true,
    bool autoCenterOnUser = true,
  }) {
    return FrayaMap(
      markers: markers,
      polylines: polylines,
      onMapCreated: widget.onMapCreated,
      initialTarget: initialTarget,
      initialZoom: initialZoom ?? 12.0,
      padding: const EdgeInsets.only(bottom: 400),
      trafficEnabled: false,
      myLocationEnabled: myLocationEnabled,
      autoCenterOnUser: autoCenterOnUser,
      onCameraMoveStarted: widget.onCameraMoveStarted,
      onCameraMove: widget.onCameraMove,
      onCameraIdle: widget.onCameraIdle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ride = ref.watch(activeRideControllerProvider);
    final nearbyDrivers = ref.watch(nearbyDriversProvider);
    final flowState = ref.watch(bookingFlowProvider);
    final pickupIcon = ref.watch(pickupMarkerIconProvider).asData?.value;
    final destinationIcon =
        ref.watch(destinationMarkerIconProvider).asData?.value;
    final activeRideRoute = ref.watch(activeRideMapRouteProvider);
    final activeRideRouteQuery = activeRideRoute.query;
    final isRideInProgress =
        flowState == BookingFlowState.inProgress &&
        ride?.status == RideStatus.inProgress;
    final activeRideColorRaw = ride?.carColor;
    final defaultDriverCarIcon =
        ref.watch(driverCarSvgIconProvider(null)).asData?.value ??
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
    final activeRideDriverIcon = ref
        .watch(driverCarSvgIconProvider(activeRideColorRaw))
        .asData
        ?.value;
    final nearbyDriverIcons = <String, BitmapDescriptor>{};
    for (final driver in nearbyDrivers) {
      final icon = ref
          .watch(driverCarSvgIconProvider(driver.vehicleColorRaw))
          .asData
          ?.value;
      if (icon != null) nearbyDriverIcons[driver.id] = icon;
    }

    // Démarrer l'animation dès qu'une nouvelle position driver arrive.
    // [prev] est passé pour servir de point de départ à la 1re animation.
    ref.listen(
      activeRideControllerProvider.select((r) => r?.driverLocation),
      (prev, next) {
        if (next != null) _onNewDriverPosition(prev: prev, next: next);
      },
    );

    final animatedPos = _interpolatedPos ?? ride?.driverLocation;
    final animatedBearing = _interpolatedBearing;

    final baseMarkers = <Marker>{
      ...buildRouteMapDriverMarkers(
        flowState: flowState,
        ride: ride,
        nearbyDrivers: nearbyDrivers,
        defaultDriverCarIcon: defaultDriverCarIcon,
        nearbyDriverIcons: nearbyDriverIcons,
        activeRideDriverIcon: activeRideDriverIcon,
        overrideDriverPosition: animatedPos,
        overrideDriverBearing: animatedBearing,
      ),
    };

    if (activeRideRouteQuery != null) {
      final markers = <Marker>{...baseMarkers};
      final target = activeRideRouteQuery.destination;
      final targetsDestination =
          activeRideRouteQuery.target == ActiveRideMapRouteTarget.destination;
      markers.add(
        Marker(
          markerId: MarkerId(
            targetsDestination
                ? 'active_ride_destination'
                : 'active_ride_pickup',
          ),
          position: target,
          icon: targetsDestination
              ? destinationIcon ??
                    BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed,
                    )
              : pickupIcon ??
                    BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen,
                    ),
          anchor: const Offset(0.5, 1),
        ),
      );
      final directions = activeRideRoute.directions;
      final routePoints = directions == null || directions.routes.isEmpty
          ? const <LatLng>[]
          : directions.mainRoute.getPolylinePoints();
      final polylines = <Polyline>{
        if (routePoints.isNotEmpty)
          Polyline(
            polylineId: const PolylineId('active_ride_route'),
            points: routePoints,
            color: const Color(0xFF4285F4),
            width: 6,
            zIndex: 1,
          ),
      };
      final centerLat =
          (activeRideRouteQuery.origin.latitude +
              activeRideRouteQuery.destination.latitude) /
          2;
      final centerLng =
          (activeRideRouteQuery.origin.longitude +
              activeRideRouteQuery.destination.longitude) /
          2;
      return _buildMap(
        markers: markers,
        polylines: polylines,
        initialTarget: LatLng(centerLat, centerLng),
        initialZoom: 7.5,
        myLocationEnabled: !isRideInProgress,
        autoCenterOnUser: !isRideInProgress,
      );
    }

    if (isRideInProgress) {
      return _buildMap(
        markers: baseMarkers,
        myLocationEnabled: false,
        autoCenterOnUser: false,
      );
    }

    return widget.directionsAsync.when(
      data: (directions) {
        final polylines = <Polyline>{};
        final markers = <Marker>{...baseMarkers};
        final originLatLng = widget.pickup != null
            ? LatLng(widget.pickup!.latitude, widget.pickup!.longitude)
            : widget.position != null
            ? LatLng(widget.position!.latitude, widget.position!.longitude)
            : null;
        final destLatLng = widget.destination != null
            ? LatLng(widget.destination!.latitude, widget.destination!.longitude)
            : null;

        if (directions != null && originLatLng != null && destLatLng != null) {
          final route = directions.mainRoute;
          polylines.addAll(buildPrimaryRoutePolylines(route));

          if (polylines.isNotEmpty) {
            addRouteAddressMarkers(
              markers: markers,
              origin: originLatLng,
              destination: destLatLng,
              pickupIcon: pickupIcon,
              destinationIcon: destinationIcon,
              onPickupTap: widget.onPickupMarkerTap,
              onDestinationTap: widget.onDestinationMarkerTap,
            );

            final centerLat =
                (originLatLng.latitude + destLatLng.latitude) / 2;
            final centerLng =
                (originLatLng.longitude + destLatLng.longitude) / 2;

            return _buildMap(
              markers: markers,
              polylines: polylines,
              initialTarget: LatLng(centerLat, centerLng),
              initialZoom: 6.0,
            );
          }
        }

        addRouteAddressMarkers(
          markers: markers,
          origin: originLatLng,
          destination: destLatLng,
          pickupIcon: pickupIcon,
          destinationIcon: destinationIcon,
          onPickupTap: widget.onPickupMarkerTap,
          onDestinationTap: widget.onDestinationMarkerTap,
        );

        return _buildMap(markers: markers);
      },
      loading: () => _buildMap(markers: baseMarkers),
      error: (_, _) => _buildMap(markers: baseMarkers),
    );
  }
}

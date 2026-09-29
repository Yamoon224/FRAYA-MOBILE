library;

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/models/directions_models.dart';
import '../../../../core/utils/vehicle_ui_utils.dart';
import '../../../../domain/models/driver_ride.dart';
import '../../../../domain/models/ride_status.dart';
import '../providers/driver_home_map_route_provider.dart';
import '../../../../shared/providers/map_icons_provider.dart';
import '../../../../shared/widgets/map/fraya_map.dart';
import 'driver_home_map_backdrop.dart';
import 'driver_home_map_route_policy.dart';

class DriverHomeMapStage extends ConsumerStatefulWidget {
  const DriverHomeMapStage({
    super.key,
    this.bottomPadding = 0,
    required this.driverMarkerColor,
    this.driverMarkerPosition,
    this.driverMarkerHeading,
    this.activeRide,
    this.forceStaticBackdrop = false,
  });

  final double bottomPadding;
  final Color driverMarkerColor;
  final LatLng? driverMarkerPosition;
  final double? driverMarkerHeading;
  final DriverRide? activeRide;
  final bool forceStaticBackdrop;

  @override
  ConsumerState<DriverHomeMapStage> createState() => _DriverHomeMapStageState();
}

class _DriverHomeMapStageState extends ConsumerState<DriverHomeMapStage>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  DriverHomeMapRouteQuery? _routeQuery;
  String? _lastFittedRouteKey;
  DateTime? _lastRouteRefreshAt;
  double _currentBearing = 0;
  LatLng? _prevMarkerPosition;

  late final AnimationController _posAnim;
  LatLng? _animFrom;
  LatLng? _animTo;

  @override
  void initState() {
    super.initState();
    _posAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addListener(_onAnimTick);
    _syncRouteQuery();
  }

  @override
  void dispose() {
    _posAnim.dispose();
    super.dispose();
  }

  void _onAnimTick() => setState(() {});

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

  void _syncPositionAnimation(DriverHomeMapStage oldWidget) {
    final prev = oldWidget.driverMarkerPosition;
    final next = widget.driverMarkerPosition;
    if (next == null) return;
    if (prev == null ||
        (prev.latitude == next.latitude && prev.longitude == next.longitude)) {
      return;
    }
    _animFrom = (_posAnim.isAnimating ? _interpolatedPos : null) ?? prev;
    _animTo = next;
    _posAnim.forward(from: 0.0);
  }

  @override
  void didUpdateWidget(covariant DriverHomeMapStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPositionAnimation(oldWidget);
    _syncBearing(oldWidget);
    _syncRouteQuery();
  }

  void _syncBearing(DriverHomeMapStage oldWidget) {
    // Priorité 1 : heading GPS du device (pos.heading de geolocator)
    final heading = widget.driverMarkerHeading;
    if (heading != null && heading >= 0) {
      _currentBearing = heading;
      _prevMarkerPosition = widget.driverMarkerPosition;
      return;
    }
    // Priorité 2 : bearing géodésique calculé depuis le delta de position
    final prev = _prevMarkerPosition ?? oldWidget.driverMarkerPosition;
    final next = widget.driverMarkerPosition;
    if (prev != null && next != null &&
        (prev.latitude != next.latitude || prev.longitude != next.longitude)) {
      _currentBearing = _geodesicBearing(prev, next);
    }
    _prevMarkerPosition = next;
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

  @override
  Widget build(BuildContext context) {
    if (widget.forceStaticBackdrop || _isWidgetTestEnvironment()) {
      return const DriverHomeMapBackdrop(key: Key('driver_home_live_map'));
    }

    final markerIcon = widget.driverMarkerPosition == null
        ? null
        : ref
              .watch(driverCarMarkerIconProvider(widget.driverMarkerColor))
              .asData
              ?.value;
    final targetPinIcon = ref
        .watch(
          _isHeadingToPickup
              ? pickupMarkerIconProvider
              : destinationMarkerIconProvider,
        )
        .asData
        ?.value;
    final fallbackIcon = BitmapDescriptor.defaultMarkerWithHue(
      VehicleUiUtils.markerHueFromColor(widget.driverMarkerColor),
    );

    final markers = <Marker>{
      if (widget.driverMarkerPosition != null)
        Marker(
          markerId: const MarkerId('driver_vehicle_marker'),
          position: _interpolatedPos ?? widget.driverMarkerPosition!,
          icon: markerIcon ?? fallbackIcon,
          rotation: _currentBearing,
          flat: true,
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 3,
        ),
      if (_activeRouteDestination != null)
        Marker(
          markerId: const MarkerId('driver_route_target_marker'),
          position: _activeRouteDestination!,
          icon:
              targetPinIcon ??
              BitmapDescriptor.defaultMarkerWithHue(
                _isHeadingToPickup
                    ? BitmapDescriptor.hueRed
                    : BitmapDescriptor.hueOrange,
              ),
          anchor: const Offset(0.5, 1),
          zIndexInt: 2,
        ),
    };

    final routeAsync = _routeQuery == null
        ? const AsyncData<DirectionsResult?>(null)
        : ref.watch(driverHomeMapRouteProvider(_routeQuery!));
    final route = routeAsync.asData?.value?.mainRoute;
    final routePoints = route?.getPolylinePoints() ?? const <LatLng>[];

    final polylines = <Polyline>{
      if (_shouldShowActiveRoute && routePoints.isNotEmpty)
        Polyline(
          polylineId: const PolylineId('driver_active_ride_polyline'),
          points: routePoints,
          color: const Color(0xFF16A34A),
          width: 6,
          geodesic: true,
          zIndex: 1,
        ),
    };

    if (_shouldShowActiveRoute && routePoints.isNotEmpty) {
      _scheduleFitRoute(routePoints, markers);
    } else if (!_shouldShowActiveRoute) {
      _lastFittedRouteKey = null;
    }

    return FrayaMap(
      key: const Key('driver_home_live_map'),
      padding: EdgeInsets.only(bottom: widget.bottomPadding),
      markers: markers,
      polylines: polylines,
      myLocationButtonEnabled: true,
      compassEnabled: true,
      showLoadingSkeleton: false,
      onMapCreated: (controller) {
        setState(() {
          _mapController = controller;
          _lastFittedRouteKey = null;
        });
      },
      initialTarget: widget.driverMarkerPosition ?? _activeRouteDestination,
      autoCenterOnUser: !_shouldShowActiveRoute,
    );
  }

  bool get _shouldShowActiveRoute {
    final ride = widget.activeRide;
    return ride != null && _activeRouteDestination != null;
  }

  bool get _isHeadingToPickup {
    final ride = widget.activeRide;
    return ride != null &&
        (ride.status == RideStatus.accepted ||
            ride.status == RideStatus.arrived);
  }

  LatLng? get _activeRouteDestination {
    final ride = widget.activeRide;
    if (ride == null || widget.driverMarkerPosition == null) return null;
    if (ride.status == RideStatus.accepted ||
        ride.status == RideStatus.arrived) {
      return ride.pickupLocation;
    }
    if (ride.status == RideStatus.inProgress) {
      return ride.destinationLocation;
    }
    return null;
  }

  void _syncRouteQuery() {
    final destination = _activeRouteDestination;
    if (destination == null || widget.driverMarkerPosition == null) {
      if (_routeQuery != null) {
        setState(() {
          _routeQuery = null;
          _lastRouteRefreshAt = null;
        });
      }
      return;
    }

    final next = DriverHomeMapRouteQuery(
      origin: widget.driverMarkerPosition!,
      destination: destination,
    );
    final previous = _routeQuery;
    if (previous == null || _shouldRefreshRoute(previous, next)) {
      setState(() {
        _routeQuery = next;
        _lastRouteRefreshAt = DateTime.now();
      });
    }
  }

  bool _shouldRefreshRoute(
    DriverHomeMapRouteQuery previous,
    DriverHomeMapRouteQuery next,
  ) {
    return DriverHomeMapRoutePolicy.shouldRefreshRoute(
      previousOrigin: previous.origin,
      previousDestination: previous.destination,
      nextOrigin: next.origin,
      nextDestination: next.destination,
      lastRefreshAt: _lastRouteRefreshAt,
    );
  }

  void _scheduleFitRoute(List<LatLng> routePoints, Set<Marker> markers) {
    final destination = _activeRouteDestination;
    final ride = widget.activeRide;
    if (destination == null || ride == null) {
      return;
    }
    final key = DriverHomeMapRoutePolicy.buildViewportKey(
      destination: destination,
      rideStatus: ride.status,
    );
    if (_lastFittedRouteKey == key) {
      return;
    }
    _lastFittedRouteKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitRouteOnMap(routePoints, markers);
    });
  }

  Future<void> _fitRouteOnMap(
    List<LatLng> routePoints,
    Set<Marker> markers,
  ) async {
    final controller = _mapController;
    if (controller == null) return;

    final points = <LatLng>[...routePoints, ...markers.map((m) => m.position)];
    if (points.isEmpty) return;

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final point in points.skip(1)) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    try {
      await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 72));
    } catch (_) {
      // Ignore transient map sizing errors.
      _lastFittedRouteKey = null;
    }
  }

  bool _isWidgetTestEnvironment() {
    final bindingName = WidgetsBinding.instance.runtimeType.toString();
    return !kReleaseMode && bindingName.contains('TestWidgetsFlutterBinding');
  }
}

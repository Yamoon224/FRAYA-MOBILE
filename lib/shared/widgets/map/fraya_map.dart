import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fraya_mobile/shared/widgets/fraya_skeleton.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../providers/location_provider.dart';
import 'fraya_map_style.dart';

class FrayaMap extends ConsumerStatefulWidget {
  const FrayaMap({
    super.key,
    this.polylines = const {},
    this.markers = const {},
    this.onMapCreated,
    this.initialTarget,
    this.initialZoom = 16.0,
    this.padding = EdgeInsets.zero,
    this.trafficEnabled = true,
    this.myLocationEnabled = true,
    this.myLocationButtonEnabled = false,
    this.compassEnabled = false,
    this.autoCenterOnUser = true,
    this.showLoadingSkeleton = true,
    this.onCameraMoveStarted,
    this.onCameraMove,
    this.onCameraIdle,
    this.mapStyle,
    this.userPosition,
  });

  final Set<Polyline> polylines;
  final Set<Marker> markers;
  final void Function(GoogleMapController)? onMapCreated;
  final LatLng? initialTarget;
  final double initialZoom;
  final EdgeInsets padding;
  final bool trafficEnabled;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final bool compassEnabled;
  final bool autoCenterOnUser;
  final bool showLoadingSkeleton;
  final VoidCallback? onCameraMoveStarted;
  final void Function(CameraPosition)? onCameraMove;
  final VoidCallback? onCameraIdle;
  final String? mapStyle;
  final Position? userPosition;

  @override
  ConsumerState<FrayaMap> createState() => _FrayaMapState();
}

class _FrayaMapState extends ConsumerState<FrayaMap> {
  GoogleMapController? _controller;
  bool _hasCentredInitially = false;
  bool _isMapReady = false;

  static const LatLng _defaultPosition = LatLng(5.3167, -4.0167);

  @override
  void didUpdateWidget(covariant FrayaMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.autoCenterOnUser) return;

    final previous = oldWidget.userPosition;
    final next = widget.userPosition;
    if (next == null || _controller == null) return;

    final hasChanged =
        previous == null ||
        previous.latitude != next.latitude ||
        previous.longitude != next.longitude;
    if (!hasChanged) return;

    _centreCamera(LatLng(next.latitude, next.longitude));
    _hasCentredInitially = true;
  }

  @override
  Widget build(BuildContext context) {
    if (_isWidgetTestEnvironment()) {
      return const ColoredBox(
        key: Key('fraya_google_map_test_placeholder'),
        color: Color(0xFFEFF2F5),
      );
    }

    final hasRealtimeLocation = ref.watch(
      currentLocationProvider.select((value) => value.asData?.value != null),
    );
    final hasLocation = widget.userPosition != null || hasRealtimeLocation;

    if (widget.userPosition == null) {
      ref.listen(currentLocationProvider, (previous, next) {
        if (!widget.autoCenterOnUser) return;

        final pos = next.asData?.value;
        if (pos != null && _controller != null && !_hasCentredInitially) {
          _centreCamera(LatLng(pos.latitude, pos.longitude));
          _hasCentredInitially = true;
        }
      });
    }

    final currentPos =
        widget.userPosition ?? ref.read(currentLocationProvider).asData?.value;
    final LatLng target =
        widget.initialTarget ??
        (currentPos != null
            ? LatLng(currentPos.latitude, currentPos.longitude)
            : _defaultPosition);

    return Stack(
      children: [
        GoogleMap(
          key: const Key('fraya_google_map'),
          initialCameraPosition: CameraPosition(
            target: target,
            zoom: widget.initialZoom,
          ),
          style: widget.mapStyle ??
              (Theme.of(context).brightness == Brightness.dark
                  ? frayaMapDarkStyle
                  : frayaMapDefaultStyle),
          myLocationEnabled: widget.myLocationEnabled && hasLocation,
          myLocationButtonEnabled: widget.myLocationButtonEnabled,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: widget.compassEnabled,
          polylines: widget.polylines,
          markers: widget.markers,
          trafficEnabled: widget.trafficEnabled,
          padding: widget.padding,
          onCameraMoveStarted: widget.onCameraMoveStarted,
          onCameraMove: widget.onCameraMove,
          onCameraIdle: widget.onCameraIdle,
          onMapCreated: (controller) {
            _controller = controller;

            if (widget.onMapCreated != null) widget.onMapCreated!(controller);

            if (widget.autoCenterOnUser &&
                currentPos != null &&
                !_hasCentredInitially) {
              _centreCamera(LatLng(currentPos.latitude, currentPos.longitude));
              _hasCentredInitially = true;
            }

            setState(() {
              _isMapReady = true;
            });
          },
        ),
        if (!_isMapReady && widget.showLoadingSkeleton)
          const Positioned.fill(child: FrayaSkeleton(borderRadius: 0)),
      ],
    );
  }

  void _centreCamera(LatLng target) {
    _controller?.animateCamera(CameraUpdate.newLatLng(target));
  }

  bool _isWidgetTestEnvironment() {
    final bindingName = WidgetsBinding.instance.runtimeType.toString();
    return !kReleaseMode && bindingName.contains('TestWidgetsFlutterBinding');
  }
}

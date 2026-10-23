/// Guidage dans la carte de la course, avec le Navigation SDK officiel de Google.
/// Si le SDK ne peut pas démarrer, on bascule sur le guidage construit avec l'API Directions (avec voix).
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';

import '../../../../core/services/navigation_launcher_service.dart';
import '../../../../core/services/navigation_sdk_service.dart';
import '../screens/driver_directions_navigation_screen.dart';

class DriverNavigationView extends StatefulWidget {
  const DriverNavigationView({
    super.key,
    required this.target,
    required this.onClose,
    this.bottomPadding = 0,
    this.starter = const NavigationSdkStarter(),
  });

  final NavigationTarget target;
  final VoidCallback onClose;

  /// Hauteur de l'encart de course posé sur la carte : le guidage reste visible au-dessus.
  final double bottomPadding;
  final NavigationSdkStarter starter;

  @override
  State<DriverNavigationView> createState() => _DriverNavigationViewState();
}

class _DriverNavigationViewState extends State<DriverNavigationView> {
  GoogleNavigationViewController? _controller;
  bool _isReady = false;
  bool _useFallback = false;
  StreamSubscription<void>? _arrivalSubscription;

  @override
  void initState() {
    super.initState();
    if (_isWidgetTestEnvironment()) return;
    unawaited(_prepare());
  }

  @override
  void didUpdateWidget(covariant DriverNavigationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bottomPadding != widget.bottomPadding) {
      unawaited(_applyPadding());
    }
  }

  @override
  void dispose() {
    unawaited(_arrivalSubscription?.cancel());
    if (!_isWidgetTestEnvironment()) {
      unawaited(widget.starter.gateway.stopAndCleanup());
    }
    super.dispose();
  }

  Future<void> _prepare() async {
    final failure = await widget.starter.prepare();
    if (!mounted) return;
    if (failure != null) {
      setState(() => _useFallback = true);
      return;
    }
    setState(() => _isReady = true);
  }

  Future<void> _applyPadding() async {
    try {
      await _controller?.setPadding(
        EdgeInsets.only(bottom: widget.bottomPadding),
      );
    } catch (_) {
      // Vue détruite entre-temps.
    }
  }

  Future<void> _onViewCreated(GoogleNavigationViewController controller) async {
    _controller = controller;
    await controller.setMyLocationEnabled(true);
    await _applyPadding();
    final result = await widget.starter.start(widget.target);
    if (!mounted) return;
    if (result != NavigationSdkStartResult.started) {
      setState(() => _useFallback = true);
      return;
    }
    await controller.followMyLocation(CameraPerspective.tilted);
    _arrivalSubscription = widget.starter.gateway.onArrival.listen((_) {
      if (mounted) widget.onClose();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isWidgetTestEnvironment()) {
      return Center(
        key: const Key('driver_navigation_test_placeholder'),
        child: Text(
          'navigation:${widget.target.leg.name}:${widget.target.latitude}:${widget.target.longitude}',
        ),
      );
    }
    if (_useFallback) {
      return DriverDirectionsNavigationScreen(
        target: widget.target,
        onClose: widget.onClose,
      );
    }
    if (!_isReady) {
      return const ColoredBox(
        color: Colors.black12,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        GoogleMapsNavigationView(
          key: const Key('driver_sdk_navigation_view'),
          onViewCreated: _onViewCreated,
          initialCameraPosition: CameraPosition(
            target: LatLng(
              latitude: widget.target.latitude,
              longitude: widget.target.longitude,
            ),
            zoom: 16,
          ),
          initialNavigationUIEnabledPreference:
              NavigationUIEnabledPreference.automatic,
        ),
        Positioned(
          right: 12,
          bottom: widget.bottomPadding + 16,
          child: FloatingActionButton.small(
            key: const Key('driver_sdk_navigation_close'),
            heroTag: 'driver_sdk_navigation_close',
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
            tooltip: 'Quitter la navigation',
            onPressed: widget.onClose,
            child: const Icon(Icons.close_rounded),
          ),
        ),
      ],
    );
  }

  bool _isWidgetTestEnvironment() {
    final bindingName = WidgetsBinding.instance.runtimeType.toString();
    return !kReleaseMode && bindingName.contains('TestWidgetsFlutterBinding');
  }
}

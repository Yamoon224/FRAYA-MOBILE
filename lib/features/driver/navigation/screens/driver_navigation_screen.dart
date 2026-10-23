/// Guidage dans l'application avec le Navigation SDK officiel de Google.
/// Si le SDK ne peut pas démarrer, on bascule sur le guidage construit avec l'API Directions.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';

import '../../../../core/services/navigation_launcher_service.dart';
import '../../../../core/services/navigation_sdk_service.dart';
import 'driver_directions_navigation_screen.dart';

class DriverNavigationScreen extends StatefulWidget {
  const DriverNavigationScreen({
    super.key,
    required this.target,
    this.starter = const NavigationSdkStarter(),
  });

  final NavigationTarget target;
  final NavigationSdkStarter starter;

  @override
  State<DriverNavigationScreen> createState() => _DriverNavigationScreenState();
}

class _DriverNavigationScreenState extends State<DriverNavigationScreen> {
  bool _isReady = false;
  bool _useFallback = false;
  StreamSubscription<void>? _arrivalSubscription;

  @override
  void initState() {
    super.initState();
    unawaited(_prepare());
  }

  @override
  void dispose() {
    unawaited(_arrivalSubscription?.cancel());
    unawaited(widget.starter.gateway.stopAndCleanup());
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

  Future<void> _onViewCreated(GoogleNavigationViewController controller) async {
    await controller.setMyLocationEnabled(true);
    final result = await widget.starter.start(widget.target);
    if (!mounted) return;
    if (result != NavigationSdkStartResult.started) {
      setState(() => _useFallback = true);
      return;
    }
    await controller.followMyLocation(CameraPerspective.tilted);
    _arrivalSubscription = widget.starter.gateway.onArrival.listen((_) {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_useFallback) {
      return DriverDirectionsNavigationScreen(target: widget.target);
    }
    if (!_isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
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
            bottom: MediaQuery.paddingOf(context).bottom + 110,
            child: FloatingActionButton.small(
              key: const Key('driver_sdk_navigation_close'),
              heroTag: 'driver_sdk_navigation_close',
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              tooltip: 'Quitter la navigation',
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Icon(Icons.close_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

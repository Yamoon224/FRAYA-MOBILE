/// Guidage dans la carte de la course, avec le Navigation SDK officiel de Google.
/// Si le SDK ne peut pas démarrer, on bascule sur le guidage construit avec l'API Directions (avec voix).
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';

import '../../../../core/services/navigation_launcher_service.dart';
import '../../../../core/services/navigation_sdk_service.dart';
import '../../../../core/services/navigation_sdk_voice.dart';
import '../../../../core/services/navigation_voice.dart';
import '../../../../core/services/navigation_voice_preference.dart';
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

class _DriverNavigationViewState extends State<DriverNavigationView>
    with WidgetsBindingObserver {
  GoogleNavigationViewController? _controller;
  bool _isReady = false;
  bool _useFallback = false;
  bool _isVoiceOn = NavigationVoicePreference.isEnabled;
  bool _isFrenchVoiceMissing = false;
  StreamSubscription<void>? _arrivalSubscription;
  StreamSubscription<NavInfo>? _navInfoSubscription;
  final FlutterTtsSpeaker _speaker = FlutterTtsSpeaker();
  late final SdkFrenchVoiceGuide _voice = SdkFrenchVoiceGuide(_speaker)
    ..enabled = NavigationVoicePreference.isEnabled;

  @override
  void initState() {
    super.initState();
    if (_isWidgetTestEnvironment()) return;
    WidgetsBinding.instance.addObserver(this);
    unawaited(_prepare());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Retour de l'écran d'installation des voix : on revérifie la voix française.
    if (state == AppLifecycleState.resumed && _isFrenchVoiceMissing) {
      unawaited(_checkFrenchVoice());
    }
  }

  Future<void> _checkFrenchVoice() async {
    final available = await _speaker.checkFrench();
    if (mounted) setState(() => _isFrenchVoiceMissing = !available);
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
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_navInfoSubscription?.cancel());
    unawaited(_voice.dispose());
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

  Future<void> _toggleVoice() async {
    final enabled = !_isVoiceOn;
    setState(() => _isVoiceOn = enabled);
    _voice.enabled = enabled;
    if (!enabled) unawaited(_voice.dispose());
    await NavigationVoicePreference.save(enabled);
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
    // Narration en français : la voix du SDK est coupée, les consignes sont lues ici.
    _navInfoSubscription = widget.starter.gateway.navInfo.listen(
      _voice.onNavInfo,
    );
    unawaited(_checkFrenchVoice());
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
        if (_isFrenchVoiceMissing)
          Positioned(
            left: 12,
            right: 76,
            bottom: widget.bottomPadding + 16,
            child: Material(
              key: const Key('driver_navigation_french_voice_missing'),
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              color: Colors.amber.shade100,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'La voix française n\'est pas installée : la voix du guidage est coupée.',
                        style: TextStyle(fontSize: 12.5, color: Colors.black87),
                      ),
                    ),
                    TextButton(
                      onPressed: FlutterTtsSpeaker.openFrenchVoiceInstall,
                      child: const Text('Installer'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Positioned(
          right: 12,
          bottom: widget.bottomPadding + 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                key: const Key('driver_sdk_navigation_voice_toggle'),
                heroTag: 'driver_sdk_navigation_voice_toggle',
                tooltip: _isVoiceOn ? 'Couper la voix' : 'Activer la voix',
                onPressed: _toggleVoice,
                child: Icon(
                  _isVoiceOn
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded,
                ),
              ),
              const SizedBox(height: 12),
              FloatingActionButton.small(
                key: const Key('driver_sdk_navigation_close'),
                heroTag: 'driver_sdk_navigation_close',
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                tooltip: 'Quitter la navigation',
                onPressed: widget.onClose,
                child: const Icon(Icons.close_rounded),
              ),
            ],
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

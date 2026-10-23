/// Guidage de secours dans l'application, construit sur l'API Directions : utilisé quand le Navigation SDK
/// de Google ne peut pas démarrer (conditions refusées, session impossible, route refusée).
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../core/models/directions_models.dart';
import '../../../../core/services/navigation_launcher_service.dart';
import '../../../../core/services/navigation_progress.dart';
import '../../../../core/services/navigation_voice.dart';
import '../../../../core/services/navigation_voice_preference.dart';
import '../../../../shared/widgets/map/fraya_map_style.dart';
import '../../home/providers/driver_home_map_route_provider.dart';
import '../../home/providers/driver_home_provider.dart';
import '../../home/providers/driver_navigation_launcher_provider.dart';
import '../../home/widgets/driver_route_polylines.dart';
import '../widgets/navigation_maneuver_icon.dart';

const _offRouteConfirmations = 3;
const _minRerouteInterval = Duration(seconds: 15);
const _followZoom = 17.5;
const _followTilt = 55.0;

class DriverDirectionsNavigationScreen extends ConsumerStatefulWidget {
  const DriverDirectionsNavigationScreen({
    super.key,
    required this.target,
    this.onClose,
  });

  final NavigationTarget target;

  /// Fermeture demandée par l'écran qui l'héberge ; à défaut, retour à l'écran précédent.
  final VoidCallback? onClose;

  @override
  ConsumerState<DriverDirectionsNavigationScreen> createState() =>
      _DriverDirectionsNavigationScreenState();
}

class _DriverDirectionsNavigationScreenState
    extends ConsumerState<DriverDirectionsNavigationScreen> {
  GoogleMapController? _map;
  DirectionsRoute? _route;
  List<List<LatLng>> _stepPoints = const [];
  NavigationProgress? _progress;
  bool _isLoadingRoute = true;
  bool _routeFailed = false;
  bool _isFollowing = true;
  bool _isMovingCamera = false;
  bool _isRerouting = false;
  bool _isVoiceOn = NavigationVoicePreference.isEnabled;
  final FlutterTtsSpeaker _speaker = FlutterTtsSpeaker();
  late final NavigationVoiceGuide _voice = NavigationVoiceGuide(_speaker)
    ..enabled = NavigationVoicePreference.isEnabled;
  VoiceLanguage? _voiceLanguage;
  int _offRouteCount = 0;
  DateTime? _lastRouteRequestAt;

  LatLng get _destination =>
      LatLng(widget.target.latitude, widget.target.longitude);

  @override
  void initState() {
    super.initState();
    unawaited(_setWakelock(true));
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRoute());
  }

  @override
  void dispose() {
    unawaited(_setWakelock(false));
    unawaited(_voice.dispose());
    super.dispose();
  }

  Future<void> _setWakelock(bool enabled) async {
    try {
      await (enabled ? WakelockPlus.enable() : WakelockPlus.disable());
    } catch (_) {
      // L'écran peut alors s'éteindre : le guidage reste utilisable.
    }
  }

  LatLng? get _position => ref.read(driverHomeProvider).currentDriverLocation;

  /// Français si la voix française est installée, sinon anglais : le texte des consignes (API Directions) et
  /// la voix suivent la même langue, pour ne jamais lire du français avec une voix anglaise.
  Future<VoiceLanguage> _chooseVoiceLanguage() async {
    final known = _voiceLanguage;
    if (known != null) return known;
    final french = await _speaker.checkFrench();
    final language = french ? VoiceLanguage.fr : VoiceLanguage.en;
    if (!french) await _speaker.useLanguage(VoiceLanguage.en);
    _voice.language = language;
    return _voiceLanguage = language;
  }

  Future<void> _loadRoute() async {
    final origin = _position;
    if (origin == null) {
      if (mounted) setState(() => _isLoadingRoute = false);
      return;
    }
    _lastRouteRequestAt = DateTime.now();
    _isLoadingRoute = true;
    final language = await _chooseVoiceLanguage();
    final result = await ref
        .read(driverHomeDirectionsServiceProvider)
        .getDirections(
          origin: origin,
          destination: _destination,
          language: language.directionsLanguage,
        );
    if (!mounted) return;

    final route = result?.mainRoute;
    if (route == null || route.steps.isEmpty) {
      setState(() {
        _isLoadingRoute = false;
        _isRerouting = false;
        _routeFailed = _route == null;
      });
      return;
    }
    setState(() {
      _route = route;
      _stepPoints = [for (final step in route.steps) step.getPolylinePoints()];
      _progress = NavigationProgress.compute(route, origin);
      _isLoadingRoute = false;
      _isRerouting = false;
      _routeFailed = false;
      _offRouteCount = 0;
    });
    // Nouvel itinéraire : les annonces vocales repartent de zéro.
    _voice.reset();
    final firstProgress = _progress;
    if (firstProgress != null) {
      _voice.onProgress(
        route,
        firstProgress,
        toPickup: widget.target.leg == DriverNavigationLeg.toPickup,
      );
    }
    unawaited(_followCamera(origin));
  }

  void _onPosition(LatLng? previous, LatLng? next) {
    final route = _route;
    if (next == null || route == null) {
      if (next != null && _route == null && !_isLoadingRoute && !_routeFailed) {
        unawaited(_loadRoute());
      }
      return;
    }

    final progress = NavigationProgress.compute(
      route,
      next,
      minStepIndex: _progress?.stepIndex ?? 0,
    );
    if (progress == null) return;

    _offRouteCount = progress.isOffRoute ? _offRouteCount + 1 : 0;
    setState(() => _progress = progress);
    _voice.onProgress(
      route,
      progress,
      toPickup: widget.target.leg == DriverNavigationLeg.toPickup,
    );
    if (_isFollowing) unawaited(_followCamera(next));

    if (_offRouteCount >= _offRouteConfirmations &&
        !_isRerouting &&
        !progress.hasArrived) {
      final last = _lastRouteRequestAt;
      if (last == null ||
          DateTime.now().difference(last) >= _minRerouteInterval) {
        setState(() => _isRerouting = true);
        _voice.announceReroute();
        unawaited(_loadRoute());
      }
    }
  }

  Future<void> _followCamera(LatLng position) async {
    final controller = _map;
    if (controller == null || kIsWeb) return;
    final heading = ref.read(driverHomeProvider).currentDriverHeading;
    final bearing = heading ?? _bearingAhead(position);
    _isMovingCamera = true;
    try {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: position,
            zoom: _followZoom,
            tilt: _followTilt,
            bearing: bearing,
          ),
        ),
      );
    } catch (_) {
      // Carte non prête ou détruite : la prochaine position réessaiera.
    } finally {
      _isMovingCamera = false;
    }
  }

  double _bearingAhead(LatLng position) {
    final progress = _progress;
    if (progress == null || progress.stepIndex >= _stepPoints.length) return 0;
    final points = _stepPoints[progress.stepIndex];
    return points.isEmpty ? 0 : bearingBetween(position, points.last);
  }

  Set<Polyline> _polylines() {
    final progress = _progress;
    if (progress == null) return const {};
    final remaining = <LatLng>[
      for (var i = progress.stepIndex; i < _stepPoints.length; i++)
        ..._stepPoints[i],
    ];
    return buildDriverRoutePolylines(remaining);
  }

  Future<void> _openGoogleMaps() async {
    final opened = await ref
        .read(driverNavigationLauncherProvider)
        .openGoogleMapsDriving(
          lat: widget.target.latitude,
          lng: widget.target.longitude,
          label: widget.target.label,
        );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Impossible d'ouvrir Google Maps sur cet appareil."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LatLng?>(
      driverHomeProvider.select((s) => s.currentDriverLocation),
      _onPosition,
    );
    final position = ref.watch(
      driverHomeProvider.select((s) => s.currentDriverLocation),
    );
    final progress = _progress;
    final route = _route;
    final isToPickup = widget.target.leg == DriverNavigationLeg.toPickup;

    final map = GoogleMap(
      key: const Key('driver_navigation_map'),
      initialCameraPosition: CameraPosition(
        target: position ?? _destination,
        zoom: _followZoom,
        tilt: _followTilt,
      ),
      style: Theme.of(context).brightness == Brightness.dark
          ? frayaMapDarkStyle
          : frayaMapDefaultStyle,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: true,
      trafficEnabled: true,
      polylines: _polylines(),
      markers: {
        Marker(
          markerId: const MarkerId('driver_navigation_destination'),
          position: _destination,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isToPickup ? BitmapDescriptor.hueRed : BitmapDescriptor.hueOrange,
          ),
        ),
      },
      padding: const EdgeInsets.only(top: 150, bottom: 110),
      onMapCreated: (controller) {
        _map = controller;
        if (position != null) unawaited(_followCamera(position));
      },
      onCameraMoveStarted: () {
        if (!_isMovingCamera && _isFollowing) {
          setState(() => _isFollowing = false);
        }
      },
    );

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          map,
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: _TopBanner(
                  route: route,
                  progress: progress,
                  isLoading: _isLoadingRoute,
                  isRerouting: _isRerouting,
                  failed:
                      _routeFailed ||
                      (!_isLoadingRoute && position == null && route == null),
                  targetLabel: widget.target.label,
                  isToPickup: isToPickup,
                  onRetry: () {
                    setState(() {
                      _isLoadingRoute = true;
                      _routeFailed = false;
                    });
                    unawaited(_loadRoute());
                  },
                ),
              ),
            ),
          ),
          if (!_isFollowing)
            Positioned(
              right: 12,
              bottom: MediaQuery.paddingOf(context).bottom + 110,
              child: FloatingActionButton.small(
                key: const Key('driver_navigation_recenter'),
                heroTag: 'driver_navigation_recenter',
                onPressed: () {
                  setState(() => _isFollowing = true);
                  final current = _position;
                  if (current != null) unawaited(_followCamera(current));
                },
                child: const Icon(Icons.my_location_rounded),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomBar(
              progress: progress,
              isVoiceOn: _isVoiceOn,
              onToggleVoice: () {
                setState(() {
                  _isVoiceOn = !_isVoiceOn;
                  _voice.enabled = _isVoiceOn;
                });
                unawaited(NavigationVoicePreference.save(_isVoiceOn));
                if (!_isVoiceOn) unawaited(_voice.dispose());
              },
              onClose: widget.onClose ?? () => Navigator.of(context).maybePop(),
              onOpenGoogleMaps: _openGoogleMaps,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBanner extends StatelessWidget {
  const _TopBanner({
    required this.route,
    required this.progress,
    required this.isLoading,
    required this.isRerouting,
    required this.failed,
    required this.targetLabel,
    required this.isToPickup,
    required this.onRetry,
  });

  final DirectionsRoute? route;
  final NavigationProgress? progress;
  final bool isLoading;
  final bool isRerouting;
  final bool failed;
  final String? targetLabel;
  final bool isToPickup;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF0B57D0);
    final textTheme = Theme.of(context).textTheme;

    Widget content;
    if (failed) {
      content = Row(
        children: [
          const Icon(Icons.location_off_rounded, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "Itinéraire indisponible. Vérifiez votre position et votre connexion.",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Réessayer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    } else if (route == null || progress == null) {
      content = Row(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            isLoading
                ? "Calcul de l'itinéraire…"
                : 'Recherche de votre position…',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    } else if (progress!.hasArrived) {
      content = Row(
        children: [
          const Icon(Icons.flag_rounded, color: Colors.white, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isToPickup
                  ? 'Vous êtes arrivé chez le passager'
                  : 'Vous êtes arrivé à destination',
              style: textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    } else {
      final steps = route!.steps;
      final next = progress!.stepIndex + 1 < steps.length
          ? steps[progress!.stepIndex + 1]
          : null;
      final icon = next == null
          ? Icons.flag_rounded
          : navigationManeuverIcon(next.maneuver);
      final instruction =
          next?.instruction ??
          (targetLabel != null && targetLabel!.isNotEmpty
              ? (isToPickup
                    ? 'Arrivée chez le passager : $targetLabel'
                    : 'Arrivée : $targetLabel')
              : (isToPickup
                    ? 'Arrivée chez le passager'
                    : 'Arrivée à destination'));
      content = Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 44),
              Text(
                formatNavigationDistance(progress!.distanceToManeuverMeters),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              isRerouting ? 'Recalcul de l\'itinéraire…' : instruction,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    }

    return Material(
      elevation: 6,
      color: background,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: content,
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.progress,
    required this.isVoiceOn,
    required this.onToggleVoice,
    required this.onClose,
    required this.onOpenGoogleMaps,
  });

  final NavigationProgress? progress;
  final bool isVoiceOn;
  final VoidCallback onToggleVoice;
  final VoidCallback onClose;
  final VoidCallback onOpenGoogleMaps;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = this.progress;
    final eta = progress == null
        ? null
        : TimeOfDay.fromDateTime(
            DateTime.now().add(
              Duration(seconds: progress.remainingSeconds.round()),
            ),
          );

    return Material(
      elevation: 10,
      color: scheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: progress == null
                    ? const Text('—')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${formatNavigationDuration(progress.remainingSeconds)} · ${formatNavigationDistance(progress.remainingMeters)}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'Arrivée à ${eta!.hour.toString().padLeft(2, '0')}:${eta.minute.toString().padLeft(2, '0')}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
              ),
              IconButton(
                key: const Key('driver_navigation_voice_toggle'),
                tooltip: isVoiceOn ? 'Couper la voix' : 'Activer la voix',
                onPressed: onToggleVoice,
                icon: Icon(
                  isVoiceOn
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded,
                ),
              ),
              IconButton(
                key: const Key('driver_navigation_open_google_maps'),
                tooltip: 'Ouvrir dans Google Maps',
                onPressed: onOpenGoogleMaps,
                icon: const Icon(Icons.open_in_new_rounded),
              ),
              FilledButton.icon(
                key: const Key('driver_navigation_close'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                ),
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
                label: const Text('Quitter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

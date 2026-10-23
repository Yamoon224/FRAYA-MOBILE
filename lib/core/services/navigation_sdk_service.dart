/// Session du Navigation SDK de Google (guidage officiel : voix, voies, trafic, recalcul).
library;

import 'dart:async';

import 'package:google_navigation_flutter/google_navigation_flutter.dart';

import '../utils/logger.dart';
import 'navigation_launcher_service.dart';

final _log = AppLogger.instance;

enum NavigationSdkRouteResult { ok, locationUnavailable, failed }

enum NavigationSdkStartResult { started, termsRefused, routeUnavailable, error }

/// Frontière avec le SDK natif, pour pouvoir tester la logique de démarrage sans plateforme.
abstract class NavigationSdkGateway {
  Future<bool> ensureTermsAccepted();
  Future<void> initializeSession();
  Future<NavigationSdkRouteResult> setDestination(NavigationTarget target);
  Future<void> startGuidance();
  Future<void> setSdkVoiceEnabled(bool enabled);
  Stream<NavInfo> get navInfo;
  Stream<void> get onArrival;
  Future<void> stopAndCleanup();
}

class GoogleNavigationSdkGateway implements NavigationSdkGateway {
  const GoogleNavigationSdkGateway();

  @override
  Future<bool> ensureTermsAccepted() async {
    if (await GoogleMapsNavigator.areTermsAccepted()) return true;
    return GoogleMapsNavigator.showTermsAndConditionsDialog(
      'Navigation Fraya Taxi',
      'Fraya Taxi',
    );
  }

  @override
  Future<void> initializeSession() async {
    await GoogleMapsNavigator.initializeNavigationSession(
      taskRemovedBehavior: TaskRemovedBehavior.continueService,
    );
    // Par défaut la voix du SDK est coupée : la narration française est lue par l'app (SdkFrenchVoiceGuide).
    // Elle n'est rallumée que si la voix française n'est pas installée (voir setSdkVoiceEnabled).
    await setSdkVoiceEnabled(false);
  }

  @override
  Future<void> setSdkVoiceEnabled(bool enabled) async {
    try {
      await GoogleMapsNavigator.setAudioGuidance(
        NavigationAudioGuidanceSettings(
          guidanceType: enabled
              ? NavigationAudioGuidanceType.alertsAndGuidance
              : NavigationAudioGuidanceType.silent,
          isBluetoothAudioEnabled: true,
          isVibrationEnabled: true,
        ),
      );
    } catch (error) {
      _log.warning(
        'Navigation SDK : réglage de la voix du SDK impossible : $error',
      );
    }
  }

  @override
  Future<NavigationSdkRouteResult> setDestination(
    NavigationTarget target,
  ) async {
    final status = await GoogleMapsNavigator.setDestinations(
      Destinations(
        waypoints: [
          NavigationWaypoint.withLatLngTarget(
            title: target.label?.trim().isNotEmpty == true
                ? target.label!
                : 'Destination',
            target: LatLng(
              latitude: target.latitude,
              longitude: target.longitude,
            ),
          ),
        ],
        displayOptions: NavigationDisplayOptions(showDestinationMarkers: true),
        routingOptions: RoutingOptions(
          travelMode: NavigationTravelMode.driving,
        ),
      ),
    );
    switch (status) {
      case NavigationRouteStatus.statusOk:
        return NavigationSdkRouteResult.ok;
      case NavigationRouteStatus.locationUnavailable:
        return NavigationSdkRouteResult.locationUnavailable;
      default:
        _log.warning('Navigation SDK : route refusée ($status)');
        return NavigationSdkRouteResult.failed;
    }
  }

  @override
  Future<void> startGuidance() => GoogleMapsNavigator.startGuidance();

  @override
  Stream<NavInfo> get navInfo {
    late final StreamController<NavInfo> controller;
    StreamSubscription<NavInfoEvent>? subscription;
    controller = StreamController<NavInfo>(
      onListen: () {
        subscription = GoogleMapsNavigator.setNavInfoListener(
          (event) => controller.add(event.navInfo),
        );
      },
      onCancel: () => subscription?.cancel(),
    );
    return controller.stream;
  }

  @override
  Stream<void> get onArrival {
    late final StreamController<void> controller;
    StreamSubscription<OnArrivalEvent>? subscription;
    controller = StreamController<void>(
      onListen: () {
        subscription = GoogleMapsNavigator.setOnArrivalListener(
          (_) => controller.add(null),
        );
      },
      onCancel: () => subscription?.cancel(),
    );
    return controller.stream;
  }

  @override
  Future<void> stopAndCleanup() async {
    try {
      await GoogleMapsNavigator.stopGuidance();
      await GoogleMapsNavigator.clearDestinations();
    } catch (_) {
      // Session déjà fermée.
    }
    try {
      await GoogleMapsNavigator.cleanup();
    } catch (_) {
      // Rien à nettoyer.
    }
  }
}

/// Démarre le guidage officiel : conditions Google, session, itinéraire.
///
/// Le SDK ne calcule une route qu'une fois la position connue : on réessaie quelques secondes
/// avant d'abandonner, plutôt que de basculer tout de suite sur le guidage de secours.
class NavigationSdkStarter {
  const NavigationSdkStarter({
    this.gateway = const GoogleNavigationSdkGateway(),
    this.retryDelay = const Duration(seconds: 2),
    this.maxLocationRetries = 5,
  });

  final NavigationSdkGateway gateway;
  final Duration retryDelay;
  final int maxLocationRetries;

  /// Conditions + session. À appeler avant d'afficher la vue de navigation.
  Future<NavigationSdkStartResult?> prepare() async {
    try {
      if (!await gateway.ensureTermsAccepted()) {
        return NavigationSdkStartResult.termsRefused;
      }
      await gateway.initializeSession();
      return null;
    } catch (error) {
      _log.error('Navigation SDK : initialisation impossible : $error');
      return NavigationSdkStartResult.error;
    }
  }

  /// Itinéraire + guidage. À appeler une fois la vue créée.
  Future<NavigationSdkStartResult> start(NavigationTarget target) async {
    try {
      for (var attempt = 0; ; attempt++) {
        final result = await gateway.setDestination(target);
        if (result == NavigationSdkRouteResult.ok) break;
        if (result == NavigationSdkRouteResult.failed ||
            attempt >= maxLocationRetries) {
          return NavigationSdkStartResult.routeUnavailable;
        }
        await Future<void>.delayed(retryDelay);
      }
      await gateway.startGuidance();
      return NavigationSdkStartResult.started;
    } catch (error) {
      _log.error('Navigation SDK : démarrage du guidage impossible : $error');
      return NavigationSdkStartResult.error;
    }
  }
}

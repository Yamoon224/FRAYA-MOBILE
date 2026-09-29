import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fraya_mobile/core/realtime/realtime_events.dart';
import 'package:fraya_mobile/core/router/route_names.dart';
import 'package:fraya_mobile/core/services/passenger_contact_launcher_service.dart';
import 'package:fraya_mobile/core/services/navigation_launcher_service.dart';
import 'package:fraya_mobile/data/sources/local_storage.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';
import 'package:fraya_mobile/domain/models/driver_wallet_overview.dart';
import 'package:fraya_mobile/domain/repositories/driver_wallet_repository.dart';
import 'package:fraya_mobile/features/driver/auth/providers/driver_auth_provider.dart';
import 'package:fraya_mobile/features/driver/home/providers/driver_contact_provider.dart';
import 'package:fraya_mobile/features/driver/home/providers/driver_navigation_launcher_provider.dart';
import 'package:fraya_mobile/features/driver/home/providers/driver_home_arrival_detection.dart';
import 'package:fraya_mobile/features/driver/home/providers/driver_home_provider.dart';
import 'package:fraya_mobile/features/driver/home/providers/driver_home_state.dart';
import 'package:fraya_mobile/features/driver/home/screens/driver_home_screen.dart';
import 'package:fraya_mobile/features/driver/home/widgets/driver_home_map_stage.dart';
import 'package:fraya_mobile/features/driver/home/widgets/driver_home_panel.dart';
import 'package:fraya_mobile/features/driver/wallet/providers/driver_wallet_dependencies.dart';
import 'package:fraya_mobile/shared/models/auth_state.dart';
import 'package:fraya_mobile/shared/providers/realtime_providers.dart';
import 'package:fraya_mobile/shared/widgets/confirmation_action_column.dart';
import 'package:fraya_mobile/shared/widgets/fraya_button.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/driver_test_doubles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders offline state on the existing driver home screen', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      authState: _approvedAuthState,
      homeState: const DriverHomeState(
        status: DriverHomeStatus.idle,
        isOnline: false,
        canGoOnline: true,
      ),
    );

    expect(find.byKey(const Key('driver_home_live_map')), findsOneWidget);
    expect(find.text('Mode hors ligne'), findsNothing);

    final switchWidget = tester.widget<CupertinoSwitch>(
      find.byType(CupertinoSwitch),
    );
    expect(switchWidget.inactiveTrackColor, const Color(0xFFEF4444));
  });

  testWidgets('keeps the offline toggle responsive on narrow phones', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 690));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpHome(
      tester,
      authState: _approvedAuthState,
      homeState: const DriverHomeState(
        status: DriverHomeStatus.ready,
        isOnline: false,
        canGoOnline: true,
      ),
    );

    expect(find.text('Hors ligne'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders blocked state with admin CTA and navigates to KYC', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      authState: AuthState(
        status: AuthStatus.authenticated,
        userData: const {
          'driverId': 14,
          'kycStatus': 'PENDING_VALIDATION',
          'vehicleStatus': 'APPROVED',
          'vehicleId': 7,
        },
      ),
      homeState: const DriverHomeState(
        status: DriverHomeStatus.blocked,
        isOnline: false,
        canGoOnline: false,
      ),
    );

    expect(find.text('Validation admin en cours'), findsOneWidget);
    await tester.tap(find.text('Suivre mon dossier KYC'));
    await tester.pumpAndSettle();
    expect(find.text('kyc-page'), findsOneWidget);
  });

  testWidgets('renders online badge and navigates to earnings and history', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      authState: _approvedAuthState,
      homeState: DriverHomeState(
        status: DriverHomeStatus.ready,
        isOnline: true,
        canGoOnline: true,
      ),
    );

    expect(find.text('En ligne'), findsWidgets);
    final switchWidget = tester.widget<CupertinoSwitch>(
      find.byType(CupertinoSwitch),
    );
    expect(switchWidget.activeTrackColor, const Color(0xFF44CB85));
    final gainsButton = tester.widget<FrayaButton>(
      find.widgetWithText(FrayaButton, 'Mes recettes'),
    );
    gainsButton.onPressed?.call();
    await tester.pumpAndSettle();
    expect(find.text('earnings-page'), findsOneWidget);
  });

  testWidgets('keeps summary cards and actions responsive on narrow phones', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 690));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpHome(
      tester,
      authState: _approvedAuthState,
      homeState: const DriverHomeState(
        status: DriverHomeStatus.ready,
        isOnline: true,
        canGoOnline: true,
        todayEarnings: 2700,
        todayRideCount: 1,
        todayOnlineHours: 0.25,
      ),
    );

    expect(find.text('Mes recettes'), findsOneWidget);
    expect(find.textContaining('0h 15min'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disables the online toggle while loading or submitting', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      authState: _approvedAuthState,
      homeState: const DriverHomeState(
        status: DriverHomeStatus.loading,
        isOnline: true,
        canGoOnline: true,
      ),
    );

    final loadingSwitch = tester.widget<CupertinoSwitch>(
      find.byType(CupertinoSwitch),
    );
    expect(loadingSwitch.onChanged, isNull);

    await _pumpHome(
      tester,
      authState: _approvedAuthState,
      homeState: DriverHomeState(
        status: DriverHomeStatus.ready,
        isOnline: true,
        canGoOnline: true,
        isSubmittingAction: true,
        activeRide: buildDriverRide(id: '202', status: RideStatus.accepted),
      ),
    );

    final submittingSwitch = tester.widget<CupertinoSwitch>(
      find.byType(CupertinoSwitch),
    );
    expect(submittingSwitch.onChanged, isNull);
  });

  testWidgets(
    'prefers currentDriverLocation when wiring the driver marker position',
    (tester) async {
      const currentLocation = LatLng(5.355, -4.021);
      const activeRideLocation = LatLng(5.401, -3.901);

      await _pumpHome(
        tester,
        authState: _approvedAuthState,
        homeState: DriverHomeState(
          status: DriverHomeStatus.ready,
          isOnline: true,
          canGoOnline: true,
          activeRide: buildDriverRide(
            id: 'ride-loc',
            status: RideStatus.accepted,
            driverLocation: activeRideLocation,
          ),
          currentDriverLocation: currentLocation,
        ),
      );

      final mapStage = tester.widget<DriverHomeMapStage>(
        find.byType(DriverHomeMapStage),
      );
      expect(mapStage.driverMarkerPosition, currentLocation);
    },
  );

  testWidgets(
    'falls back to active ride driver location for the driver marker',
    (tester) async {
      const activeRideLocation = LatLng(5.324, -4.005);

      await _pumpHome(
        tester,
        authState: _approvedAuthState,
        homeState: DriverHomeState(
          status: DriverHomeStatus.ready,
          isOnline: true,
          canGoOnline: true,
          activeRide: buildDriverRide(
            id: 'ride-only-loc',
            status: RideStatus.accepted,
            driverLocation: activeRideLocation,
          ),
        ),
      );

      final mapStage = tester.widget<DriverHomeMapStage>(
        find.byType(DriverHomeMapStage),
      );
      expect(mapStage.driverMarkerPosition, activeRideLocation);
    },
  );

  testWidgets('opens the driver drawer from the top menu button', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      authState: _approvedAuthState,
      homeState: const DriverHomeState(
        status: DriverHomeStatus.ready,
        isOnline: false,
        canGoOnline: true,
      ),
    );

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Mon portefeuille'), findsOneWidget);
    expect(find.text('Mon profil'), findsOneWidget);
    expect(find.textContaining('connexion'), findsOneWidget);

    await tester.tap(find.text('Mon portefeuille'));
    await tester.pumpAndSettle();
    expect(find.text('wallet-page'), findsOneWidget);
  });

  testWidgets('triggers driver logout when tapping Deconnexion in drawer', (
    tester,
  ) async {
    final authNotifier = await _pumpHome(
      tester,
      authState: _approvedAuthState,
      homeState: const DriverHomeState(
        status: DriverHomeStatus.ready,
        isOnline: false,
        canGoOnline: true,
      ),
    );

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('connexion'));
    await tester.pumpAndSettle();

    expect(authNotifier.logoutCalls, 1);
    expect(authNotifier.state.status, AuthStatus.unauthenticated);
  });

  testWidgets(
    'opens external Google Maps navigation when active ride is present',
    (tester) async {
      final launcher = _FakeNavigationLauncherService();
      await _pumpHome(
        tester,
        authState: _approvedAuthState,
        homeState: DriverHomeState(
          status: DriverHomeStatus.ready,
          isOnline: true,
          canGoOnline: true,
          activeRide: buildDriverRide(
            id: 'ride-nav',
            status: RideStatus.accepted,
          ),
        ),
        navigationLauncher: launcher,
      );

      await tester.tap(find.byIcon(Icons.navigation_rounded));
      await tester.pumpAndSettle();

      expect(launcher.openCalls, 1);
      expect(launcher.lastLat, closeTo(5.4, 0.0001));
      expect(launcher.lastLng, closeTo(-3.9, 0.0001));
    },
  );

  testWidgets(
    'opens external Google Maps navigation to destination when ride is in progress',
    (tester) async {
      final launcher = _FakeNavigationLauncherService();
      await _pumpHome(
        tester,
        authState: _approvedAuthState,
        homeState: DriverHomeState(
          status: DriverHomeStatus.ready,
          isOnline: true,
          canGoOnline: true,
          activeRide: buildDriverRide(
            id: 'ride-nav-destination',
            status: RideStatus.inProgress,
          ),
        ),
        navigationLauncher: launcher,
      );

      await tester.tap(find.byIcon(Icons.navigation_rounded));
      await tester.pumpAndSettle();

      expect(launcher.openCalls, 1);
      expect(launcher.lastLat, closeTo(5.32, 0.0001));
      expect(launcher.lastLng, closeTo(-4.01, 0.0001));
    },
  );

  testWidgets(
    'disables navigation button when active ride target coordinates are invalid',
    (tester) async {
      final launcher = _FakeNavigationLauncherService();
      await _pumpHome(
        tester,
        authState: _approvedAuthState,
        homeState: DriverHomeState(
          status: DriverHomeStatus.ready,
          isOnline: true,
          canGoOnline: true,
          activeRide: buildDriverRide(
            id: 'ride-invalid-nav',
            status: RideStatus.inProgress,
          ).copyWith(destinationLocation: const LatLng(0, 0)),
        ),
        navigationLauncher: launcher,
      );

      final navButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.navigation_rounded),
      );
      expect(navButton.onPressed, isNull);

      await tester.tap(
        find.byIcon(Icons.navigation_rounded),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(launcher.openCalls, 0);
    },
  );

  testWidgets(
    'opens phone call with passenger number from active ride contact button',
    (tester) async {
      final contactLauncher = _FakePassengerContactLauncherService();
      await _pumpHome(
        tester,
        authState: _approvedAuthState,
        homeState: DriverHomeState(
          status: DriverHomeStatus.ready,
          isOnline: true,
          canGoOnline: true,
          activeRide: buildDriverRide(
            id: 'ride-contact-phone',
            status: RideStatus.accepted,
          ).copyWith(passengerPhone: '+2250700112233'),
        ),
        contactLauncher: contactLauncher,
      );

      await tester.tap(find.byIcon(Icons.call_outlined));
      await tester.pumpAndSettle();

      expect(contactLauncher.lastPhoneNumber, '+2250700112233');
      expect(contactLauncher.phoneCallAttempts, 1);
    },
  );

  testWidgets(
    'opens WhatsApp with passenger number from active ride contact button',
    (tester) async {
      final contactLauncher = _FakePassengerContactLauncherService();
      await _pumpHome(
        tester,
        authState: _approvedAuthState,
        homeState: DriverHomeState(
          status: DriverHomeStatus.ready,
          isOnline: true,
          canGoOnline: true,
          activeRide: buildDriverRide(
            id: 'ride-contact-wa',
            status: RideStatus.accepted,
          ).copyWith(passengerPhone: '+2250700112233'),
        ),
        contactLauncher: contactLauncher,
      );

      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is FaIcon && widget.icon == FontAwesomeIcons.whatsapp,
        ),
      );
      await tester.pumpAndSettle();

      expect(contactLauncher.lastWhatsAppNumber, '+2250700112233');
      expect(contactLauncher.whatsAppAttempts, 1);
    },
  );

  testWidgets('shows error snackbar when passenger phone is missing', (
    tester,
  ) async {
    final contactLauncher = _FakePassengerContactLauncherService();
    await _pumpHome(
      tester,
      authState: _approvedAuthState,
      homeState: DriverHomeState(
        status: DriverHomeStatus.ready,
        isOnline: true,
        canGoOnline: true,
        activeRide: buildDriverRide(
          id: 'ride-contact-empty',
          status: RideStatus.accepted,
        ).copyWith(passengerPhone: null),
      ),
      contactLauncher: contactLauncher,
    );

    await tester.tap(find.byIcon(Icons.call_outlined));
    await tester.pumpAndSettle();

    expect(
      find.text('Numéro du passager indisponible pour l\'appel.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('confirms driver cancellation before cancelling active ride', (
    tester,
  ) async {
    final activeRide = buildDriverRide(
      id: 'ride-driver-cancel',
      status: RideStatus.accepted,
    );
    final harness = await _pumpHomeHarness(
      tester,
      authState: _approvedAuthState,
      homeState: DriverHomeState(
        status: DriverHomeStatus.ready,
        isOnline: true,
        canGoOnline: true,
        activeRide: activeRide,
      ),
    );
    harness.homeNotifier.syncUserData(_approvedAuthState.userData);
    harness.homeNotifier.repository.activeRide = activeRide;

    await tester.tap(find.text('Annuler la course'));
    await tester.pumpAndSettle();

    expect(find.text('Annuler la course ?'), findsOneWidget);
    expect(find.byType(ConfirmationActionColumn), findsOneWidget);
    expect(find.textContaining('Plus de 2 annulations'), findsOneWidget);
    _expectAbove(
      tester,
      find.text('Oui, annuler'),
      find.text('Garder la course'),
    );

    await tester.tap(find.widgetWithText(OutlinedButton, 'Garder la course'));
    await tester.pumpAndSettle();

    expect(harness.homeNotifier.repository.cancelRideCalls, 0);

    await tester.tap(find.text('Annuler la course'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Oui, annuler'));
    await tester.pumpAndSettle();

    expect(harness.homeNotifier.repository.cancelRideCalls, 1);
    expect(find.text('Course annulée avec succès.'), findsOneWidget);
    expect(find.text('Course annulée'), findsNothing);

    harness.container
        .read(driverRideStatusRealtimeProvider.notifier)
        .state = DriverRideStatusRealtimeEvent(
      rideId: 'ride-driver-cancel',
      status: 'CANCELLED',
      updatedAt: DateTime.parse('2026-05-22T12:15:00.000Z'),
      changedBy: 'DRIVER',
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Course annulée'), findsNothing);
  });

  testWidgets(
    'shows the arrival confirmation dialog and navigates to the completion '
    'screen on OK',
    (tester) async {
      final activeRide = buildDriverRide(
        id: 'ride-arrival-ok',
        status: RideStatus.inProgress,
      );
      final harness = await _pumpHomeHarness(
        tester,
        authState: _approvedAuthState,
        homeState: DriverHomeState(
          status: DriverHomeStatus.ready,
          isOnline: true,
          canGoOnline: true,
          activeRide: activeRide,
        ),
      );

      harness.homeNotifier.setTestState(
        harness.homeNotifier.state.copyWith(
          arrivalDetectionEvent: DriverArrivalDetectionEvent(
            rideId: 'ride-arrival-ok',
            detectedAt: DateTime(2026, 7, 9, 12),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Êtes-vous arrivé à destination ?'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'OK, je suis arrivé'));
      await tester.pumpAndSettle();

      expect(find.text('status-page'), findsOneWidget);
    },
  );

  testWidgets(
    'keeps the ride screen and manual complete button after dismissing the '
    'arrival dialog',
    (tester) async {
      final activeRide = buildDriverRide(
        id: 'ride-arrival-dismiss',
        status: RideStatus.inProgress,
      );
      final harness = await _pumpHomeHarness(
        tester,
        authState: _approvedAuthState,
        homeState: DriverHomeState(
          status: DriverHomeStatus.ready,
          isOnline: true,
          canGoOnline: true,
          activeRide: activeRide,
        ),
      );

      harness.homeNotifier.setTestState(
        harness.homeNotifier.state.copyWith(
          arrivalDetectionEvent: DriverArrivalDetectionEvent(
            rideId: 'ride-arrival-dismiss',
            detectedAt: DateTime(2026, 7, 9, 12),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Êtes-vous arrivé à destination ?'), findsOneWidget);

      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Pas encore arrivé'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Êtes-vous arrivé à destination ?'), findsNothing);
      expect(find.text('status-page'), findsNothing);
      expect(find.text('Terminer la course'), findsOneWidget);

      await tester.tap(find.text('Terminer la course'));
      await tester.pumpAndSettle();

      expect(find.text('status-page'), findsOneWidget);
    },
  );

  testWidgets(
    'reacts immediately to realtime cancellation without showing the fallback popup',
    (tester) async {
      final initialState = DriverHomeState(
        status: DriverHomeStatus.ready,
        isOnline: true,
        canGoOnline: true,
        activeRide: buildDriverRide(
          id: 'ride-cancelled',
          status: RideStatus.accepted,
        ),
      );
      final harness = await _pumpHomeHarness(
        tester,
        authState: _approvedAuthState,
        homeState: initialState,
      );
      harness.homeNotifier.syncUserData(_approvedAuthState.userData);
      harness.homeNotifier.repository.availableRides = const [];
      harness.homeNotifier.setTestState(initialState);

      harness.container
          .read(driverRideStatusRealtimeProvider.notifier)
          .state = DriverRideStatusRealtimeEvent(
        rideId: 'ride-cancelled',
        status: 'CANCELLED',
        updatedAt: DateTime.parse('2026-05-22T12:15:00.000Z'),
        reason: 'Client a annule',
        changedBy: 'PASSENGER',
      );

      await tester.pump();
      await tester.pump();

      harness.container
          .read(driverRideStatusRealtimeProvider.notifier)
          .state = DriverRideStatusRealtimeEvent(
        rideId: 'ride-cancelled',
        status: 'CANCELLED',
        updatedAt: DateTime.parse('2026-05-22T12:15:01.000Z'),
        reason: 'Evenement duplique',
        changedBy: 'PASSENGER',
      );
      await tester.pump();

      expect(find.text('Course annulée'), findsOneWidget);
      expect(find.textContaining('Motif : Client a annule'), findsOneWidget);
      expect(find.text('Redirection automatique dans 10 s'), findsOneWidget);
      expect(find.byType(ConfirmationActionColumn), findsOneWidget);
      expect(find.text('J\'ai compris'), findsOneWidget);
      expect(harness.homeNotifier.state.activeRide, isNull);
      expect(find.textContaining('backend'), findsNothing);

      await tester.tap(find.text('J\'ai compris'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Course annulée'), findsNothing);
    },
  );

  testWidgets(
    'shows the fallback popup when the active ride disappears without realtime event',
    (tester) async {
      final harness = await _pumpHomeHarness(
        tester,
        authState: _approvedAuthState,
        homeState: DriverHomeState(
          status: DriverHomeStatus.ready,
          isOnline: true,
          canGoOnline: true,
          activeRide: buildDriverRide(
            id: 'ride-fallback',
            status: RideStatus.accepted,
          ),
        ),
      );

      harness.homeNotifier.setTestState(
        const DriverHomeState(
          status: DriverHomeStatus.ready,
          isOnline: true,
          canGoOnline: true,
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(find.text('Course annulée'), findsOneWidget);
      expect(
        find.text('Cette course a été clôturée ou annulée.'),
        findsOneWidget,
      );
      expect(find.textContaining('backend'), findsNothing);

      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();

      expect(find.text('Course annulée'), findsNothing);
    },
  );

  testWidgets('keeps a declined pre-arrival request hidden after refresh', (
    tester,
  ) async {
    // Use a distinct passenger name so we can tell it apart from the active ride
    // (both would default to 'Alice Kouassi' via buildDriverRide).
    final availableRide = buildDriverRide(
      id: 'ride-declined-popup',
    ).copyWith(passengerName: 'Eve N\'Goran');
    final harness = await _pumpHomeHarness(
      tester,
      authState: _approvedAuthState,
      homeState: DriverHomeState(
        status: DriverHomeStatus.ready,
        isOnline: true,
        canGoOnline: true,
        activeRide: buildDriverRide(
          id: 'ride-active-popup',
          status: RideStatus.accepted,
        ),
        availableRides: [availableRide],
        isPreArrivalOffersActive: true,
      ),
    );
    harness.homeNotifier.syncUserData(_approvedAuthState.userData);
    harness.homeNotifier.repository.activeRide = buildDriverRide(
      id: 'ride-active-popup',
      status: RideStatus.accepted,
    );
    harness.homeNotifier.repository.availableRides = [availableRide];

    await tester.tap(find.text('Refuser'));
    await tester.pumpAndSettle();

    expect(find.text('Eve N\'Goran'), findsNothing);

    await harness.homeNotifier.refreshHome();
    await tester.pumpAndSettle();

    expect(find.text('Eve N\'Goran'), findsNothing);
    expect(harness.homeNotifier.state.ignoredIncomingRideIds, [
      'ride-declined-popup',
    ]);
  });

  testWidgets(
    'declines an available ride from the standard list and keeps the next one visible',
    (tester) async {
      final firstRide = buildDriverRide(
        id: 'ride-list-1',
      ).copyWith(passengerName: 'Premier passager');
      final secondRide = buildDriverRide(
        id: 'ride-list-2',
      ).copyWith(passengerName: 'Second passager');
      final harness = await _pumpHomeHarness(
        tester,
        authState: _approvedAuthState,
        homeState: DriverHomeState(
          status: DriverHomeStatus.ready,
          isOnline: true,
          canGoOnline: true,
          availableRides: [firstRide, secondRide],
        ),
      );
      harness.homeNotifier.syncUserData(_approvedAuthState.userData);
      harness.homeNotifier.repository.availableRides = [firstRide, secondRide];

      expect(find.text('Premier passager'), findsOneWidget);
      expect(find.text('Second passager'), findsOneWidget);

      await tester.tap(find.text('Refuser').first);
      await tester.pumpAndSettle();

      expect(find.text('Premier passager'), findsNothing);
      expect(find.text('Second passager'), findsOneWidget);
      expect(harness.homeNotifier.state.ignoredIncomingRideIds, [
        'ride-list-1',
      ]);

      harness.homeNotifier.setTestState(
        harness.homeNotifier.state.copyWith(
          availableRides: [firstRide, secondRide],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Premier passager'), findsNothing);
      expect(find.text('Second passager'), findsOneWidget);
    },
  );

  testWidgets(
    'keeps bottom panel surface attached to bottom for summary and active ride states',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 1366));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpHome(
        tester,
        authState: _approvedAuthState,
        homeState: const DriverHomeState(
          status: DriverHomeStatus.ready,
          isOnline: true,
          canGoOnline: true,
        ),
      );

      final screenBottomSummary = tester.getSize(find.byType(Scaffold)).height;
      final panelBottomSummary = tester
          .getBottomRight(find.byKey(driverHomeBottomPanelSurfaceKey))
          .dy;
      expect(panelBottomSummary, closeTo(screenBottomSummary, 1.0));

      await _pumpHome(
        tester,
        authState: _approvedAuthState,
        homeState: DriverHomeState(
          status: DriverHomeStatus.ready,
          isOnline: true,
          canGoOnline: true,
          activeRide: buildDriverRide(id: 'ride-bottom-panel'),
        ),
      );

      final screenBottomActive = tester.getSize(find.byType(Scaffold)).height;
      final panelBottomActive = tester
          .getBottomRight(find.byKey(driverHomeBottomPanelSurfaceKey))
          .dy;
      expect(panelBottomActive, closeTo(screenBottomActive, 1.0));
    },
  );

  testWidgets(
    'uses internal safe-area padding without creating external gap under panel',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 1366));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpHome(
        tester,
        authState: _approvedAuthState,
        homeState: const DriverHomeState(
          status: DriverHomeStatus.ready,
          isOnline: true,
          canGoOnline: true,
        ),
        mediaQueryData: const MediaQueryData(
          size: Size(1024, 1366),
          padding: EdgeInsets.only(top: 44),
          viewPadding: EdgeInsets.only(top: 44, bottom: 34),
        ),
      );

      final panel = tester.widget<Container>(
        find.byKey(driverHomeBottomPanelSurfaceKey),
      );
      final padding = panel.padding! as EdgeInsets;
      expect(padding.bottom, closeTo(42, 0.01));

      final screenBottom = tester.getSize(find.byType(Scaffold)).height;
      final panelBottom = tester
          .getBottomRight(find.byKey(driverHomeBottomPanelSurfaceKey))
          .dy;
      expect(panelBottom, closeTo(screenBottom, 1.0));
    },
  );
}

Future<FakeDriverAuthNotifier> _pumpHome(
  WidgetTester tester, {
  required AuthState authState,
  required DriverHomeState homeState,
  NavigationLauncherService? navigationLauncher,
  PassengerContactLauncherService? contactLauncher,
  MediaQueryData? mediaQueryData,
}) async {
  SharedPreferences.setMockInitialValues({});
  await LocalStorage.instance.init();
  if (authState.status == AuthStatus.authenticated) {
    FlutterSecureStorage.setMockInitialValues({
      'driver_access_token': 'driver-token',
      'driver_auth_user_data': jsonEncode(authState.userData),
    });
  } else {
    FlutterSecureStorage.setMockInitialValues({});
  }
  final authNotifier = FakeDriverAuthNotifier(authState);
  final homeNotifier = FakeDriverHomeNotifier(
    FakeDriverRideRepository(),
    homeState,
  );
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const DriverHomeScreen()),
      GoRoute(
        path: '/earnings',
        name: RouteNames.driverEarnings,
        builder: (context, state) =>
            const Scaffold(body: Text('earnings-page')),
      ),
      GoRoute(
        path: '/history',
        name: RouteNames.driverHistory,
        builder: (context, state) => const Scaffold(body: Text('history-page')),
      ),
      GoRoute(
        path: '/wallet',
        name: RouteNames.driverWallet,
        builder: (context, state) => const Scaffold(body: Text('wallet-page')),
      ),
      GoRoute(
        path: '/profile',
        name: RouteNames.driverProfile,
        builder: (context, state) => const Scaffold(body: Text('profile-page')),
      ),
      GoRoute(
        path: '/driver-status',
        name: RouteNames.driverStatus,
        builder: (context, state) => const Scaffold(body: Text('status-page')),
      ),
      GoRoute(
        path: '/kyc',
        name: RouteNames.driverKyc,
        builder: (context, state) => const Scaffold(body: Text('kyc-page')),
      ),
      GoRoute(
        path: '/vehicle',
        name: RouteNames.driverVehicle,
        builder: (context, state) => const Scaffold(body: Text('vehicle-page')),
      ),
    ],
  );

  Widget app = MaterialApp.router(
    theme: ThemeData(
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    ),
    routerConfig: router,
  );
  if (mediaQueryData != null) {
    app = MediaQuery(data: mediaQueryData, child: app);
  }

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        driverAuthProvider.overrideWith((ref) => authNotifier),
        driverHomeProvider.overrideWith((ref) => homeNotifier),
        driverWalletRepositoryProvider.overrideWithValue(
          _FakeDriverWalletRepository(),
        ),
        if (navigationLauncher != null)
          driverNavigationLauncherProvider.overrideWithValue(
            navigationLauncher,
          ),
        if (contactLauncher != null)
          driverContactLauncherServiceProvider.overrideWithValue(
            contactLauncher,
          ),
      ],
      child: app,
    ),
  );
  await tester.pumpAndSettle();
  return authNotifier;
}

Future<_HomeHarness> _pumpHomeHarness(
  WidgetTester tester, {
  required AuthState authState,
  required DriverHomeState homeState,
  NavigationLauncherService? navigationLauncher,
  PassengerContactLauncherService? contactLauncher,
  MediaQueryData? mediaQueryData,
}) async {
  SharedPreferences.setMockInitialValues({});
  await LocalStorage.instance.init();
  if (authState.status == AuthStatus.authenticated) {
    FlutterSecureStorage.setMockInitialValues({
      'driver_access_token': 'driver-token',
      'driver_auth_user_data': jsonEncode(authState.userData),
    });
  } else {
    FlutterSecureStorage.setMockInitialValues({});
  }
  final authNotifier = FakeDriverAuthNotifier(authState);
  final homeNotifier = FakeDriverHomeNotifier(
    FakeDriverRideRepository(),
    homeState,
  );
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const DriverHomeScreen()),
      GoRoute(
        path: '/earnings',
        name: RouteNames.driverEarnings,
        builder: (context, state) =>
            const Scaffold(body: Text('earnings-page')),
      ),
      GoRoute(
        path: '/history',
        name: RouteNames.driverHistory,
        builder: (context, state) => const Scaffold(body: Text('history-page')),
      ),
      GoRoute(
        path: '/wallet',
        name: RouteNames.driverWallet,
        builder: (context, state) => const Scaffold(body: Text('wallet-page')),
      ),
      GoRoute(
        path: '/profile',
        name: RouteNames.driverProfile,
        builder: (context, state) => const Scaffold(body: Text('profile-page')),
      ),
      GoRoute(
        path: '/settings',
        name: RouteNames.driverSettings,
        builder: (context, state) =>
            const Scaffold(body: Text('settings-page')),
      ),
      GoRoute(
        path: '/driver-status',
        name: RouteNames.driverStatus,
        builder: (context, state) => const Scaffold(body: Text('status-page')),
      ),
      GoRoute(
        path: '/kyc',
        name: RouteNames.driverKyc,
        builder: (context, state) => const Scaffold(body: Text('kyc-page')),
      ),
      GoRoute(
        path: '/vehicle',
        name: RouteNames.driverVehicle,
        builder: (context, state) => const Scaffold(body: Text('vehicle-page')),
      ),
    ],
  );

  Widget app = MaterialApp.router(
    theme: ThemeData(
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    ),
    routerConfig: router,
  );
  if (mediaQueryData != null) {
    app = MediaQuery(data: mediaQueryData, child: app);
  }

  final container = ProviderContainer(
    overrides: [
      driverAuthProvider.overrideWith((ref) => authNotifier),
      driverHomeProvider.overrideWith((ref) => homeNotifier),
      driverWalletRepositoryProvider.overrideWithValue(
        _FakeDriverWalletRepository(),
      ),
      if (navigationLauncher != null)
        driverNavigationLauncherProvider.overrideWithValue(navigationLauncher),
      if (contactLauncher != null)
        driverContactLauncherServiceProvider.overrideWithValue(contactLauncher),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: app),
  );
  await tester.pumpAndSettle();
  return _HomeHarness(
    authNotifier: authNotifier,
    homeNotifier: homeNotifier,
    container: container,
  );
}

class _HomeHarness {
  const _HomeHarness({
    required this.authNotifier,
    required this.homeNotifier,
    required this.container,
  });

  final FakeDriverAuthNotifier authNotifier;
  final FakeDriverHomeNotifier homeNotifier;
  final ProviderContainer container;
}

class _FakeDriverWalletRepository implements DriverWalletRepository {
  @override
  Future<DriverWalletOverview> fetchWalletOverview() async {
    return const DriverWalletOverview(balance: 0, transactions: []);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _approvedAuthState = AuthState(
  status: AuthStatus.authenticated,
  userData: const {
    'driverId': 14,
    'kycStatus': 'APPROVED',
    'vehicleStatus': 'APPROVED',
    'vehicleId': 7,
  },
);

class _FakeNavigationLauncherService extends NavigationLauncherService {
  int openCalls = 0;
  double? lastLat;
  double? lastLng;

  @override
  Future<bool> openGoogleMapsDriving({
    required double lat,
    required double lng,
    String? label,
  }) async {
    openCalls++;
    lastLat = lat;
    lastLng = lng;
    return true;
  }
}

class _FakePassengerContactLauncherService
    extends PassengerContactLauncherService {
  int phoneCallAttempts = 0;
  int whatsAppAttempts = 0;
  String? lastPhoneNumber;
  String? lastWhatsAppNumber;

  @override
  Future<bool> launchPhoneCall(String? rawPhoneNumber) async {
    phoneCallAttempts++;
    lastPhoneNumber = rawPhoneNumber;
    return rawPhoneNumber != null && rawPhoneNumber.trim().isNotEmpty;
  }

  @override
  Future<bool> launchWhatsApp(String? rawPhoneNumber) async {
    whatsAppAttempts++;
    lastWhatsAppNumber = rawPhoneNumber;
    return rawPhoneNumber != null && rawPhoneNumber.trim().isNotEmpty;
  }
}

void _expectAbove(WidgetTester tester, Finder top, Finder bottom) {
  expect(tester.getTopLeft(top).dy, lessThan(tester.getTopLeft(bottom).dy));
}

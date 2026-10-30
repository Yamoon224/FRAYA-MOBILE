// PARCOURS CHAUFFEUR - étapes 5 à 11 : accueil, passage en ligne, offre, acceptation, trajet,
// arrivée, démarrage, fin de course, encaissement. Vrais écrans + vrai DriverHomeNotifier + vrais dépôts
// branchés sur FakeFrayaBackend (contrat backend). GPS / SDK de navigation / son : non simulables ici.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/router/route_names.dart';
import 'package:fraya_mobile/core/services/pin_migration_service.dart';
import 'package:fraya_mobile/core/utils/extensions.dart';
import 'package:fraya_mobile/data/repositories/driver_ride_repository_impl.dart';
import 'package:fraya_mobile/data/repositories/driver_status_repository_impl.dart';
import 'package:fraya_mobile/data/sources/local_storage.dart';
import 'package:fraya_mobile/data/sources/remote/driver_ride_remote_data_source.dart';
import 'package:fraya_mobile/data/sources/remote/driver_status_remote_data_source.dart';
import 'package:fraya_mobile/domain/models/driver_ride.dart';
import 'package:fraya_mobile/domain/models/driver_wallet_overview.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';
import 'package:fraya_mobile/domain/repositories/driver_wallet_repository.dart';
import 'package:fraya_mobile/features/driver/auth/providers/driver_auth_provider.dart';
import 'package:fraya_mobile/features/driver/home/providers/driver_home_provider.dart';
import 'package:fraya_mobile/features/driver/home/providers/driver_ride_dependencies.dart';
import 'package:fraya_mobile/features/driver/home/providers/driver_status_dependencies.dart';
import 'package:fraya_mobile/features/driver/home/screens/driver_home_screen.dart';
import 'package:fraya_mobile/features/driver/home/widgets/driver_home_top_bar.dart';
import 'package:fraya_mobile/features/driver/status/screens/driver_ride_completion_screen.dart';
import 'package:fraya_mobile/features/driver/wallet/providers/driver_wallet_dependencies.dart';
import 'package:fraya_mobile/shared/models/auth_state.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/driver_test_doubles.dart';
import 'parcours_support.dart';

class _WalletFromBackend implements DriverWalletRepository {
  _WalletFromBackend(this.backend);
  final FakeFrayaBackend backend;
  @override
  Future<DriverWalletOverview> fetchWalletOverview() async =>
      DriverWalletOverview(balance: backend.walletBalance, transactions: const []);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _approved = {
  'userId': 14,
  'driverId': 14,
  'id': 14,
  'kycStatus': 'APPROVED',
  'vehicleStatus': 'APPROVED',
  'vehicleId': 7,
  'firstNames': 'Adama',
  'lastName': 'Traoré',
  'phoneNumber': '0707123456',
};

class _Env {
  _Env(this.container, this.backend, this.auth);
  final ProviderContainer container;
  final FakeFrayaBackend backend;
  final FakeDriverAuthNotifier auth;
}

/// Récupère TOUTES les exceptions de rendu en attente (débordements, etc.).
List<String> drainErrors(WidgetTester t) {
  final out = <String>[];
  Object? e;
  while ((e = t.takeException()) != null) {
    final text = e is FlutterError ? e.toStringDeep() : e.toString();
    out.add(text.split(RegExp(r'[\r\n]+')).take(14).join(' | '));
  }
  return out;
}

/// Taps a text after scrolling it into view; notes when it was off-screen (hors écran) without scrolling.
Future<void> tapText(WidgetTester t, String text, List<String> notes) async {
  final f = find.text(text);
  final h = t.view.physicalSize.height / t.view.devicePixelRatio;
  final y = t.getCenter(f).dy;
  if (y > h) notes.add('"$text" hors écran au premier affichage (y=${y.round()} > hauteur ${h.round()})');
  await t.ensureVisible(f);
  await t.pump();
  await t.tap(f);
}

Future<void> settle(WidgetTester t, [int n = 12]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 150));
  }
}

Future<_Env> pumpHome(WidgetTester tester, FakeFrayaBackend backend, {bool pinDone = true}) async {
  SharedPreferences.setMockInitialValues({});
  await LocalStorage.instance.init();
  if (pinDone) await PinMigrationService().markDone();
  FlutterSecureStorage.setMockInitialValues({
    'driver_access_token': 'driver-token',
    'driver_auth_user_data': jsonEncode(_approved),
  });
  final dio = fakeDio(backend);
  final rideRepo = DriverRideRepositoryImpl(
    remoteDataSource: DriverRideRemoteDataSource(dio: dio),
  );
  final statusRepo = DriverStatusRepositoryImpl(
    remoteDataSource: DriverStatusRemoteDataSource(dio: dio),
  );
  final auth = FakeDriverAuthNotifier(
    AuthState(status: AuthStatus.authenticated, userData: _approved),
  );
  final container = ProviderContainer(
    overrides: [
      driverAuthProvider.overrideWith((ref) => auth),
      driverRideRepositoryProvider.overrideWithValue(rideRepo),
      driverStatusRepositoryProvider.overrideWithValue(statusRepo),
      driverWalletRepositoryProvider.overrideWithValue(_WalletFromBackend(backend)),
    ],
  );
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (c, s) => const DriverHomeScreen()),
      GoRoute(
        path: '/driver-status',
        name: RouteNames.driverStatus,
        builder: (c, s) => DriverRideCompletionScreen(ride: s.extra! as DriverRide),
      ),
      GoRoute(
        path: '/earnings',
        name: RouteNames.driverEarnings,
        builder: (c, s) => const Scaffold(body: Text('earnings-page')),
      ),
      GoRoute(
        path: '/wallet',
        name: RouteNames.driverWallet,
        builder: (c, s) => const Scaffold(body: Text('wallet-page')),
      ),
      for (final r in [
        (RouteNames.driverHistory, '/history'),
        (RouteNames.driverProfile, '/profile'),
        (RouteNames.driverSettings, '/settings'),
        (RouteNames.driverKyc, '/kyc'),
        (RouteNames.driverVehicle, '/vehicle'),
      ])
        GoRoute(
          path: r.$2,
          name: r.$1,
          builder: (c, s) => Scaffold(body: Text('${r.$2}-page')),
        ),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        routerConfig: router,
      ),
    ),
  );
  await settle(tester);
  _lastContainer = container;
  return _Env(container, backend, auth);
}

ProviderContainer? _lastContainer;

Future<void> disposeTree(WidgetTester tester, [ProviderContainer? container]) async {
  await tester.pumpWidget(const SizedBox.shrink());
  container?.dispose();
  await tester.pump(const Duration(seconds: 12));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadRealisticFonts);

  for (final scale in phoneScales) {
    group('Galaxy A25 5G - textScale $scale', () {
      testWidgets(
        'S5-S11 course complète : en ligne -> offre -> accepter -> arrivé -> démarrer -> terminer',
        (tester) async {
          usePhone(tester, textScale: scale);
          final backend = FakeFrayaBackend();
          backend.ride = FakeFrayaBackend.rideJson(id: 501);
          final env = await pumpHome(tester, backend);

          // Étape 5 : accueil, hors ligne, interrupteur actif (compte validé).
          final sw = tester.widget<CupertinoSwitch>(find.byType(CupertinoSwitch));
          expect(sw.value, isFalse);
          expect(sw.onChanged, isNotNull, reason: 'compte validé : peut passer en ligne');
          expect(find.text('Hors ligne'), findsWidgets);

          // Étape 6 : passage en ligne -> PUT /sid-users/me/online + chargement des offres.
          await tester.tap(find.byType(CupertinoSwitch));
          await settle(tester);
          expect(backend.callsTo('PUT', '/sid-users/me/online').length, 1);
          expect(backend.online, isTrue);
          expect(env.container.read(driverHomeProvider).isOnline, isTrue);

          // Étape 7 : l'offre apparaît (GET /rides/maps/available).
          expect(find.text('Nouvelle demande de course'), findsOneWidget);
          expect(find.text('Accepter'), findsOneWidget);
          expect(find.text('Refuser'), findsOneWidget);
          expect(find.text('Gain estime'), findsOneWidget);
          expect(find.text(3200.toCFA), findsWidgets);
          expect(find.textContaining('Koffi'), findsWidgets);
          final errs = <String>[...drainErrors(tester).map((e) => '[apres-offre] $e')];

          // Étape 8 : acceptation -> POST accept avec vehicleId=7, course active "accepted".
          await tester.tap(find.text('Accepter'));
          await settle(tester);
          final acceptCalls = backend.callsTo('POST', '/accept').toList();
          expect(acceptCalls.length, 1);
          expect((acceptCalls.single.data as Map)['vehicleId'], 7);
          final active = env.container.read(driverHomeProvider).activeRide;
          expect(active, isNotNull);
          expect(active!.status, RideStatus.accepted);
          expect(find.text('Je suis arrivé'), findsOneWidget);
          expect(find.text('Annuler la course'), findsOneWidget);
          errs.addAll(drainErrors(tester).map((e) => '[apres-accept] $e'));

          // Étape 10 : arrivée au point de prise en charge.
          final notes = <String>[];
          await tapText(tester, 'Je suis arrivé', notes);
          await settle(tester);
          errs.addAll(drainErrors(tester).map((e) => '[apres-arrivee] $e'));
          expect(backend.callsTo('POST', '/arrived').length, 1);
          expect(
            env.container.read(driverHomeProvider).activeRide!.status,
            RideStatus.arrived,
          );
          expect(find.text('Démarrer la course'), findsOneWidget);

          // Étape 11a : démarrage de la course.
          // ignore: avoid_print
          print('ARRIVED scale=$scale bouton Démarrer y=${tester.getCenter(find.text('Démarrer la course')).dy} / écran ${tester.view.physicalSize.height / tester.view.devicePixelRatio}');
          await tapText(tester, 'Démarrer la course', notes);
          await settle(tester);
          expect(backend.callsTo('POST', '/start').length, 1);
          expect(
            env.container.read(driverHomeProvider).activeRide!.status,
            RideStatus.inProgress,
          );
          expect(find.text('Terminer la course'), findsOneWidget);

          // Étape 11b : "Terminer la course" ouvre l'écran d'encaissement avec le montant.
          errs.addAll(drainErrors(tester).map((e) => '[apres-demarrage] $e'));
          await tapText(tester, 'Terminer la course', notes);
          await settle(tester);
          errs.addAll(drainErrors(tester).map((e) => '[ecran-fin] $e'));
          // ignore: avoid_print
          print('LAYOUT scale=$scale: $notes');
          expect(find.text('Clôturer la course'), findsOneWidget);
          final cta = find.textContaining('Terminer et recevoir');
          notes.add('bouton "Terminer et recevoir" construit sans défilement: ${cta.evaluate().isNotEmpty}');
          await tester.scrollUntilVisible(cta, 200, scrollable: find.byType(Scrollable).first);
          await tester.ensureVisible(cta);
          await tester.pump();
          expect(find.text('Terminer et recevoir ${3200.toCFA}'), findsOneWidget);
          // ignore: avoid_print
          print('LAYOUT2 scale=$scale: $notes');

          // Étape 12 : encaissement (espèces par défaut) -> POST complete.
          await tester.ensureVisible(find.textContaining('Terminer et recevoir'));
          await tester.tap(find.textContaining('Terminer et recevoir'));
          await settle(tester);
          final completeCalls = backend.callsTo('POST', '/complete').toList();
          expect(completeCalls.length, 1);
          final body = completeCalls.single.data as Map;
          expect(body['finalPrice'], '3200');
          expect(find.text('Retour au tableau de bord'), findsOneWidget);
          expect(backend.ride!['statusRace'], 'COMPLETED');
          errs.addAll(drainErrors(tester).map((e) => '[apres-encaissement] $e'));
          // ignore: avoid_print
          print('ERRORS scale=$scale: ${errs.length} ${errs.join(' ===== ')}');
          expect(errs, isEmpty, reason: 'exceptions de rendu pendant le parcours');
          await disposeTree(tester, _lastContainer);
        },
      );
    });
  }

  testWidgets('S6 compte NON validé : impossible de passer en ligne, message admin', (
    tester,
  ) async {
    usePhone(tester);
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.instance.init();
    final backend = FakeFrayaBackend();
    final dio = fakeDio(backend);
    final container = ProviderContainer(
      overrides: [
        driverAuthProvider.overrideWith(
          (ref) => FakeDriverAuthNotifier(
            AuthState(
              status: AuthStatus.authenticated,
              userData: const {
                'userId': 14,
                'driverId': 14,
                'kycStatus': 'PENDING_VALIDATION',
                'vehicleStatus': 'APPROVED',
                'vehicleId': 7,
              },
            ),
          ),
        ),
        driverRideRepositoryProvider.overrideWithValue(
          DriverRideRepositoryImpl(remoteDataSource: DriverRideRemoteDataSource(dio: dio)),
        ),
        driverStatusRepositoryProvider.overrideWithValue(
          DriverStatusRepositoryImpl(remoteDataSource: DriverStatusRemoteDataSource(dio: dio)),
        ),
        driverWalletRepositoryProvider.overrideWithValue(_WalletFromBackend(backend)),
      ],
    );
    _lastContainer = container;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DriverHomeScreen()),
      ),
    );
    await settle(tester);
    expect(find.text('Validation admin en cours'), findsOneWidget);
    final sw = tester.widget<CupertinoSwitch>(find.byType(CupertinoSwitch));
    expect(sw.onChanged, isNull);
    expect(backend.callsTo('PUT', '/sid-users/me/online'), isEmpty);
    await disposeTree(tester, _lastContainer);
  });

  testWidgets('S10 arrivée refusée par le serveur (trop loin) : message affiché, statut inchangé', (
    tester,
  ) async {
    usePhone(tester);
    final backend = FakeFrayaBackend()
      ..ride = FakeFrayaBackend.rideJson(id: 502)
      ..farFromPickup = true;
    final env = await pumpHome(tester, backend);
    await tester.tap(find.byType(CupertinoSwitch));
    await settle(tester);
    await tester.tap(find.text('Accepter'));
    await settle(tester);
    await tester.tap(find.text('Je suis arrivé'));
    await settle(tester, 3);
    final state = env.container.read(driverHomeProvider);
    expect(state.activeRide!.status, RideStatus.accepted);
    expect(find.textContaining('trop loin du point de départ'), findsWidgets);
    await disposeTree(tester, _lastContainer);
  });

  testWidgets('S8 offre déjà prise par un autre chauffeur (409) : message clair, pas de course active', (
    tester,
  ) async {
    usePhone(tester);
    final backend = FakeFrayaBackend()..ride = FakeFrayaBackend.rideJson(id: 503);
    final env = await pumpHome(tester, backend);
    await tester.tap(find.byType(CupertinoSwitch));
    await settle(tester);
    expect(find.text('Accepter'), findsOneWidget);
    // Un autre chauffeur prend la course entre l'affichage et le tap.
    backend.ride!['statusRace'] = 'DRIVER_ASSIGNED';
    backend.ride!['vehicle'] = {'id': 9, 'range': 'MAGIC', 'sidUserId': 99};
    await tester.tap(find.text('Accepter'));
    await settle(tester, 3);
    final state = env.container.read(driverHomeProvider);
    expect(state.activeRide, isNull);
    expect(find.textContaining('déjà été attribuée'), findsWidgets);
    await disposeTree(tester, _lastContainer);
  });

  testWidgets('S7 refuser une offre la masque et la mémorise localement', (tester) async {
    usePhone(tester);
    final backend = FakeFrayaBackend()..ride = FakeFrayaBackend.rideJson(id: 504);
    final env = await pumpHome(tester, backend);
    await tester.tap(find.byType(CupertinoSwitch));
    await settle(tester);
    await tester.tap(find.text('Refuser'));
    await settle(tester);
    expect(find.text('Nouvelle demande de course'), findsNothing);
    expect(env.container.read(driverHomeProvider).ignoredIncomingRideIds, contains('504'));
    await disposeTree(tester, _lastContainer);
  });

  testWidgets('S9 navigation vers le passager : lancement in-app (SDK réel non testable)', (
    tester,
  ) async {
    usePhone(tester);
    final backend = FakeFrayaBackend()..ride = FakeFrayaBackend.rideJson(id: 505);
    await pumpHome(tester, backend);
    await tester.tap(find.byType(CupertinoSwitch));
    await settle(tester);
    await tester.tap(find.text('Accepter'));
    await settle(tester);
    final nav = find.byIcon(Icons.navigation_rounded);
    expect(nav, findsOneWidget);
    // On appelle le callback du bouton (voir le test S9b pour la zone de tap réelle).
    tester.widget<DriverHomeTopBar>(find.byType(DriverHomeTopBar)).onNavigationPressed!();
    await settle(tester);
    // Hors Android le widget de guidage est un substitut texte : le SDK Navigation n'est PAS exercé.
    expect(find.textContaining('navigation:toPickup'), findsOneWidget);
    await disposeTree(tester, _lastContainer);
  });

  for (final scale in phoneScales) {
    testWidgets('S9b bouton Navigation accessible au doigt pendant la course (textScale $scale)', (
      tester,
    ) async {
      usePhone(tester, textScale: scale);
      final backend = FakeFrayaBackend()..ride = FakeFrayaBackend.rideJson(id: 507);
      await pumpHome(tester, backend);
      await tester.tap(find.byType(CupertinoSwitch));
      await settle(tester);
      await tester.tap(find.text('Accepter'));
      await settle(tester);
      final navIcon = find.byIcon(Icons.navigation_rounded);
      final badge = find.byType(DriverHomeFloatingStatusBadge);
      // ignore: avoid_print
      print('S9b scale=$scale nav=${tester.getRect(navIcon)} badge=${tester.getRect(badge)}');
      final back = find.byIcon(Icons.arrow_back_rounded);
      // ignore: avoid_print
      print('S9b scale=$scale back-hitTestable=${back.hitTestable().evaluate().isNotEmpty} nav-hitTestable=${navIcon.hitTestable().evaluate().isNotEmpty}');
      expect(
        navIcon.hitTestable(),
        findsOneWidget,
        reason: 'le chauffeur doit pouvoir toucher le bouton Navigation (icône masquée par le badge de statut ?)',
      );
      await disposeTree(tester, _lastContainer);
    });
  }

  testWidgets('S10c bouton "Démarrer la course" visible sans faire défiler le panneau (A25, 1.0)', (
    tester,
  ) async {
    usePhone(tester);
    final backend = FakeFrayaBackend()..ride = FakeFrayaBackend.rideJson(id: 508);
    await pumpHome(tester, backend);
    await tester.tap(find.byType(CupertinoSwitch));
    await settle(tester);
    await tester.tap(find.text('Accepter'));
    await settle(tester);
    await tester.tap(find.text('Je suis arrivé'));
    await settle(tester);
    final h = tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final y = tester.getCenter(find.text('Démarrer la course')).dy;
    expect(y, lessThan(h), reason: 'Démarrer la course à y=$y pour un écran de $h dp');
    await disposeTree(tester, _lastContainer);
  });

  testWidgets('S19 hors ligne : refusé pendant une course, accepté sinon (PUT online=false)', (
    tester,
  ) async {
    usePhone(tester);
    final backend = FakeFrayaBackend()..ride = FakeFrayaBackend.rideJson(id: 506);
    final env = await pumpHome(tester, backend);
    final notifier = env.container.read(driverHomeProvider.notifier);
    await tester.tap(find.byType(CupertinoSwitch));
    await settle(tester);
    await tester.tap(find.text('Accepter'));
    await settle(tester);
    // Pendant la course : impossible de passer hors ligne.
    unawaited(notifier.setOnline(false));
    await settle(tester);
    expect(env.container.read(driverHomeProvider).isOnline, isTrue);
    expect(
      env.container.read(driverHomeProvider).errorMessage,
      contains('pas passer hors ligne'),
    );
    // Course annulée côté chauffeur puis hors ligne.
    unawaited(notifier.cancelRide(rideId: '506', reason: 'Annulation chauffeur'));
    await settle(tester);
    expect(env.container.read(driverHomeProvider).activeRide, isNull);
    expect(backend.ride!['statusRace'], 'CANCELLED_DRIVER');
    unawaited(notifier.setOnline(false));
    await settle(tester);
    expect(env.container.read(driverHomeProvider).isOnline, isFalse);
    expect(backend.online, isFalse);
    await disposeTree(tester, _lastContainer);
  });

  testWidgets('S12 montant affiché vs prix serveur : l\'écran de fin ignore le prix calculé par le serveur', (
    tester,
  ) async {
    usePhone(tester);
    // Attente de 8 min au point de prise en charge (arrivée -> démarrage).
    final arrived = DateTime.now().subtract(const Duration(minutes: 8));
    final started = DateTime.now();
    final ride = DriverRide.fromMap(
      FakeFrayaBackend.rideJson(
        id: 600,
        status: 'IN_PROGRESS',
        driverUserId: 14,
        vehicleId: 7,
        pickupArrivedAt: arrived.toIso8601String(),
        departureDate: started.toIso8601String(),
      ),
    );
    final backend = FakeFrayaBackend()
      ..ride = FakeFrayaBackend.rideJson(
        id: 600,
        status: 'IN_PROGRESS',
        driverUserId: 14,
        vehicleId: 7,
      )
      ..serverFinalPrice = 3200;
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.instance.init();
    final dio = fakeDio(backend);
    final container = ProviderContainer(
      overrides: [
        driverAuthProvider.overrideWith(
          (ref) => FakeDriverAuthNotifier(
            AuthState(status: AuthStatus.authenticated, userData: _approved),
          ),
        ),
        driverRideRepositoryProvider.overrideWithValue(
          DriverRideRepositoryImpl(remoteDataSource: DriverRideRemoteDataSource(dio: dio)),
        ),
        driverStatusRepositoryProvider.overrideWithValue(
          DriverStatusRepositoryImpl(remoteDataSource: DriverStatusRemoteDataSource(dio: dio)),
        ),
        driverWalletRepositoryProvider.overrideWithValue(_WalletFromBackend(backend)),
      ],
    );
    _lastContainer = container;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: DriverRideCompletionScreen(ride: ride)),
      ),
    );
    await settle(tester);

    // Le client calcule : 3200 + ceil((480-300)/60)=3 min * 100 = 3500 FCFA (franchise 300 s codée en dur).
    await tester.scrollUntilVisible(
      find.textContaining('Terminer et recevoir'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Terminer et recevoir ${3500.toCFA}'), findsOneWidget);
    await tester.tap(find.textContaining('Terminer et recevoir'));
    await settle(tester);
    final body = backend.callsTo('POST', '/complete').single.data as Map;
    // Le client envoie des secondes DÉJÀ NETTES de la franchise (480-300=180) ; le backend, lui,
    // attend l'attente brute au départ (« Temps d'attente au départ en secondes ») et retranche sa
    // propre franchise -> double déduction. Le prix serveur (3200) n'est jamais affiché au chauffeur.
    expect(body['additionnalFree'], inInclusiveRange(179, 181));
    expect(body['finalPrice'], '3500');
    expect(find.textContaining('3 200'), findsNothing);
    expect(find.textContaining('commission'), findsNothing);
    await disposeTree(tester, _lastContainer);
  });
}



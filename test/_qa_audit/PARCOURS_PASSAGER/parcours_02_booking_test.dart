// PARCOURS PASSAGER - etapes 5 a 10 : recherche d'adresse, gammes/prix, commande,
// recherche chauffeur, suivi, arrivee, course en cours, fin de course.
// Tout est simule au niveau providers/widgets avec des faux conformes au backend NestJS
// (statusRace : REQUESTED, SEARCHING_DRIVER, DRIVER_ASSIGNED, DRIVER_EN_ROUTE,
//  WAITING_FOR_PASSENGER, IN_PROGRESS, COMPLETED, CANCELLED_*).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/models/directions_models.dart';
import 'package:fraya_mobile/core/models/places_models.dart';
import 'package:fraya_mobile/core/models/ride_category.dart';
import 'package:fraya_mobile/core/services/passenger_contact_launcher_service.dart';
import 'package:fraya_mobile/core/services/places_service.dart';
import 'package:fraya_mobile/core/utils/extensions.dart';
import 'package:fraya_mobile/domain/models/active_ride.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';
import 'package:fraya_mobile/domain/repositories/booking_repository.dart';
import 'package:fraya_mobile/features/passenger/auth/providers/passenger_auth_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/active_ride_check_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/active_ride_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_dependencies.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_flow_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/passenger_contact_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/payment_method_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/ride_categories_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/route_directions_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/widgets/active_ride_sheet.dart';
import 'package:fraya_mobile/shared/models/auth_state.dart';
import 'package:fraya_mobile/shared/providers/location_provider.dart';
import 'package:fraya_mobile/shared/providers/places_provider.dart';

import 'qa_support.dart';

class _FakePlacesService extends PlacesService {
  _FakePlacesService({this.suggestions = const [], this.details});
  final List<PlaceSuggestion> suggestions;
  final PlaceDetails? details;

  @override
  Future<List<PlaceSuggestion>> getAutocompleteSuggestions(
    String query, {
    String? sessionToken,
    String language = 'fr',
    String components = 'country:ci',
    double? originLat,
    double? originLng,
    bool bypassCache = false,
  }) async => suggestions;

  @override
  Future<PlaceDetails?> getPlaceDetails(
    String placeId, {
    String? sessionToken,
    String language = 'fr',
  }) async => details;
}

const _magic = RideCategory(
  id: 'MAGIC', name: 'Magic', description: 'Eco', price: 1500, seats: 4, iconAsset: 'assets/images/magic.png');
const _gladiateur = RideCategory(
  id: 'GLADIATEUR', name: 'Gladiateur', description: 'Confort', price: 2500, seats: 4, iconAsset: 'assets/images/magic.png');
const _elite = RideCategory(
  id: 'ELITE', name: 'Elite', description: 'Premium', price: 4000, seats: 4, iconAsset: 'assets/images/magic.png');

const _angre = PlaceDetails(
  placeId: 'ChIJangre8tranche',
  name: 'Angré 8e tranche',
  address: 'Angré 8e tranche, Cocody, Abidjan',
  latitude: 5.4012,
  longitude: -3.9876,
);
const _fhb = PlaceDetails(
  placeId: 'ChIJuniversitefhb',
  name: 'Université Félix Houphouët-Boigny',
  address: 'Université FHB, Cocody, Abidjan',
  latitude: 5.3430,
  longitude: -4.0010,
);

final _directions = DirectionsResult(
  routes: const [
    DirectionsRoute(
      encodedPolyline: '',
      distanceText: '6.4 km',
      distanceValue: 6400,
      durationText: '18 min',
      durationValue: 1080,
      arrivalTime: null,
      durationInTrafficValue: 1260,
      trafficSegments: [],
      hasTrafficData: false,
    ),
  ],
);

ProviderContainer _container(QaBookingRepository repo, {PlacesService? places}) {
  return ProviderContainer(
    overrides: [
      passengerAuthProvider.overrideWith(
        (ref) => PresetAuthNotifier(AuthState(
          status: AuthStatus.authenticated,
          userData: {'id': 7, 'firstNames': 'Aminata'},
        )),
      ),
      activeRideCheckProvider.overrideWith((ref) async => null),
      passengerBookingRepositoryProvider.overrideWithValue(repo),
      routeDirectionsProvider.overrideWith((ref) async => _directions),
      currentLocationProvider.overrideWith((ref) => Stream.value(null)),
      passengerLocationSnapshotProvider.overrideWith((ref) async => null),
      formattedAddressProvider.overrideWith((ref) => 'Angré 8e tranche, Cocody'),
      if (places != null) placesServiceProvider.overrideWithValue(places),
    ],
  );
}

Future<void> _flush() async {
  for (var i = 0; i < 4; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  setUpAll(() async {
    await loadRealisticFonts();
  });
  setUp(() async => initQaEnvironment(secure: {
        'access_token': 'jwt-aminata',
        'auth_user_data': '{"id":7}',
      }));

  group('ETAPE 5 - saisie depart / destination (recherche d\'adresse)', () {
    test('autocomplete (country:ci, >=3 car.) renvoie les adresses d\'Abidjan', () async {
      final container = _container(
        QaBookingRepository(),
        places: _FakePlacesService(suggestions: [
          PlaceSuggestion(
            placeId: _fhb.placeId,
            description: 'Université FHB, Cocody, Abidjan',
            mainText: 'Université FHB',
            secondaryText: 'Cocody, Abidjan',
          ),
        ]),
      );
      addTearDown(container.dispose);
      final q = container.listen(searchQueryProvider, (_, _) {});
      addTearDown(q.close);
      container.read(searchQueryProvider.notifier).updateQuery('fhb coc');
      await Future<void>.delayed(const Duration(milliseconds: 600));
      final sub = container.listen(placeSuggestionsProvider, (_, _) {});
      addTearDown(sub.close);
      final list = await container.read(placeSuggestionsProvider.future);
      expect(list.map((s) => s.mainText), contains('Université FHB'));
    });

    test('hors-ligne : une panne reseau est affichee comme "aucun resultat" (indiscernable)', () async {
      // Le faux service renvoie [] exactement comme PlacesService reel apres exception (catch -> []).
      final container = _container(QaBookingRepository(), places: _FakePlacesService());
      addTearDown(container.dispose);
      final q = container.listen(searchQueryProvider, (_, _) {});
      addTearDown(q.close);
      container.read(searchQueryProvider.notifier).updateQuery('sococe');
      await Future<void>.delayed(const Duration(milliseconds: 600));
      final sub = container.listen(placeSuggestionsProvider, (_, _) {});
      addTearDown(sub.close);
      final list = await container.read(placeSuggestionsProvider.future);
      expect(list, isEmpty);
      // CONSTAT (revue code places_service.dart:104-107) : aucune erreur remontee a l'UI.
    });

    test('echec reseau sur getPlaceDetails : le depart deja choisi est conserve', () async {
      final container = _container(QaBookingRepository(), places: _FakePlacesService(details: null));
      addTearDown(container.dispose);
      container.read(selectedPickupProvider.notifier).setPlace(_angre);
      expect(container.read(selectedPickupProvider)?.placeId, _angre.placeId);
      final ok = await container.read(selectedPickupProvider.notifier).selectPlace('ChIJriviera3');
      expect(ok, isFalse);
      expect(container.read(selectedPickupProvider)?.placeId, _angre.placeId,
          reason: 'attendu : on garde le depart precedent quand le nouveau lieu ne se charge pas (4G instable)');
    });

    test('echec reseau sur getPlaceDetails : la destination deja choisie est conservee', () async {
      final container = _container(QaBookingRepository(), places: _FakePlacesService(details: null));
      addTearDown(container.dispose);
      container.read(selectedDestinationProvider.notifier).setPlace(_fhb);
      final ok = await container.read(selectedDestinationProvider.notifier).selectPlace('ChIJplateau');
      expect(ok, isFalse);
      expect(container.read(selectedDestinationProvider)?.placeId, _fhb.placeId);
    });
  });

  group('ETAPE 6 - gamme de vehicule et prix', () {
    test('3 gammes avec prix backend en FCFA sans centimes, MAGIC preselectionnee', () async {
      final repo = QaBookingRepository(
        categories: [_magic, _gladiateur, _elite],
        prices: {
          'MAGIC': const RidePriceEstimate(range: 'MAGIC', totalPrice: 2200, amountReceived: 2000),
          'GLADIATEUR': const RidePriceEstimate(range: 'GLADIATEUR', totalPrice: 3300, amountReceived: 3000),
          'ELITE': const RidePriceEstimate(range: 'ELITE', totalPrice: 5500, amountReceived: 5000),
        },
      );
      final container = _container(repo);
      addTearDown(container.dispose);
      container.read(selectedPickupProvider.notifier).setPlace(_angre);
      container.read(selectedDestinationProvider.notifier).setPlace(_fhb);
      final sub = container.listen(selectedCategoryProvider, (_, _) {});
      addTearDown(sub.close);
      final cats = await container.read(rideCategoriesProvider.future);
      expect(cats.map((c) => c.id), ['MAGIC', 'GLADIATEUR', 'ELITE']);
      expect(cats.map((c) => c.price), [2200, 3300, 5500]);
      await _flush();
      expect(container.read(selectedCategoryProvider)?.id, 'MAGIC');
      expect(2200.toCFA.replaceAll(RegExp(r'\s'), ' '), '2 200 FCFA');
      expect(2200.toCFA, isNot(contains(',')), reason: 'pas de centimes');
    });

    test('prix indisponible : message d\'erreur clair, aucune gamme proposee', () async {
      final repo = QaBookingRepository(categories: [_magic], prices: const {});
      final container = _container(repo);
      addTearDown(container.dispose);
      container.read(selectedPickupProvider.notifier).setPlace(_angre);
      container.read(selectedDestinationProvider.notifier).setPlace(_fhb);
      final cats = await container.read(rideCategoriesProvider.future);
      expect(cats, isEmpty);
      expect(container.read(bookingErrorProvider), pricingUnavailableMessage);
    });
  });

  group('ETAPES 7-8 - commande, recherche, chauffeur assigne', () {
    test('commande Mobile Money (Orange) : payload backend + passage en recherche', () async {
      final status = <String>['REQUESTED'];
      final repo = QaBookingRepository(
        categories: [_magic, _gladiateur, _elite],
        activeRideHandler: (_, id) => ActiveRide.fromMap(backendRideMap(statusRace: status.last, id: 'ride_qa_1')),
      );
      final container = _container(repo);
      addTearDown(container.dispose);
      container.read(selectedPickupProvider.notifier).setPlace(_angre);
      container.read(selectedDestinationProvider.notifier).setPlace(_fhb);
      container.read(selectedCategoryProvider.notifier).select(_gladiateur.copyWith(price: 3300, amountReceived: 3000));
      container.read(selectedPaymentMethodProvider.notifier).state = PaymentMethod.orangeMoney;
      await container.read(routeDirectionsProvider.future);

      final flow = container.read(bookingFlowProvider.notifier);
      await flow.startSearching();

      expect(repo.requests, hasLength(1));
      final p = repo.requests.single;
      expect(p.userId, 7);
      expect(p.requestedRange, 'GLADIATEUR');
      expect(p.estimatedPrice, 3300);
      expect(p.amountReceived, 3000);
      expect(p.paymentMethod, 'MOBILE_MONEY');
      expect(p.arrivalPlaceId, 'ChIJuniversitefhb');
      expect(p.departureAddress.toLowerCase(), contains('angr'));
      expect(container.read(bookingFlowProvider), BookingFlowState.searching);

      // L'operateur choisi (Orange Money / Wave / MTN / Moov) n'est pas transmis : tout part en MOBILE_MONEY.
      for (final m in PaymentMethod.values.where((m) => m != PaymentMethod.cash)) {
        expect(m.apiValue, 'MOBILE_MONEY');
      }
      container.read(bookingFlowProvider.notifier).stopPolling();
    });

    test('chauffeur assigne -> en route -> arrive -> en cours -> termine (statusRace backend)', () async {
      var current = 'REQUESTED';
      final repo = QaBookingRepository(
        activeRideHandler: (_, id) => ActiveRide.fromMap(backendRideMap(statusRace: current)),
      );
      final container = _container(repo);
      addTearDown(container.dispose);
      await _flush();
      final flow = container.read(bookingFlowProvider.notifier);

      Future<BookingFlowState> at(String s) async {
        current = s;
        await flow.handleRideAcceptedRealtime('ride_qa_1');
        return container.read(bookingFlowProvider);
      }

      expect(await at('SEARCHING_DRIVER'), BookingFlowState.searching);
      expect(await at('DRIVER_ASSIGNED'), BookingFlowState.driverAssigned);
      expect(container.read(activeRideControllerProvider)?.driverName, 'Yao Brou');
      expect(container.read(activeRideControllerProvider)?.carPlate, '1234 AB 01');
      expect(await at('DRIVER_EN_ROUTE'), BookingFlowState.driverAssigned);
      expect(await at('WAITING_FOR_PASSENGER'), BookingFlowState.arrived);
      expect(await at('IN_PROGRESS'), BookingFlowState.inProgress);
      expect(await at('COMPLETED'), BookingFlowState.completed);
      expect(container.read(completedRideControllerProvider)?.estimatedPrice, 2500);
      expect(container.read(activeRideControllerProvider), isNull);
      flow.stopPolling();
    });

    test('annulation pendant la recherche : cancelRide appele, retour accueil', () async {
      var current = 'SEARCHING_DRIVER';
      final repo = QaBookingRepository(
        activeRideHandler: (_, id) => ActiveRide.fromMap(backendRideMap(statusRace: current)),
      );
      final container = _container(repo);
      addTearDown(container.dispose);
      await _flush();
      final flow = container.read(bookingFlowProvider.notifier);
      await flow.handleRideAcceptedRealtime('ride_qa_1');
      expect(container.read(bookingFlowProvider), BookingFlowState.searching);
      await flow.cancelSearching(reason: 'Changement de plan');
      expect(repo.cancelled, ['ride_qa_1']);
      expect(container.read(bookingFlowProvider), BookingFlowState.idle);
    });

    test('echec requestRide (4G coupee) : etat searchFailed + message utilisateur', () async {
      final repo = QaBookingRepository(
        categories: [_magic],
        requestRideHandler: (_) async => throw TimeoutException('connexion perdue'),
      );
      final container = _container(repo);
      addTearDown(container.dispose);
      container.read(selectedPickupProvider.notifier).setPlace(_angre);
      container.read(selectedDestinationProvider.notifier).setPlace(_fhb);
      container.read(selectedCategoryProvider.notifier).select(_magic);
      await container.read(routeDirectionsProvider.future);
      await container.read(bookingFlowProvider.notifier).startSearching();
      expect(container.read(bookingFlowProvider), BookingFlowState.searchFailed);
      expect(container.read(bookingErrorProvider), isNotNull);
    });

    test('depart/destination absents : retour silencieux a l apercu sans message', () async {
      final repo = QaBookingRepository(categories: [_magic]);
      final container = _container(repo);
      addTearDown(container.dispose);
      container.read(selectedCategoryProvider.notifier).select(_magic);
      await container.read(bookingFlowProvider.notifier).startSearching();
      expect(repo.requests, isEmpty);
      expect(container.read(bookingFlowProvider), BookingFlowState.routePreview);
      expect(container.read(bookingErrorProvider), isNull,
          reason: 'CONSTAT : aucun message si le GPS/depart est indisponible');
    });
  });

  group('Mapping des statuts backend (RideStatus.fromBackend)', () {
    const expected = <String, RideStatus>{
      'REQUESTED': RideStatus.pending,
      'SEARCHING_DRIVER': RideStatus.pending,
      'DRIVER_ASSIGNED': RideStatus.accepted,
      'DRIVER_EN_ROUTE': RideStatus.accepted,
      'WAITING_FOR_PASSENGER': RideStatus.arrived,
      'IN_PROGRESS': RideStatus.inProgress,
      'COMPLETED': RideStatus.completed,
      'CANCELLED_PASSENGER': RideStatus.cancelled,
      'CANCELLED_DRIVER': RideStatus.cancelled,
      'CANCELLED_SYSTEM': RideStatus.cancelled, // course annulee automatiquement : "Aucun chauffeur disponible"
    };
    for (final e in expected.entries) {
      test('${e.key} -> ${e.value.name}', () {
        expect(RideStatus.fromBackend(e.key), e.value);
      });
    }
  });

  group('Widgets : feuille de course active (Galaxy A15, textScale 1.0 et 1.3)', () {
    Future<void> pumpSheet(WidgetTester tester, String statusRace, {double scale = 1.0, PassengerContactLauncherService? launcher}) async {
      useGalaxyA15(tester);
      final ride = ActiveRide.fromMap(backendRideMap(statusRace: statusRace));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeRideControllerProvider.overrideWithValue(ride),
            if (launcher != null) passengerContactLauncherServiceProvider.overrideWithValue(launcher),
          ],
          child: MaterialApp(
            builder: (c, child) => MediaQuery(
              data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const Scaffold(body: Align(alignment: Alignment.bottomCenter, child: ActiveRideSheet())),
          ),
        ),
      );
      await tester.pump();
    }

    for (final scale in [1.0, 1.3]) {
      for (final s in ['DRIVER_ASSIGNED', 'WAITING_FOR_PASSENGER', 'IN_PROGRESS']) {
        testWidgets('$s a textScale $scale : chauffeur, plaque, prix, pas d overflow', (tester) async {
          await pumpSheet(tester, s, scale: scale);
          expect(find.text('Yao Brou'), findsWidgets);
          expect(find.textContaining('1234 AB 01'), findsWidgets);
          expect(find.textContaining('FCFA'), findsWidgets);
          expect(tester.takeException(), isNull);
          if (s == 'DRIVER_ASSIGNED') {
            expect(find.text('Annuler la course'), findsOneWidget);
          } else {
            expect(find.text('Annuler la course'), findsNothing);
          }
        });
      }
    }

    testWidgets('appeler le chauffeur : numero 05 01 02 03 04 compose via tel:', (tester) async {
      final launcher = _RecordingLauncher();
      await pumpSheet(tester, 'DRIVER_ASSIGNED', launcher: launcher);
      await tester.tap(find.byIcon(Icons.call_outlined));
      await tester.pump();
      expect(launcher.calls, [Uri(scheme: 'tel', path: '0501020304').toString()]);
    });

    testWidgets('WhatsApp du chauffeur : indicatif 225 ajoute pour un numero a 10 chiffres', (tester) async {
      final launcher = _RecordingLauncher();
      await pumpSheet(tester, 'DRIVER_ASSIGNED', launcher: launcher);
      await tester.tap(find.byIcon(Icons.call_outlined).first);
      await tester.pump();
      launcher.calls.clear();
      await launcher.launchWhatsApp('05 01 02 03 04');
      expect(launcher.calls.first, contains('phone=2250501020304'));
    });

    testWidgets('chauffeur sans numero : appel refuse avec message', (tester) async {
      final launcher = _RecordingLauncher();
      useGalaxyA15(tester);
      final ride = ActiveRide.fromMap(backendRideMap(statusRace: 'DRIVER_ASSIGNED', driverPhone: null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeRideControllerProvider.overrideWithValue(ride),
            passengerContactLauncherServiceProvider.overrideWithValue(launcher),
          ],
          child: const MaterialApp(home: Scaffold(body: Align(alignment: Alignment.bottomCenter, child: ActiveRideSheet()))),
        ),
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.call_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('indisponible'), findsOneWidget);
      expect(launcher.calls, isEmpty);
      await tester.pump(const Duration(seconds: 11));
    });
  });
}

class _RecordingLauncher extends PassengerContactLauncherService {
  _RecordingLauncher();
  final calls = <String>[];

  @override
  Future<bool> canLaunch(Uri uri) async => true;

  @override
  Future<bool> launch(Uri uri) async {
    calls.add(uri.toString());
    return true;
  }
}

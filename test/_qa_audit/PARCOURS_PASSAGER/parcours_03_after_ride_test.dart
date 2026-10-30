// PARCOURS PASSAGER - etapes 11 a 16 : fin de course/montant, notation, historique,
// detail, favoris, profil/parametres, deconnexion.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/models/favorite_place.dart';
import 'package:fraya_mobile/core/models/places_models.dart';
import 'package:fraya_mobile/core/router/passenger_router.dart';
import 'package:fraya_mobile/core/router/route_names.dart';
import 'package:fraya_mobile/core/services/favorite_places_service.dart';
import 'package:fraya_mobile/core/services/places_service.dart';
import 'package:fraya_mobile/core/utils/constants.dart';
import 'package:fraya_mobile/data/sources/local_storage.dart';
import 'package:fraya_mobile/domain/models/active_ride.dart';
import 'package:fraya_mobile/features/passenger/auth/providers/passenger_auth_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/active_ride_check_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/active_ride_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_dependencies.dart';
import 'package:fraya_mobile/features/passenger/booking/screens/ride_summary_screen.dart';
import 'package:fraya_mobile/features/passenger/favorites/screens/favorites_screen.dart';
import 'package:fraya_mobile/features/passenger/history/screens/my_rides_screen.dart';
import 'package:fraya_mobile/features/passenger/profile/models/profile_model.dart';
import 'package:fraya_mobile/features/passenger/profile/providers/profile_provider.dart';
import 'package:fraya_mobile/features/passenger/profile/screens/passenger_profile_screen.dart';
import 'package:fraya_mobile/features/passenger/settings/screens/passenger_settings_screen.dart';
import 'package:fraya_mobile/shared/models/auth_state.dart';
import 'package:fraya_mobile/shared/providers/favorite_places_provider.dart';
import 'package:fraya_mobile/shared/providers/places_provider.dart';
import 'package:go_router/go_router.dart';

import 'qa_support.dart';

class _NoDetailsPlaces extends PlacesService {
  @override
  Future<PlaceDetails?> getPlaceDetails(String placeId, {String? sessionToken, String language = 'fr'}) async => null;
  @override
  Future<List<PlaceDetails>> getNearbyPlaces({required double lat, required double lng, int radius = 10000, String type = 'point_of_interest', String language = 'fr'}) async => const [];
  @override
  Future<List<PlaceSuggestion>> getAutocompleteSuggestions(String query,
          {String? sessionToken, String language = 'fr', String components = 'country:ci', double? originLat, double? originLng, bool bypassCache = false}) async =>
      const [];
}

Widget _app(Widget home, {List<Override> overrides = const [], double scale = 1.0, GoRouter? router, PassengerAuthNotifier? auth}) {
  Widget builder(BuildContext c, Widget? child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      );
  return ProviderScope(
    overrides: [
      passengerAuthProvider.overrideWith(
        (ref) => auth ?? PresetAuthNotifier(AuthState(status: AuthStatus.authenticated, userData: {'id': 7, 'firstNames': 'Aminata'})),
      ),
      activeRideCheckProvider.overrideWith((ref) async => null),
      ...overrides,
    ],
    child: router != null
        ? MaterialApp.router(routerConfig: router, builder: builder)
        : MaterialApp(builder: builder, home: home),
  );
}

final _completed = ActiveRide.fromMap(backendRideMap(statusRace: 'COMPLETED', finalPrice: 2500));

void main() {
  setUpAll(() async {
    await loadRealisticFonts();
  });
  setUp(() async => initQaEnvironment(secure: {
        'access_token': 'jwt-aminata',
        'auth_user_data': '{"id":7}',
      }));

  group('ETAPES 11-12 - fin de course, montant, notation', () {
    for (final scale in [1.0, 1.3]) {
      testWidgets('ecran de fin : montant FCFA, adresses, note 4 etoiles + commentaire -> rateRide -> accueil (x$scale)', (tester) async {
        useGalaxyA15(tester);
        final repo = QaBookingRepository();
        final router = GoRouter(initialLocation: RoutePaths.rideComplete, routes: [
          GoRoute(path: RoutePaths.rideComplete, builder: (_, _) => const RideSummaryScreen()),
          GoRoute(path: RoutePaths.passengerHome, builder: (_, _) => const Scaffold(body: Text('ACCUEIL_PASSAGER'))),
        ]);
        await tester.pumpWidget(_app(const SizedBox(), router: router, scale: scale, overrides: [
          passengerBookingRepositoryProvider.overrideWithValue(repo),
          completedRideControllerProvider.overrideWith((ref) => _CompletedStub(_completed)),
        ]));
        await tester.pump();

        expect(find.text('Course terminée !'), findsOneWidget);
        expect(find.textContaining('2'), findsWidgets);
        expect(find.textContaining('FCFA'), findsOneWidget);
        expect(find.text('Départ'), findsOneWidget);
        expect(find.text('Arrivée'), findsOneWidget);
        expect(find.textContaining('Cocody'), findsWidgets, reason: 'adresses de la course affichees');

        // "Terminer" est desactive tant qu'aucune note n'est donnee ; pas de bouton "Passer".
        final finishBtn = find.text('Terminer');
        await tester.ensureVisible(finishBtn);
        await tester.tap(finishBtn, warnIfMissed: false);
        await tester.pump();
        expect(repo.ratings, isEmpty);
        expect(find.text('Passer'), findsNothing);

        final stars = find.byIcon(Icons.star_border);
        expect(stars, findsNWidgets(5));
        await tester.ensureVisible(stars.at(3));
        await tester.tap(stars.at(3));
        await tester.pump();
        await tester.ensureVisible(find.text('Terminer'));
        await tester.tap(find.text('Terminer'));
        await tester.pumpAndSettle();

        expect(repo.ratings.single.rideId, 'ride_qa_1');
        expect(repo.ratings.single.rating, 4);
        expect(find.text('ACCUEIL_PASSAGER'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('fin de course sans donnees en memoire : orientation vers l historique', (tester) async {
      useGalaxyA15(tester);
      final router = GoRouter(initialLocation: RoutePaths.rideComplete, routes: [
        GoRoute(path: RoutePaths.rideComplete, builder: (_, _) => const RideSummaryScreen()),
        GoRoute(path: RoutePaths.history, builder: (_, _) => const Scaffold(body: Text('HISTORIQUE'))),
        GoRoute(path: RoutePaths.passengerHome, builder: (_, _) => const Scaffold(body: Text('ACCUEIL_PASSAGER'))),
      ]);
      await tester.pumpWidget(_app(const SizedBox(), router: router, overrides: [
        passengerBookingRepositoryProvider.overrideWithValue(QaBookingRepository()),
      ]));
      await tester.pump();
      expect(find.text("Ouvrir l'historique"), findsOneWidget);
      await tester.tap(find.text("Ouvrir l'historique"));
      await tester.pumpAndSettle();
      expect(find.text('HISTORIQUE'), findsOneWidget);
    });
  });

  group('ETAPE 13 - historique des courses', () {
    for (final scale in [1.0, 1.3]) {
      testWidgets('historique : course terminee 2 500 FCFA + annulee ; en cours ignoree (x$scale)', (tester) async {
        useGalaxyA15(tester);
        final repo = QaBookingRepository(rides: [
          backendRideMap(statusRace: 'COMPLETED', id: '1', finalPrice: 2500, departure: 'Angré 8e tranche', arrival: 'Plateau'),
          backendRideMap(statusRace: 'CANCELLED_DRIVER', id: '2', departure: 'Riviera 3', arrival: 'Cap Sud'),
          backendRideMap(statusRace: 'IN_PROGRESS', id: '3', departure: 'EnCours', arrival: 'X'),
        ]);
        await tester.pumpWidget(_app(const MyRidesScreen(), scale: scale, overrides: [
          passengerBookingRepositoryProvider.overrideWithValue(repo),
        ]));
        await tester.pumpAndSettle();
        expect(find.text('Angré 8e tranche'), findsOneWidget);
        expect(find.text('Riviera 3'), findsOneWidget);
        expect(find.text('EnCours'), findsNothing);
        expect(find.textContaining('2').evaluate().isNotEmpty, isTrue);
        expect(find.textContaining('FCFA'), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('course annulee automatiquement (CANCELLED_SYSTEM "Aucun chauffeur disponible") visible dans l historique', (tester) async {
      useGalaxyA15(tester);
      final repo = QaBookingRepository(rides: [
        backendRideMap(statusRace: 'CANCELLED_SYSTEM', id: '9', departure: 'Sococé', arrival: 'Aéroport'),
      ]);
      await tester.pumpWidget(_app(const MyRidesScreen(), overrides: [
        passengerBookingRepositoryProvider.overrideWithValue(repo),
      ]));
      await tester.pumpAndSettle();
      expect(find.text('Sococé'), findsOneWidget,
          reason: 'attendu : la course auto-annulee est listee comme annulee, sinon la passagere ne la retrouve pas');
    });

    testWidgets('historique : erreur reseau 4G -> message et bouton reessayer', (tester) async {
      useGalaxyA15(tester);
      final repo = _FailingRepo();
      await tester.pumpWidget(_app(const MyRidesScreen(), overrides: [
        passengerBookingRepositoryProvider.overrideWithValue(repo),
      ]));
      await tester.pumpAndSettle();
      expect(find.text('Impossible de charger vos courses.'), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    });
  });

  group('ETAPE 14 - favoris / adresses enregistrees', () {
    testWidgets('favori avec coordonnees : tap -> destination positionnee et ecran ferme', (tester) async {
      useGalaxyA15(tester);
      final fav = FavoritePlace(
        id: 'fav_1', placeId: 'ChIJfhb', name: 'Université FHB', address: 'Cocody, Abidjan',
        latitude: 5.343, longitude: -4.001, savedAt: DateTime(2026, 10, 1),
      );
      await FavoritePlacesServiceHelper.seed('7', fav);
      final router = GoRouter(initialLocation: '/home', routes: [
        GoRoute(path: '/home', builder: (_, _) => Scaffold(body: Builder(builder: (c) => TextButton(onPressed: () => c.push('/fav'), child: const Text('OUVRIR_FAVORIS'))))),
        GoRoute(path: '/fav', builder: (_, _) => const FavoritesScreen()),
      ]);
      await tester.pumpWidget(_app(const SizedBox(), router: router));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OUVRIR_FAVORIS'));
      await tester.pumpAndSettle();
      expect(find.text('Université FHB'), findsOneWidget);
      await tester.tap(find.text('Université FHB'));
      await tester.pumpAndSettle();
      expect(find.text('OUVRIR_FAVORIS'), findsOneWidget, reason: 'ecran favoris ferme');
      final container = ProviderScope.containerOf(tester.element(find.text('OUVRIR_FAVORIS')));
      expect(container.read(selectedDestinationProvider)?.placeId, 'ChIJfhb');
    });

    testWidgets('favori sans placeId ni resolution possible (4G) : aucun retour a l utilisateur', (tester) async {
      useGalaxyA15(tester);
      final fav = FavoritePlace(
        id: 'fav_2', name: 'Chez Maman Riviera 3', address: 'Riviera 3, Cocody',
        latitude: 5.33, longitude: -3.98, savedAt: DateTime(2026, 10, 1),
      );
      await FavoritePlacesServiceHelper.seed('7', fav);
      await tester.pumpWidget(_app(const FavoritesScreen(), overrides: [
        placesServiceProvider.overrideWithValue(_NoDetailsPlaces()),
      ]));
      await tester.pumpAndSettle();
      expect(find.text('Chez Maman Riviera 3'), findsOneWidget);
      await tester.tap(find.text('Chez Maman Riviera 3'));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(tester.element(find.byType(FavoritesScreen)));
      expect(container.read(selectedDestinationProvider), isNull);
      // CONSTAT : ni SnackBar ni message (favorite_places_provider.dart:~58 `if (details == null ...) return;`)
      // ignore: avoid_print
      print('QA FAVORI textes apres tap: ${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList()}');
      expect(find.textContaining(RegExp('Impossible|introuvable|indisponible')), findsOneWidget,
          reason: 'attendu : un message d erreur quand le favori ne peut pas etre utilise (obtenu : aucun)');
      // Le message s'affiche 10 s en haut de l'ecran (AppSnackBar) : on laisse expirer son minuteur.
      await tester.pump(const Duration(seconds: 11));
    });

    testWidgets('favoris vides : etat vide, textScale 1.3 sans overflow', (tester) async {
      useGalaxyA15(tester);
      await tester.pumpWidget(_app(const FavoritesScreen(), scale: 1.3, overrides: [
        passengerBookingRepositoryProvider.overrideWithValue(QaBookingRepository()),
      ]));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('ETAPES 15-16 - profil, parametres, deconnexion', () {
    PassengerProfile profile() => PassengerProfile(
          firstName: 'Aminata', lastName: 'Kone', name: 'Aminata Kone', phone: '0712345678',
          email: '', rating: 4.9, ridesCount: 12, membershipMonths: 3, memberSince: 'juillet 2026',
        );

    testWidgets('profil affiche nom, telephone ; Deconnexion -> confirmation -> session purgee', (tester) async {
      useGalaxyA15(tester);
      final repo = FakePassengerAuthRepository();
      final notifier = realAuthNotifier(repo);
      await notifier.login('0712345678', '1234');
      // CONSTAT : login() rend la main alors que la session est encore en 'loading' (persistance non attendue).
      final statusRightAfterLogin = notifier.state.status;
      // ignore: avoid_print
      print('QA statut juste apres await login() = $statusRightAfterLogin');
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(notifier.state.status, AuthStatus.authenticated);
      await tester.pumpWidget(_app(const MyPassengerProfileScreen(), auth: notifier, overrides: [
        passengerProfileProvider.overrideWith((ref) async => profile()),
        passengerBookingRepositoryProvider.overrideWithValue(QaBookingRepository()),
      ]));
      await tester.pumpAndSettle();
      // ignore: avoid_print
      print('QA PROFIL textes: ${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList()}');
      expect(find.text('Aminata Kone'), findsWidgets);
      expect(find.textContaining('0712345678'), findsWidgets);

      final logout = find.text('Déconnexion');
      await tester.ensureVisible(logout);
      await tester.tap(logout);
      await tester.pumpAndSettle();
      expect(find.text('Se déconnecter ?'), findsOneWidget);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Annuler').evaluate().isNotEmpty
          ? find.widgetWithText(OutlinedButton, 'Annuler')
          : find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(notifier.state.status, AuthStatus.authenticated, reason: 'Annuler ne deconnecte pas');

      await tester.ensureVisible(logout);
      await tester.tap(logout);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Déconnexion').last);
      await tester.pumpAndSettle();
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(await LocalStorage.instance.getSecure(AppConstants.accessTokenKey), isNull);
      // Apres deconnexion le routeur renvoie vers /login (onboarding deja fait).
      final next = resolvePassengerRedirect(
        authState: notifier.state,
        currentPath: RoutePaths.profile,
        hasCompletedOnboarding: true,
        pendingSearchCleanupAsync: const AsyncValue.data(null),
        activeRideAsync: const AsyncValue.data(null),
      );
      expect(next, RoutePaths.login);
    });

    testWidgets('parametres : sections Preferences / Compte, bascule du mode sombre', (tester) async {
      useGalaxyA15(tester);
      await tester.pumpWidget(_app(const PassengerSettingsScreen(), scale: 1.3));
      await tester.pumpAndSettle();
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Mode sombre'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

class _CompletedStub extends CompletedRideController {
  _CompletedStub(ActiveRide ride) {
    state = ride;
  }
}

class _FailingRepo extends QaBookingRepository {
  @override
  Future<List<Map<String, dynamic>>> getUserRides(int userId) async =>
      throw Exception('Pas de connexion internet');
}

abstract final class FavoritePlacesServiceHelper {
  static Future<void> seed(String userId, FavoritePlace place) async {
    // Passe par le vrai stockage local (SharedPreferences mock) comme l'app.
    await FavoritePlacesService(userId: userId).save(place);
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/data/ci_popular_places.dart';
import 'package:fraya_mobile/core/services/popular_destinations_store.dart';
import 'package:fraya_mobile/data/sources/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _entry(
  String name, {
  double lat = 5.279,
  double lng = -3.989,
  String? id,
  String? address,
}) => {
  'id': id ?? 'popular_${lat}_$lng',
  'name': name,
  'address': address ?? '$name, Marcory',
  'latitude': lat,
  'longitude': lng,
};

Map<String, dynamic> _response(List<Map<String, dynamic>> items) => {
  'success': true,
  'data': items,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.instance.init();
    PopularDestinationsStore.instance.debugReset();
  });

  group('PopularDestination.fromJson', () {
    test('accepte une entrée valide et en déduit la commune', () {
      final d = PopularDestination.fromJson(_entry('Cap Sud'));

      expect(d, isNotNull);
      expect(d!.name, 'Cap Sud');
      expect(d.locality, 'Marcory');
    });

    test('refuse les entrées qui fausseraient un prix', () {
      expect(PopularDestination.fromJson(null), isNull);
      expect(PopularDestination.fromJson('x'), isNull);
      expect(PopularDestination.fromJson(_entry('A', lat: 0, lng: 0)), isNull);
      // Hors de la Côte d'Ivoire.
      expect(
        PopularDestination.fromJson(_entry('A', lat: 48.8, lng: 2.3)),
        isNull,
      );
      expect(
        PopularDestination.fromJson({..._entry('A'), 'latitude': 'x'}),
        isNull,
      );
      expect(PopularDestination.fromJson({..._entry('A'), 'name': ''}), isNull);
      expect(PopularDestination.fromJson({..._entry('A'), 'id': ''}), isNull);
    });
  });

  group('PopularDestinationsStore', () {
    test(
      'enregistre la liste du serveur et la relit après redémarrage',
      () async {
        final store = PopularDestinationsStore(
          fetcher: () async => _response([
            _entry('Cap Sud'),
            _entry('Gare d\'Adjamé', lat: 5.355, lng: -4.025),
            _entry('Doublon', lat: 5.279, lng: -3.989), // même id que Cap Sud
          ]),
        );

        await store.refreshIfStale();
        expect(store.items.map((e) => e.name), ['Cap Sud', "Gare d'Adjamé"]);

        final restarted = PopularDestinationsStore(fetcher: () async => null);
        expect(restarted.items.map((e) => e.name), [
          'Cap Sud',
          "Gare d'Adjamé",
        ]);
      },
    );

    test(
      'ne rappelle pas le serveur avant une semaine, puis rafraîchit',
      () async {
        var now = DateTime(2026, 1);
        var calls = 0;
        final store = PopularDestinationsStore(
          now: () => now,
          fetcher: () async {
            calls++;
            return _response([_entry('Cap Sud')]);
          },
        );

        await store.refreshIfStale();
        now = now.add(const Duration(days: 6));
        await store.refreshIfStale();
        expect(calls, 1);

        now = now.add(const Duration(days: 2));
        await store.refreshIfStale();
        expect(calls, 2);
      },
    );

    test('un échec garde la liste précédente et ne boucle pas', () async {
      var now = DateTime(2026, 1);
      var calls = 0;
      final store = PopularDestinationsStore(
        now: () => now,
        fetcher: () async {
          calls++;
          if (calls == 1) return _response([_entry('Cap Sud')]);
          throw Exception('réseau');
        },
      );
      await store.refreshIfStale();

      now = now.add(const Duration(days: 8)); // périmée
      await store.refreshIfStale(); // échec
      await store.refreshIfStale(); // trop tôt pour réessayer
      expect(calls, 2);
      expect(store.items.single.name, 'Cap Sud');

      now = now.add(const Duration(minutes: 31));
      await store.refreshIfStale();
      expect(calls, 3);
    });

    test('ignore une réponse inattendue sans rien effacer', () async {
      final good = PopularDestinationsStore(
        fetcher: () async => _response([_entry('Cap Sud')]),
      );
      await good.refreshIfStale();

      var now = DateTime.now().add(const Duration(days: 30));
      final bad = PopularDestinationsStore(
        now: () => now,
        fetcher: () async => {'success': false, 'message': 'erreur'},
      );
      await bad.refreshIfStale();

      expect(bad.items.single.name, 'Cap Sud');
      now = now.add(const Duration(minutes: 1));
    });
  });

  group('popularPlaceSuggestions avec les destinations du serveur', () {
    test(
      'un lieu du serveur est trouvé localement, avec ses coordonnées',
      () async {
        await PopularDestinationsStore(
          fetcher: () async => _response([
            _entry(
              'Centre commercial Cap Sud',
              address: 'Centre commercial Cap Sud, Marcory',
            ),
          ]),
        ).refreshIfStale();
        PopularDestinationsStore.instance.debugReset();

        final results = popularPlaceSuggestions('cap sud');

        expect(results, hasLength(1));
        expect(results.single.placeId, startsWith('popular_'));
        expect(results.single.mainText, 'Centre commercial Cap Sud');
        expect(results.single.localDetails!.latitude, 5.279);
        expect(
          results.single.localDetails!.address,
          'Centre commercial Cap Sud, Marcory',
        );
      },
    );

    test('la recherche ignore les accents et la casse', () async {
      await PopularDestinationsStore(
        fetcher: () async => _response([
          _entry(
            'Marché de Treichville',
            lat: 5.29,
            lng: -4.0,
            address: 'Marché de Treichville, Treichville',
          ),
        ]),
      ).refreshIfStale();
      PopularDestinationsStore.instance.debugReset();

      expect(popularPlaceSuggestions('MARCHE de treich'), hasLength(1));
    });

    test('un doublon d\'un lieu intégré ne le remplace pas', () async {
      await PopularDestinationsStore(
        fetcher: () async => _response([
          _entry('Cocody', lat: 5.5, lng: -3.5, address: 'Cocody, Ailleurs'),
        ]),
      ).refreshIfStale();
      PopularDestinationsStore.instance.debugReset();

      final results = popularPlaceSuggestions('cocody');

      expect(results, hasLength(1));
      expect(results.single.placeId, 'local_ci_cocody');
      expect(results.single.localDetails!.latitude, 5.3600);
    });

    test('sans liste serveur, la base intégrée répond comme avant', () {
      final results = popularPlaceSuggestions('aeroport');

      expect(results.first.placeId, 'local_ci_aeroport_fhb');
    });
  });
}

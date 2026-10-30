// PARCOURS PASSAGER - etape 7/8 (robustesse 4G + contrat backend) :
// le backend NestJS met en cache 30 s GET /rides/maps (cle cache:rides:list:<user>:<type>:<query>,
// rides.service.ts:969, TTL redis.queryCacheTtlSeconds=30, aucune invalidation).
// Le mobile suit le statut d'une course en relisant cette liste (booking_repository_impl.dart:75-98).
// Ce test rejoue un Dio factice qui renvoie la liste "perimee" (sans la course qui vient d'etre creee).
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/models/directions_models.dart';
import 'package:fraya_mobile/core/models/places_models.dart';
import 'package:fraya_mobile/core/models/ride_category.dart';
import 'package:fraya_mobile/data/sources/remote/booking_remote_data_source.dart';
import 'package:fraya_mobile/features/passenger/auth/providers/passenger_auth_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/active_ride_check_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/active_ride_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_dependencies.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_flow_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/ride_categories_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/route_directions_provider.dart';
import 'package:fraya_mobile/shared/models/auth_state.dart';
import 'package:fraya_mobile/shared/providers/location_provider.dart';
import 'package:fraya_mobile/shared/providers/places_provider.dart';

import 'qa_support.dart';

class _FakeBackendAdapter implements HttpClientAdapter {
  _FakeBackendAdapter({required this.staleListCalls});

  /// Nombre d'appels GET /rides/maps qui renvoient la liste perimee (cache 30 s du backend).
  int staleListCalls;
  final calls = <String>[];

  ResponseBody _json(Object body, [int status = 200]) => ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    calls.add('${options.method} ${options.path}');
    final path = options.path;
    if (options.method == 'POST' && path == '/rides/maps/request') {
      return _json({'success': true, 'data': {'id': 'ride_new', 'statusRace': 'REQUESTED'}}, 201);
    }
    if (options.method == 'GET' && path == '/rides/maps') {
      final old = backendRideMap(statusRace: 'COMPLETED', id: 'ride_old');
      if (staleListCalls > 0) {
        staleListCalls--;
        return _json({'success': true, 'data': [old]});
      }
      return _json({
        'success': true,
        'data': [backendRideMap(statusRace: 'SEARCHING_DRIVER', id: 'ride_new'), old],
      });
    }
    if (path.contains('/drivers/nearby')) return _json({'success': true, 'data': []});
    return _json({'success': false, 'message': 'introuvable'}, 404);
  }

  @override
  void close({bool force = false}) {}
}

final _directions = DirectionsResult(routes: const [
  DirectionsRoute(
    encodedPolyline: '', distanceText: '6.4 km', distanceValue: 6400, durationText: '18 min',
    durationValue: 1080, arrivalTime: null, durationInTrafficValue: 1260, trafficSegments: [], hasTrafficData: false,
  ),
]);

void main() {
  setUp(() async => initQaEnvironment(secure: {'access_token': 'jwt', 'auth_user_data': '{"id":7}'}));

  Future<(ProviderContainer, _FakeBackendAdapter)> boot(int stale) async {
    final adapter = _FakeBackendAdapter(staleListCalls: stale);
    final dio = Dio(BaseOptions(baseUrl: 'https://qa.invalid'))..httpClientAdapter = adapter;
    final container = ProviderContainer(overrides: [
      passengerAuthProvider.overrideWith((ref) => PresetAuthNotifier(
          AuthState(status: AuthStatus.authenticated, userData: {'id': 7}))),
      activeRideCheckProvider.overrideWith((ref) async => null),
      bookingRemoteDataSourceProvider.overrideWithValue(BookingRemoteDataSource(dio: dio)),
      routeDirectionsProvider.overrideWith((ref) async => _directions),
      currentLocationProvider.overrideWith((ref) => Stream.value(null)),
      formattedAddressProvider.overrideWith((ref) => 'Angré 8e tranche'),
    ]);
    addTearDown(container.dispose);
    container.read(selectedPickupProvider.notifier).setPlace(const PlaceDetails(
        placeId: 'p', name: 'Angré', address: 'Angré 8e tranche, Cocody', latitude: 5.40, longitude: -3.98));
    container.read(selectedDestinationProvider.notifier).setPlace(const PlaceDetails(
        placeId: 'ChIJfhb', name: 'FHB', address: 'Université FHB, Cocody', latitude: 5.34, longitude: -4.00));
    container.read(selectedCategoryProvider.notifier).select(const RideCategory(
        id: 'MAGIC', name: 'Magic', description: 'Eco', price: 2500, seats: 4, iconAsset: 'assets/images/magic.png'));
    await container.read(routeDirectionsProvider.future);
    return (container, adapter);
  }

  test('reference : liste a jour -> la course commandee passe en recherche', () async {
    final (container, adapter) = await boot(0);
    await container.read(bookingFlowProvider.notifier).startSearching();
    expect(adapter.calls, contains('POST /rides/maps/request'));
    expect(container.read(bookingFlowProvider), BookingFlowState.searching);
    container.read(bookingFlowProvider.notifier).stopPolling();
  });

  test('liste en cache perimee (30 s backend) juste apres la commande : la course doit rester en recherche', () async {
    final (container, adapter) = await boot(1);
    await container.read(bookingFlowProvider.notifier).startSearching();
    final state = container.read(bookingFlowProvider);
    // ignore: avoid_print
    print('QA cache perime -> etat apres commande = $state ; appels = ${adapter.calls}');
    expect(state, BookingFlowState.searching,
        reason: 'attendu : la course vient d etre creee cote serveur (id ride_new) ; une liste en cache '
            'ne doit pas la faire considerer comme terminee/annulee');
    container.read(bookingFlowProvider.notifier).stopPolling();
  });
}

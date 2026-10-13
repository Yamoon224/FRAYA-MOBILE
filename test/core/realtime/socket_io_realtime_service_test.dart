import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/config/app_config.dart';
import 'package:fraya_mobile/core/config/app_flavor.dart';
import 'package:fraya_mobile/core/realtime/socket_health_state.dart';
import 'package:fraya_mobile/core/realtime/socket_io_realtime_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Récupère les sockets créés par le service via le cache de managers de
/// socket_io_client (aucune connexion réelle n'aboutit en test).
Map<String, io.Socket> _socketsByNamespace() {
  final manager = io.cache.values.single;
  final nsps = Map<String, io.Socket>.from(manager.nsps as Map);
  return nsps;
}

Map<String, String> _extraHeaders() {
  final manager = io.cache.values.single;
  final options = manager.options as Map;
  return Map<String, String>.from(options['extraHeaders'] as Map);
}

/// Aucune connexion réseau réelle : toute ouverture échoue proprement, comme
/// un serveur injoignable (le socket passe alors en reconnexion).
class _OfflineHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) =>
      Future.error(const SocketException('offline (test)'));

  @override
  void close({bool force = false}) {}
}

class _OfflineHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _OfflineHttpClient();
}

void main() {
  setUpAll(() => HttpOverrides.global = _OfflineHttpOverrides());
  tearDownAll(() => HttpOverrides.global = null);

  late SocketIoRealtimeService service;

  setUp(() {
    AppConfig.instance.init(flavor: AppFlavor.passenger);
    io.cache.clear();
    service = SocketIoRealtimeService();
  });

  tearDown(() {
    service.dispose();
    io.cache.clear();
  });

  group('connection', () {
    test('passenger opens "/" and "/rides" with bearer header and userId', () async {
      await service.connectPassenger(token: 'jwt-passenger', userId: 42);

      final sockets = _socketsByNamespace();
      expect(sockets.keys, containsAll(['/', '/rides']));
      expect(_extraHeaders(), {'Authorization': 'Bearer jwt-passenger'});
      expect(sockets['/']!.query, 'userId=42');
      expect(sockets['/rides']!.query, 'userId=42');

      final manager = io.cache.values.single;
      final options = manager.options as Map;
      expect(options['transports'], ['websocket']);
      expect(options['path'], '/socket.io');
      expect(options['autoConnect'], isFalse);
    });

    test('driver connects with its own token and id', () async {
      AppConfig.instance.init(flavor: AppFlavor.driver);
      await service.connectDriver(token: 'jwt-driver', userId: 7);

      final sockets = _socketsByNamespace();
      expect(_extraHeaders(), {'Authorization': 'Bearer jwt-driver'});
      expect(sockets['/']!.query, 'userId=7');
    });

    test('socket url targets the API host without the /api path', () async {
      await service.connectPassenger(token: 't', userId: 1);

      final apiUri = Uri.parse(AppConfig.instance.baseUrl);
      final managerKey = io.cache.keys.single;
      expect(managerKey, startsWith('${apiUri.scheme}://${apiUri.host}:'));
    });
  });

  group('"/" namespace events delivered to user_<id>', () {
    late io.Socket publicSocket;

    setUp(() async {
      await service.connectPassenger(token: 't', userId: 42);
      publicSocket = _socketsByNamespace()['/']!;
    });

    Future<List<T>> collect<T>(Stream<T> stream, void Function() act) async {
      final events = <T>[];
      final sub = stream.listen(events.add);
      act();
      await pumpEventQueue();
      await sub.cancel();
      return events;
    }

    test('new_ride_available (backend shape with nested ride) -> offers', () async {
      final events = await collect(
        service.newRideOfferStream,
        () => publicSocket.emitEvent([
          'new_ride_available',
          {
            'message': 'Nouvelle course disponible à proximité !',
            'ride': {'id': 123, 'requestedRange': 'MAGIC'},
            'timestamp': '2026-10-13T10:00:00.000Z',
          },
        ]),
      );

      expect(events.map((e) => e.rideId), ['123']);
    });

    for (final entry in {
      'ride_started': 'STARTED',
      'driver_arrived': 'ARRIVED',
      'ride_completed': 'COMPLETED',
    }.entries) {
      test('${entry.key} -> passenger lifecycle stream only', () async {
        final driverEvents = <Object>[];
        final driverSub = service.driverRideStatusStream.listen(
          driverEvents.add,
        );
        final events = await collect(
          service.passengerRideLifecycleStream,
          () => publicSocket.emitEvent([
            entry.key,
            {
              'rideId': 55,
              'status': entry.value,
              'timestamp': '2026-10-13T10:00:00.000Z',
            },
          ]),
        );
        await driverSub.cancel();

        expect(events, hasLength(1));
        expect(events.single.rideId, '55');
        expect(events.single.status, entry.value);
        expect(
          events.single.updatedAt,
          DateTime.parse('2026-10-13T10:00:00.000Z'),
        );
        expect(driverEvents, isEmpty);
      });
    }

    for (final name in ['ride_started_driver', 'ride_completed_driver']) {
      test('$name -> driver status stream only', () async {
        final passengerEvents = <Object>[];
        final passengerSub = service.passengerRideLifecycleStream.listen(
          passengerEvents.add,
        );
        final events = await collect(
          service.driverRideStatusStream,
          () => publicSocket.emitEvent([
            name,
            {'rideId': 8, 'status': 'IN_PROGRESS'},
          ]),
        );
        await passengerSub.cancel();

        expect(events.map((e) => e.rideId), ['8']);
        expect(passengerEvents, isEmpty);
      });
    }

    test('ride_cancelled fans out to both ride streams', () async {
      final driverEvents = <Object>[];
      final driverSub = service.driverRideStatusStream.listen(driverEvents.add);
      final events = await collect(
        service.passengerRideLifecycleStream,
        () => publicSocket.emitEvent([
          'ride_cancelled',
          {'rideId': 9, 'reason': 'Annulée'},
        ]),
      );
      await driverSub.cancel();

      expect(events.single.isCancelled, isTrue);
      expect(events.single.reason, 'Annulée');
      expect(driverEvents, hasLength(1));
    });

    test('positionUpdate and nearbyDriverMoving reach their streams', () async {
      final positions = await collect(
        service.ridePositionUpdateStream,
        () => publicSocket.emitEvent([
          'positionUpdate',
          {'rideId': 3, 'driverLat': 5.35, 'driverLng': -4.01},
        ]),
      );
      final nearby = await collect(
        service.nearbyDriverMovingStream,
        () => publicSocket.emitEvent([
          'nearbyDriverMoving',
          {'driverId': 11, 'latitude': 5.35, 'longitude': -4.01},
        ]),
      );

      expect(positions, hasLength(1));
      expect(nearby, hasLength(1));
    });

    test('malformed payloads are ignored', () async {
      final offers = await collect(
        service.newRideOfferStream,
        () => publicSocket.emitEvent(['new_ride_available', 'not-a-map']),
      );
      final lifecycle = await collect(
        service.passengerRideLifecycleStream,
        () => publicSocket.emitEvent(['ride_started', {'message': 'x'}]),
      );

      expect(offers, isEmpty);
      expect(lifecycle, isEmpty);
    });
  });

  group('"/rides" namespace', () {
    late io.Socket ridesSocket;

    setUp(() async {
      await service.connectDriver(token: 't', userId: 7);
      ridesSocket = _socketsByNamespace()['/rides']!;
    });

    test('ride_accepted, ride_notification and force_logout', () async {
      final accepted = <Object>[];
      final offers = <Object>[];
      var logouts = 0;
      final subs = [
        service.rideAcceptedStream.listen(accepted.add),
        service.newRideOfferStream.listen(offers.add),
        service.forceLogoutStream.listen((_) => logouts++),
      ];

      ridesSocket.emitEvent([
        'ride_accepted',
        {'rideId': 4, 'driverId': 7},
      ]);
      ridesSocket.emitEvent([
        'ride_notification',
        {'type': 'new_ride', 'rideId': 5},
      ]);
      ridesSocket.emitEvent([
        'ride_notification',
        {'type': 'promo', 'rideId': 6},
      ]);
      ridesSocket.emitEvent(['force_logout', {}]);
      await pumpEventQueue();
      for (final s in subs) {
        await s.cancel();
      }

      expect(accepted, hasLength(1));
      expect(offers, hasLength(1), reason: 'type promo ignoré');
      expect(logouts, 1);
    });
  });

  group('health', () {
    test('connect -> connected, disconnect -> reconnecting, failed -> offline', () async {
      final states = <SocketHealthState>[];
      final sub = service.healthStream.listen(states.add);
      await service.connectPassenger(token: 't', userId: 1);
      final socket = _socketsByNamespace()['/']!;

      socket.emitReserved('connect');
      await pumpEventQueue();
      socket.emitReserved('disconnect', 'transport close');
      await pumpEventQueue();
      socket.emitReserved('reconnect_failed');
      await pumpEventQueue();
      await sub.cancel();

      // Un connect_error de la tentative hors-ligne peut s'intercaler.
      expect(
        states,
        containsAllInOrder([
          SocketHealthState.connected,
          SocketHealthState.reconnecting,
          SocketHealthState.offline,
        ]),
      );
      expect(states.last, SocketHealthState.offline);
    });
  });

  test('disconnect drops listeners so late events are not delivered', () async {
    await service.connectPassenger(token: 't', userId: 42);
    final publicSocket = _socketsByNamespace()['/']!;
    final events = <Object>[];
    final sub = service.passengerRideLifecycleStream.listen(events.add);

    await service.disconnect();
    publicSocket.emitEvent([
      'ride_started',
      {'rideId': 1, 'status': 'STARTED'},
    ]);
    await pumpEventQueue();
    await sub.cancel();

    expect(events, isEmpty);
  });
}

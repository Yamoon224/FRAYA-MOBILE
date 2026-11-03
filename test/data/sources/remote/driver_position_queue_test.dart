import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/data/sources/remote/driver_position_queue.dart';
import 'package:fraya_mobile/data/sources/remote/driver_ride_remote_data_source.dart';

double _lat(int i) => 5.0 + i / 1000;

QueuedDriverPosition _position(int i, {DateTime? at}) => QueuedDriverPosition(
  rideId: '34',
  driverId: 18,
  latitude: _lat(i),
  longitude: -4.0,
  timestamp: at ?? DateTime.now(),
);

/// Serveur factice : `mode` pilote la réponse, `received` garde les latitudes reçues dans l'ordre.
class _FakeServer implements HttpClientAdapter {
  String mode = 'ok'; // ok | network | refused | server
  final List<double> received = <double>[];
  final List<String> timestamps = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    switch (mode) {
      case 'network':
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'offline',
          error: const SocketException('offline'),
        );
      case 'refused':
        return ResponseBody.fromString(
          jsonEncode({'message': 'statut non compatible'}),
          400,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      case 'server':
        return ResponseBody.fromString('{}', 502);
    }
    final data = options.data as Map<dynamic, dynamic>;
    received.add((data['latitude'] as num).toDouble());
    timestamps.add(data['timestamp'] as String);
    return ResponseBody.fromString(
      jsonEncode({'success': true}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('DriverPositionQueue', () {
    test('écarte les plus anciennes au-delà de la borne', () {
      final queue = DriverPositionQueue(maxEntries: 3);
      for (var i = 0; i < 5; i++) {
        queue.add(_position(i));
      }

      expect(queue.length, 3);
      expect(queue.peek()!.latitude, _lat(2));
    });

    test('ignore les entrées de plus de 30 minutes', () {
      var now = DateTime(2026, 11, 3, 12);
      final queue = DriverPositionQueue(now: () => now);
      queue.add(_position(1, at: now.subtract(const Duration(minutes: 31))));
      queue.add(_position(2, at: now.subtract(const Duration(minutes: 5))));

      expect(queue.peek()!.latitude, _lat(2));
      expect(queue.length, 1);

      now = now.add(const Duration(minutes: 40));
      expect(queue.peek(), isNull);
      expect(queue.isEmpty, isTrue);
    });
  });

  group('sendDriverLocation avec file hors ligne', () {
    late _FakeServer server;
    late StreamController<List<ConnectivityResult>> connectivity;
    late DriverRideRemoteDataSource dataSource;

    setUp(() {
      server = _FakeServer();
      connectivity = StreamController<List<ConnectivityResult>>.broadcast();
      dataSource = DriverRideRemoteDataSource(
        dio: Dio()..httpClientAdapter = server,
        connectivityChanges: connectivity.stream,
      );
    });

    tearDown(() async {
      dataSource.dispose();
      await connectivity.close();
    });

    // Laisse finir le rejeu lancé en arrière-plan par l'envoi, pour un état stable.
    Future<void> send(int i) async {
      await dataSource.sendDriverLocation(
        rideId: '34',
        driverId: 18,
        lat: _lat(i),
        lng: -4.0,
      );
      await pumpEventQueue();
    }

    test('met en file sur coupure réseau puis rejoue dans l\'ordre', () async {
      server.mode = 'network';
      await send(1);
      await send(2);
      await send(3);
      expect(server.received, isEmpty);

      server.mode = 'ok';
      await dataSource.flushPendingPositions();

      expect(server.received, [_lat(1), _lat(2), _lat(3)]);
      // Le rejeu garde l'heure de la mesure, pas celle de l'envoi.
      expect(server.timestamps, everyElement(endsWith('Z')));
      expect(server.timestamps, [...server.timestamps]..sort());

      // File vide : pas de second rejeu ni de doublon.
      await dataSource.flushPendingPositions();
      expect(server.received.length, 3);
    });

    test('un envoi réussi suivant rejoue la file avant la nouvelle position', () async {
      server.mode = 'network';
      await send(1);
      await send(2);

      server.mode = 'ok';
      await send(3);
      await pumpEventQueue();

      expect(server.received, [_lat(1), _lat(2), _lat(3)]);
    });

    test('un retour de connectivité déclenche le rejeu', () async {
      server.mode = 'network';
      await send(1);

      server.mode = 'ok';
      connectivity.add([ConnectivityResult.wifi]);
      await pumpEventQueue();

      expect(server.received, [_lat(1)]);
    });

    test('ne rejoue pas tant que la connectivité reste absente', () async {
      server.mode = 'network';
      await send(1);

      server.mode = 'ok';
      connectivity.add([ConnectivityResult.none]);
      await pumpEventQueue();

      expect(server.received, isEmpty);
    });

    test('un refus 4xx métier n\'est pas mis en file', () async {
      server.mode = 'refused';
      await send(1);

      server.mode = 'ok';
      await dataSource.flushPendingPositions();

      expect(server.received, isEmpty);
    });

    test('une erreur serveur 5xx est mise en file', () async {
      server.mode = 'server';
      await send(1);

      server.mode = 'ok';
      await dataSource.flushPendingPositions();

      expect(server.received, [_lat(1)]);
    });

    test('un rejeu interrompu par la coupure garde le reste de la file', () async {
      server.mode = 'network';
      await send(1);
      await send(2);

      await dataSource.flushPendingPositions(); // toujours coupé
      expect(server.received, isEmpty);

      server.mode = 'ok';
      await dataSource.flushPendingPositions();
      expect(server.received, [_lat(1), _lat(2)]);
    });

    test('rejoue par lots limités', () async {
      server.mode = 'network';
      final total = DriverRideRemoteDataSource.maxReplayPerRun + 5;
      for (var i = 0; i < total; i++) {
        await send(i);
      }

      server.mode = 'ok';
      await dataSource.flushPendingPositions();
      expect(server.received.length, DriverRideRemoteDataSource.maxReplayPerRun);

      await dataSource.flushPendingPositions();
      expect(server.received.length, total);
      expect(server.received, [...server.received]..sort());
    });
  });
}

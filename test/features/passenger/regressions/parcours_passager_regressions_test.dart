// Non-régression des correctifs du parcours passager (PP-01, PP-02, PP-06, PP-11, PP-12).
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/data/repositories/booking_repository_impl.dart';
import 'package:fraya_mobile/data/sources/remote/booking_remote_data_source.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_polling_mixin.dart';
import 'package:fraya_mobile/shared/widgets/app_snack_bar.dart';
import 'package:fraya_mobile/shared/widgets/auth_login_layout.dart';

class _Poller with BookingPollingMixin {
  _Poller(this.ticks);
  final int ticks;
  @override
  int get pollEveryTicks => ticks;
}

class _Adapter implements HttpClientAdapter {
  final calls = <String>[];

  ResponseBody _json(Object body) => ResponseBody.fromString(
        jsonEncode(body),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    calls.add('${options.method} ${options.path}');
    if (options.path == '/rides/maps') return _json({'success': true, 'data': []});
    if (options.path == '/rides/maps/user/7/active') {
      return _json({'success': true, 'data': {'id': 'ride_new', 'statusRace': 'SEARCHING_DRIVER'}});
    }
    return _json({'success': true, 'data': []});
  }

  @override
  void close({bool force = false}) {}
}

TextEditingValue _format(String text) => const LocalPhoneInputFormatter()
    .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: text));

void main() {
  group('PP-01 numero colle a la connexion', () {
    test('+225 avec espaces -> format local a 10 chiffres', () {
      expect(_format('+225 07 12 34 56 78').text, '0712345678');
      expect(_format('00225 07 12 34 56 78').text, '0712345678');
      expect(_format('2250712345678').text, '0712345678');
    });

    test('numero local saisi normalement inchange', () {
      expect(_format('0712345678').text, '0712345678');
      expect(_format('07 12').text, '0712');
    });
  });

  group('PP-12 sondage espace quand le temps reel est connecte', () {
    test('1 battement : relecture toutes les 4 s', () {
      fakeAsync((async) {
        var n = 0;
        final p = _Poller(1)..startPolling(() async => n++);
        async.elapse(const Duration(seconds: 16));
        expect(n, 4);
        p.stopPolling();
      });
    });

    test('4 battements : relecture toutes les 16 s', () {
      fakeAsync((async) {
        var n = 0;
        final p = _Poller(4)..startPolling(() async => n++);
        async.elapse(const Duration(seconds: 15));
        expect(n, 0);
        async.elapse(const Duration(seconds: 1));
        expect(n, 1);
        p.stopPolling();
      });
    });
  });

  test('PP-02 course absente de la liste en cache : repli sur la course active', () async {
    final adapter = _Adapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://qa.invalid'))..httpClientAdapter = adapter;
    final repo = BookingRepositoryImpl(remoteDataSource: BookingRemoteDataSource(dio: dio));
    final ride = await repo.getActiveRide(7, rideId: 'ride_new');
    expect(ride?.rideId, 'ride_new');
    expect(adapter.calls, contains('GET /rides/maps/user/7/active'));
    // Une autre course active ne doit pas etre prise pour celle qu'on suit.
    expect(await repo.getActiveRide(7, rideId: 'autre'), isNull);
  });

  testWidgets('PP-11 message avec bouton Reglages', (tester) async {
    var opened = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => AppSnackBar.showErrorWithAction(
              context,
              'Activez le GPS',
              actionLabel: 'Réglages',
              onAction: () => opened = true,
            ),
            child: const Text('go'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));
    await tester.tap(find.text('Réglages'));
    await tester.pump();
    expect(opened, isTrue);
  });
}

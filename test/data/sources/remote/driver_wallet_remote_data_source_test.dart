import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/data/sources/remote/driver_wallet_remote_data_source.dart';

class RecordingHttpClientAdapter implements HttpClientAdapter {
  RecordingHttpClientAdapter(this._handler);

  final Future<ResponseBody> Function(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  )
  _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return _handler(options, requestStream, cancelFuture);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('reloadWallet sends expected amount and walletId payload', () async {
    RequestOptions? captured;
    Map<String, dynamic>? capturedBody;
    final dio = Dio()
      ..httpClientAdapter = RecordingHttpClientAdapter((
        options,
        requestStream,
        cancelFuture,
      ) async {
        captured = options;
        capturedBody = await _readJsonBody(requestStream);
        return ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'message': 'Rechargement initié avec succès.',
          }),
          201,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });
    final dataSource = DriverWalletRemoteDataSource(dio: dio);

    final payload = await dataSource.reloadWallet(
      amount: 2500,
      walletId: 'Fra-I4JUY',
    );

    expect(captured?.path, '/subscriptions/reload/drivers/create');
    expect(capturedBody?['amount'], 2500);
    expect(capturedBody?['walletId'], 'Fra-I4JUY');
    expect((payload as Map)['message'], 'Rechargement initié avec succès.');
  });

  test('reloadWallet throws backend message when success is false', () async {
    final dio = Dio()
      ..httpClientAdapter = RecordingHttpClientAdapter((
        options,
        requestStream,
        cancelFuture,
      ) async {
        return ResponseBody.fromString(
          jsonEncode({
            'success': false,
            'message': 'Le rechargement a échoué.',
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });
    final dataSource = DriverWalletRemoteDataSource(dio: dio);

    expect(
      () => dataSource.reloadWallet(amount: 2500, walletId: 'Fra-I4JUY'),
      throwsA(
        isA<ServerException>().having(
          (error) => error.message,
          'message',
          'Le rechargement a échoué.',
        ),
      ),
    );
  });

  test('withdrawWallet omits walletId when empty', () async {
    Map<String, dynamic>? capturedBody;
    final dio = Dio()
      ..httpClientAdapter = RecordingHttpClientAdapter((
        options,
        requestStream,
        cancelFuture,
      ) async {
        capturedBody = await _readJsonBody(requestStream);
        return ResponseBody.fromString(
          jsonEncode({'success': true}),
          201,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });
    final dataSource = DriverWalletRemoteDataSource(dio: dio);

    await dataSource.withdrawWallet(amount: 1200, walletId: ' ');

    expect(capturedBody?['amount'], 1200);
    expect(capturedBody?.containsKey('walletId'), isFalse);
  });

  test('getPackages calls packages endpoint', () async {
    RequestOptions? captured;
    final dio = Dio()
      ..httpClientAdapter = RecordingHttpClientAdapter((
        options,
        requestStream,
        cancelFuture,
      ) async {
        captured = options;
        return ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'data': [
              {'id': 8, 'name': 'Pack Journalier'},
            ],
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });
    final dataSource = DriverWalletRemoteDataSource(dio: dio);

    final payload = await dataSource.getPackages();

    expect(captured?.path, '/packages');
    expect((payload as Map)['success'], isTrue);
  });

  test('subscribeToPackage sends sidUserId and packageId payload', () async {
    RequestOptions? captured;
    Map<String, dynamic>? capturedBody;
    final dio = Dio()
      ..httpClientAdapter = RecordingHttpClientAdapter((
        options,
        requestStream,
        cancelFuture,
      ) async {
        captured = options;
        capturedBody = await _readJsonBody(requestStream);
        return ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'message': 'Souscription effectuee avec succes.',
            'data': {
              'wallet': {
                'previousBalance': 3100,
                'newBalance': 1600,
                'amountDebited': 1500,
                'transactionReference': 'SUB-001',
              },
            },
          }),
          201,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });
    final dataSource = DriverWalletRemoteDataSource(dio: dio);

    await dataSource.subscribeToPackage(sidUserId: 19, packageId: 8);

    expect(captured?.path, '/subscriptions/paiement/reload/create');
    expect(capturedBody, {'sidUserId': 19, 'packageId': 8});
  });

  test(
    'subscribeToPackage throws backend message when success is false',
    () async {
      final dio = Dio()
        ..httpClientAdapter = RecordingHttpClientAdapter((
          options,
          requestStream,
          cancelFuture,
        ) async {
          return ResponseBody.fromString(
            jsonEncode({
              'success': false,
              'statusCode': 400,
              'message': 'Solde insuffisant. Disponible: 3100 FCFA',
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        });
      final dataSource = DriverWalletRemoteDataSource(dio: dio);

      expect(
        () => dataSource.subscribeToPackage(sidUserId: 19, packageId: 9),
        throwsA(
          isA<ServerException>().having(
            (error) => error.message,
            'message',
            contains('Solde insuffisant'),
          ),
        ),
      );
    },
  );
}

Future<Map<String, dynamic>> _readJsonBody(Stream<Uint8List>? stream) async {
  if (stream == null) return <String, dynamic>{};
  final bytesBuilder = BytesBuilder();
  await for (final chunk in stream) {
    bytesBuilder.add(chunk);
  }
  final text = utf8.decode(bytesBuilder.toBytes());
  if (text.trim().isEmpty) return <String, dynamic>{};
  final decoded = jsonDecode(text);
  return Map<String, dynamic>.from(decoded as Map);
}

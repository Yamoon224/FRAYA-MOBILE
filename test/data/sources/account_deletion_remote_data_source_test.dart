import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/data/sources/remote/account_deletion_remote_data_source.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.status, this.body);

  final int status;
  final Object body;
  final List<String> calls = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await requestStream?.drain<void>();
    calls.add('${options.method} ${options.path}');
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

AccountDeletionRemoteDataSource _source(_FakeAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))..httpClientAdapter = adapter;
  return AccountDeletionRemoteDataSource(dio: dio);
}

void main() {
  test('supprime le compte du titulaire via DELETE /sid-users/delete/:id', () async {
    final adapter = _FakeAdapter(200, {'success': true});

    await _source(adapter).deleteAccount(42);

    expect(adapter.calls, ['DELETE /sid-users/delete/42']);
  });

  test("remonte le refus du serveur (200 avec success false), au lieu de croire que c'est supprimé", () async {
    final adapter = _FakeAdapter(200, {
      'success': false,
      'statusCode': 409,
      'message': 'Vous avez une course en cours : terminez-la ou annulez-la avant de supprimer votre compte.',
    });

    await expectLater(
      _source(adapter).deleteAccount(42),
      throwsA(
        isA<ServerException>()
            .having((e) => e.message, 'message', contains('course en cours'))
            .having((e) => e.statusCode, 'statusCode', 409),
      ),
    );
  });

  test('un refus sans message donne un message par défaut', () async {
    final adapter = _FakeAdapter(200, {'success': false});

    await expectLater(
      _source(adapter).deleteAccount(42),
      throwsA(isA<ServerException>().having((e) => e.message, 'message', 'Impossible de supprimer le compte.')),
    );
  });
}

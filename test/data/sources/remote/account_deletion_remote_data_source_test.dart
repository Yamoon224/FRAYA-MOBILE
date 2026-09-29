import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/data/sources/remote/account_deletion_remote_data_source.dart';

class _RecordingHttpClientAdapter implements HttpClientAdapter {
  _RecordingHttpClientAdapter(this._handler);

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
  test('deleteAccount calls sid user delete endpoint', () async {
    late RequestOptions capturedOptions;
    final dio = Dio()
      ..httpClientAdapter = _RecordingHttpClientAdapter((
        options,
        requestStream,
        cancelFuture,
      ) async {
        capturedOptions = options;
        await requestStream?.drain<void>();
        return ResponseBody.fromString('', 200);
      });
    final dataSource = AccountDeletionRemoteDataSource(dio: dio);

    await dataSource.deleteAccount(15);

    expect(capturedOptions.method, 'DELETE');
    expect(capturedOptions.path, '/sid-users/delete/15');
  });
}

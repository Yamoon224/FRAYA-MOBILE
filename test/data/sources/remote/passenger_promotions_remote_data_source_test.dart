import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/data/sources/remote/passenger_promotions_remote_data_source.dart';

class RecordingAdapter implements HttpClientAdapter {
  RecordingAdapter(this._handler);

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
  test(
    'applyPromoCode sends expected payload and returns response map',
    () async {
      RequestOptions? capturedOptions;
      Map<String, dynamic>? capturedBody;
      final dio = Dio()
        ..httpClientAdapter = RecordingAdapter((
          options,
          requestStream,
          _,
        ) async {
          capturedOptions = options;
          capturedBody = await _decodeBody(requestStream);
          return ResponseBody.fromString(
            jsonEncode(<String, dynamic>{
              'originalPrice': 10000,
              'discountAmount': 2500,
              'finalPrice': 7500,
              'promoCode': 'FRAYA25',
              'message': 'Promo code applied successfully',
            }),
            200,
            headers: <String, List<String>>{
              Headers.contentTypeHeader: <String>[Headers.jsonContentType],
            },
          );
        });
      final dataSource = PassengerPromotionsRemoteDataSource(dio: dio);

      final result = await dataSource.applyPromoCode(
        code: 'FRAYA25',
        userId: 9,
        initialPrice: 10000,
        courseId: 88,
      );

      expect(capturedOptions?.path, '/promotions/apply');
      expect(capturedBody?['code'], 'FRAYA25');
      expect(capturedBody?['userId'], 9);
      expect(capturedBody?['initialPrice'], 10000);
      expect(capturedBody?['courseId'], 88);
      expect(result['finalPrice'], 7500);
    },
  );

  test('applyPromoCode throws ServerException on invalid code (400)', () async {
    final dio = Dio()
      ..httpClientAdapter = RecordingAdapter((options, _, _) async {
        return ResponseBody.fromString(
          jsonEncode(<String, dynamic>{'message': 'Invalid promo code'}),
          400,
          headers: <String, List<String>>{
            Headers.contentTypeHeader: <String>[Headers.jsonContentType],
          },
        );
      });
    final dataSource = PassengerPromotionsRemoteDataSource(dio: dio);

    expect(
      () => dataSource.applyPromoCode(
        code: 'BADCODE',
        userId: 1,
        initialPrice: 5000,
      ),
      throwsA(isA<ServerException>()),
    );
  });

  test('applyPromoCode throws AuthException on unauthorized (401)', () async {
    final dio = Dio()
      ..httpClientAdapter = RecordingAdapter((options, _, _) async {
        return ResponseBody.fromString(
          jsonEncode(<String, dynamic>{'message': 'Unauthorized'}),
          401,
          headers: <String, List<String>>{
            Headers.contentTypeHeader: <String>[Headers.jsonContentType],
          },
        );
      });
    final dataSource = PassengerPromotionsRemoteDataSource(dio: dio);

    expect(
      () => dataSource.applyPromoCode(
        code: 'FRAYA20',
        userId: 1,
        initialPrice: 5000,
      ),
      throwsA(isA<AuthException>()),
    );
  });
}

Future<Map<String, dynamic>> _decodeBody(Stream<Uint8List>? stream) async {
  if (stream == null) return <String, dynamic>{};
  final builder = BytesBuilder();
  await for (final chunk in stream) {
    builder.add(chunk);
  }
  final body = utf8.decode(builder.toBytes());
  if (body.trim().isEmpty) return <String, dynamic>{};
  return Map<String, dynamic>.from(jsonDecode(body) as Map);
}

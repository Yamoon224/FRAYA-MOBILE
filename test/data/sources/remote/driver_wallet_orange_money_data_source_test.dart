import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/data/repositories/driver_wallet_repository_impl.dart';
import 'package:fraya_mobile/data/sources/remote/driver_wallet_remote_data_source.dart';
import 'package:fraya_mobile/domain/models/orange_money_payment.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this._respond);

  final ResponseBody Function(RequestOptions options) _respond;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await requestStream?.drain<void>();
    requests.add(options);
    return _respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, [int status = 200]) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

DriverWalletRepositoryImpl _repository(_Adapter adapter) =>
    DriverWalletRepositoryImpl(
      remoteDataSource: DriverWalletRemoteDataSource(
        dio: Dio()..httpClientAdapter = adapter,
      ),
    );

void main() {
  group('initializeOrangeMoneyReload', () {
    test(
      'posts a whole amount to /orange-money/initialize and parses the url',
      () async {
        final adapter = _Adapter(
          (_) => _json({
            'success': true,
            'statusCode': 200,
            'data': {
              'paymentUrl': 'https://webpayment.orange.test/pay/abc',
              'payToken': 'pay',
              'reference': 'FRAYA_OM_1_ABCD',
            },
          }, 201),
        );

        final payment = await _repository(
          adapter,
        ).initializeOrangeMoneyReload(amount: 2500.0);

        final request = adapter.requests.single;
        expect(request.method, 'POST');
        expect(request.path, '/orange-money/initialize');
        expect(request.data, {'amount': 2500});
        expect(payment.paymentUrl, 'https://webpayment.orange.test/pay/abc');
        expect(payment.reference, 'FRAYA_OM_1_ABCD');
      },
    );

    test(
      'never sends a user id: the server uses the logged-in driver',
      () async {
        final adapter = _Adapter(
          (_) => _json({
            'success': true,
            'data': {'paymentUrl': 'https://x', 'reference': 'R'},
          }, 201),
        );

        await _repository(adapter).initializeOrangeMoneyReload(amount: 1000);

        expect(
          (adapter.requests.single.data as Map).keys,
          isNot(contains('sidUserId')),
        );
      },
    );

    test('surfaces a business error returned with HTTP 201', () async {
      final adapter = _Adapter(
        (_) => _json({
          'success': false,
          'statusCode': 400,
          'message': 'Les clés Orange Money ne sont pas configurées',
        }, 201),
      );

      expect(
        () => _repository(adapter).initializeOrangeMoneyReload(amount: 1000),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            'Les clés Orange Money ne sont pas configurées',
          ),
        ),
      );
    });

    test('rejects a response without payment link', () async {
      final adapter = _Adapter(
        (_) => _json({'success': true, 'data': <String, dynamic>{}}, 201),
      );

      expect(
        () => _repository(adapter).initializeOrangeMoneyReload(amount: 1000),
        throwsA(isA<ServerException>()),
      );
    });

    test(
      'never reports success when the server rejects the request (HTTP 400)',
      () async {
        final adapter = _Adapter(
          (_) => _json({'message': 'Validation failed'}, 400),
        );

        await expectLater(
          () => _repository(adapter).initializeOrangeMoneyReload(amount: -5),
          throwsA(isA<Exception>()),
        );
      },
    );
  });

  group('verifyOrangeMoneyReload', () {
    Future<OrangeMoneyPaymentStatus> verify(Map<String, dynamic> body) async {
      final adapter = _Adapter((_) => _json(body));
      final status = await _repository(
        adapter,
      ).verifyOrangeMoneyReload('FRAYA_OM_1_ABCD');
      expect(adapter.requests.single.method, 'GET');
      expect(
        adapter.requests.single.path,
        '/orange-money/verify/FRAYA_OM_1_ABCD',
      );
      return status;
    }

    test('success once the webhook credited the wallet', () async {
      expect(
        await verify({
          'success': true,
          'data': {'success': true, 'paymentStatus': 'SUCCESS'},
        }),
        OrangeMoneyPaymentStatus.success,
      );
    });

    test('failed when the payment was refused or expired', () async {
      expect(
        await verify({
          'success': true,
          'data': {'success': false, 'paymentStatus': 'FAILED'},
        }),
        OrangeMoneyPaymentStatus.failed,
      );
    });

    test('pending while waiting for the notification', () async {
      expect(
        await verify({
          'success': true,
          'data': {'success': false, 'paymentStatus': 'PENDING'},
        }),
        OrangeMoneyPaymentStatus.pending,
      );
    });

    test('encodes the reference in the url', () async {
      final adapter = _Adapter((_) => _json({'success': true, 'data': {}}));
      await _repository(adapter).verifyOrangeMoneyReload('a/b c');
      expect(adapter.requests.single.path, '/orange-money/verify/a%2Fb%20c');
    });
  });
}

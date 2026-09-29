import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/utils/auth_log_redactor.dart';

void main() {
  test('redacts auth secrets recursively while preserving business fields', () {
    final original = {
      'phoneNumber': '0700000000',
      'password': 'secret123',
      'data': {
        'access_token': 'access-secret',
        'refreshToken': 'refresh-secret',
        'user': {'firstNames': 'Awa'},
      },
    };
    final redacted = redactAuthLogData(original) as Map;

    expect(original['password'], 'secret123');
    expect(redacted['phoneNumber'], '0700000000');
    expect(redacted['password'], '[REDACTED]');
    expect(redacted['data']['access_token'], '[REDACTED]');
    expect(redacted['data']['refreshToken'], '[REDACTED]');
    expect(redacted['data']['user']['firstNames'], 'Awa');
  });
}

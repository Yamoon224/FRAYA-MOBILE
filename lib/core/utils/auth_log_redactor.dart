library;

const _redactedValue = '[REDACTED]';
const _sensitiveAuthKeys = {
  'password',
  'confirmpassword',
  'newpassword',
  'token',
  'accesstoken',
  'refreshtoken',
  'verificationcode',
  'otp',
};

dynamic redactAuthLogData(dynamic value) {
  if (value is Map) {
    return {
      for (final entry in value.entries)
        entry.key: _isSensitiveKey(entry.key)
            ? _redactedValue
            : redactAuthLogData(entry.value),
    };
  }
  if (value is List) {
    return value.map(redactAuthLogData).toList(growable: false);
  }
  return value;
}

bool _isSensitiveKey(Object? key) {
  final normalized = key.toString().toLowerCase().replaceAll(
    RegExp(r'[_\-\s]'),
    '',
  );
  return _sensitiveAuthKeys.contains(normalized);
}

library;

import '../../core/utils/map_parsing_utils.dart';

class DriverWalletReloadResult {
  const DriverWalletReloadResult({
    required this.message,
    this.reference,
    this.statusCode,
    this.payload = const <String, dynamic>{},
  });

  final String message;
  final String? reference;
  final int? statusCode;
  final Map<String, dynamic> payload;

  factory DriverWalletReloadResult.fromMap(
    Map<String, dynamic> map, {
    int? statusCode,
  }) {
    final data = nestedMap(map, ['data']) ?? map;
    return DriverWalletReloadResult(
      message: firstString([map['message'], data['message']], fallback: ''),
      reference: firstString([
        data['transactionReference'],
        data['reference'],
        data['transactionId'],
      ], fallback: ''),
      statusCode: statusCode,
      payload: Map<String, dynamic>.from(data),
    );
  }
}

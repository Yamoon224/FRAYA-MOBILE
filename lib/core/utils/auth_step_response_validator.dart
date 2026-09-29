library;

import '../error/exceptions.dart';

void ensureAuthStepSucceeded(dynamic data, {required String fallbackMessage}) {
  if (data == null || (data is String && data.trim().isEmpty)) {
    return;
  }

  if (data is! Map) {
    throw ServerException(message: fallbackMessage);
  }

  final response = Map<String, dynamic>.from(data);
  final success = response['success'];
  final message = _extractMessage(response);
  final error = response['error'];
  final status = response['status']?.toString().trim().toLowerCase();
  final statusCode = _extractStatusCode(response['statusCode']);

  if (success == false) {
    throw ServerException(
      message: message ?? fallbackMessage,
      statusCode: statusCode,
    );
  }

  if (error != null && error.toString().trim().isNotEmpty) {
    throw ServerException(
      message: message ?? error.toString(),
      statusCode: statusCode,
    );
  }

  if (status == 'error' || status == 'failed' || status == 'failure') {
    throw ServerException(
      message: message ?? fallbackMessage,
      statusCode: statusCode,
    );
  }

  if (success != true &&
      message != null &&
      !_containsSuccessMarker(message) &&
      _looksLikeFailureMessage(message)) {
    throw ServerException(message: message, statusCode: statusCode);
  }
}

int? _extractStatusCode(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

String? _extractMessage(Map<String, dynamic> data) {
  final message = data['message'];
  if (message is String && message.trim().isNotEmpty) {
    return message.trim();
  }

  final errors = data['errors'];
  if (errors is List && errors.isNotEmpty) {
    final first = errors.first;
    if (first is Map) {
      final mapped = first['message']?.toString().trim();
      if (mapped != null && mapped.isNotEmpty) {
        return mapped;
      }
    }
    final text = first.toString().trim();
    if (text.isNotEmpty) {
      return text;
    }
  }

  if (errors is Map && errors.isNotEmpty) {
    final firstValue = errors.values.first?.toString().trim();
    if (firstValue != null && firstValue.isNotEmpty) {
      return firstValue;
    }
  }

  final error = data['error']?.toString().trim();
  if (error != null && error.isNotEmpty) {
    return error;
  }

  return null;
}

bool _containsSuccessMarker(String message) {
  final normalized = message.toLowerCase();
  return normalized.contains('succ') ||
      normalized.contains('envoye') ||
      normalized.contains('envoy') ||
      normalized.contains('sent') ||
      normalized.contains('valide') ||
      normalized.contains('valid');
}

bool _looksLikeFailureMessage(String message) {
  final normalized = message.toLowerCase();
  const keywords = [
    'invalide',
    'invalid',
    'incorrect',
    'introuvable',
    'non trouv',
    'not found',
    'erreur',
    'error',
    'echoue',
    'failed',
    'failure',
    'expire',
    'expired',
    'mauvais',
  ];

  return keywords.any(normalized.contains);
}

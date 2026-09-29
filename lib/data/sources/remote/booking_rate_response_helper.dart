import 'package:dio/dio.dart';

import '../../../core/utils/logger.dart';

class BookingRateResponseHelper {
  const BookingRateResponseHelper._();

  static bool isSuccessfulStatus(int? statusCode) {
    return statusCode == 200 ||
        statusCode == 201 ||
        statusCode == 202 ||
        statusCode == 204;
  }

  static String extractDioMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }

      final nested = data['data'];
      if (nested is Map<String, dynamic>) {
        final nestedMessage = nested['message'];
        if (nestedMessage is String && nestedMessage.trim().isNotEmpty) {
          return nestedMessage;
        }
      }

      final errorField = data['error'];
      if (errorField is String && errorField.trim().isNotEmpty) {
        return errorField;
      }
    }
    return error.message ?? '';
  }

  static bool isAlreadySubmittedConflict({
    required int? statusCode,
    required String message,
    Object? responseData,
  }) {
    if (statusCode != 409) return false;

    final normalized = _normalizeForSearch(
      <String>[
        message,
        _stringifyResponseData(responseData),
      ].join(' '),
    );
    if (normalized.isEmpty) return false;

    if (normalized.contains('database error')) {
      return true;
    }

    final hasDuplicateWord = _containsAny(normalized, _duplicateKeywords);
    final hasRatingWord = _containsAny(normalized, _ratingKeywords);
    return hasDuplicateWord && hasRatingWord;
  }

  static void logInfo(String message) {
    try {
      logger.info(message);
    } catch (_) {}
  }

  static void logWarning(String message) {
    try {
      logger.warning(message);
    } catch (_) {}
  }

  static bool _containsAny(String value, List<String> keywords) {
    for (final keyword in keywords) {
      if (value.contains(keyword)) return true;
    }
    return false;
  }

  static String _normalizeForSearch(String input) {
    if (input.isEmpty) return '';
    return input
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ç', 'c');
  }

  static String _stringifyResponseData(Object? responseData) {
    if (responseData == null) return '';
    if (responseData is String) return responseData;
    if (responseData is Map || responseData is List) {
      return responseData.toString();
    }
    return '$responseData';
  }

  static const List<String> _duplicateKeywords = <String>[
    'already',
    'deja',
    'submitted',
    'soumis',
    'duplicate',
    'exists',
    'rated',
    'note',
    'avis',
  ];

  static const List<String> _ratingKeywords = <String>[
    'rate',
    'rating',
    'comment',
    'review',
    'driver',
    'chauffeur',
    'avis',
    'note',
  ];
}

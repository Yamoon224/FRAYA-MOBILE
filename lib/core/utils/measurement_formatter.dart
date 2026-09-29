library;

import 'package:intl/intl.dart';

class MeasurementFormatter {
  static final NumberFormat _currencyFormat = NumberFormat('#,###', 'fr_FR');

  static String formatCurrency(num value) {
    return '${_currencyFormat.format(value)} FCFA';
  }

  static String formatCurrencyPerHour(num value) {
    return '${_currencyFormat.format(value)} FCFA/h';
  }

  static String formatDurationMinutes(num minutes) {
    return '${minutes.round()} min';
  }

  /// Formate une distance en mètres : « 850 m » ou « 2,4 km » (fr_FR).
  static String formatDistanceMeters(int meters) {
    if (meters < 1000) return '$meters m';
    final km = (meters / 1000).toStringAsFixed(1).replaceAll('.', ',');
    return '$km km';
  }

  static String normalizeDuration(String? value, {required String fallback}) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return fallback;
    if (_containsDurationUnit(raw)) return raw;

    final numeric = num.tryParse(raw.replaceAll(',', '.'));
    if (numeric == null) return raw;
    if (numeric <= 0) return '0 min';

    return '${numeric.round()} min';
  }

  static String normalizeDistance(String? value, {required String fallback}) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return fallback;
    if (_containsDistanceUnit(raw)) return raw;

    final numeric = num.tryParse(raw.replaceAll(',', '.'));
    if (numeric == null) return raw;

    return '${numeric.toStringAsFixed(1)} km';
  }

  static bool _containsDurationUnit(String value) {
    final lower = value.toLowerCase();
    return lower.contains('min') ||
        lower.contains('heure') ||
        lower.contains('hour') ||
        lower.contains('hr') ||
        lower.contains(' h');
  }

  static bool _containsDistanceUnit(String value) {
    final lower = value.toLowerCase();
    return lower.contains('km') ||
        lower.contains(' m ') ||
        lower.endsWith(' m') ||
        lower.endsWith('m');
  }
}

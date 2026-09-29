library;

import '../../core/utils/map_parsing_utils.dart';

class DriverWalletPackage {
  const DriverWalletPackage({
    required this.id,
    required this.name,
    required this.description,
    required this.trialDays,
    required this.maxRides,
    required this.maxCancellations,
    required this.status,
    required this.isRecommended,
    required this.isPrivate,
    required this.type,
    required this.isMonthly,
    required this.isAnnual,
    this.dailyPrice,
    this.monthlyPrice,
    this.annualPrice,
  });

  final int id;
  final String name;
  final String description;
  final int trialDays;
  final double? dailyPrice;
  final double? monthlyPrice;
  final double? annualPrice;
  final int maxRides;
  final int maxCancellations;
  final bool status;
  final bool isRecommended;
  final bool isPrivate;
  final String type;
  final bool isMonthly;
  final bool isAnnual;

  double? get price => dailyPrice ?? monthlyPrice ?? annualPrice;

  String get billingCycle {
    if (dailyPrice != null) return 'DAILY';
    if (monthlyPrice != null || isMonthly) return 'MONTHLY';
    if (annualPrice != null || isAnnual) return 'ANNUAL';
    return type.toUpperCase();
  }

  bool get isVisible => status && !isPrivate;

  factory DriverWalletPackage.fromMap(Map<String, dynamic> map) {
    return DriverWalletPackage(
      id: toInt(map['id']) ?? 0,
      name: firstString([map['name']], fallback: 'Package chauffeur'),
      description: firstString([map['description']], fallback: ''),
      trialDays: toInt(map['trialDays']) ?? 0,
      dailyPrice: toDouble(map['dailyPrice']),
      monthlyPrice: toDouble(map['monthlyPrice']),
      annualPrice: toDouble(map['annualPrice']),
      maxRides: toInt(map['maxRides']) ?? 0,
      maxCancellations: toInt(map['maxCancellations']) ?? 0,
      status: _toBool(map['status'], fallback: true),
      isRecommended: _toBool(map['isRecommended']),
      isPrivate: _toBool(map['isPrivate']),
      type: firstString([map['type']], fallback: 'standard'),
      isMonthly: _toBool(map['isMonthly']),
      isAnnual: _toBool(map['isAnnual']),
    );
  }
}

bool _toBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return fallback;
}

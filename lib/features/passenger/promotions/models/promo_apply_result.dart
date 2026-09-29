class PromoApplyResult {
  const PromoApplyResult({
    required this.originalPrice,
    required this.discountAmount,
    required this.finalPrice,
    required this.promoCode,
    required this.message,
  });

  final double originalPrice;
  final double discountAmount;
  final double finalPrice;
  final String promoCode;
  final String message;

  factory PromoApplyResult.fromMap(Map<String, dynamic> map) {
    final original = (map['originalPrice'] as num?)?.toDouble() ?? 0;
    final discount = (map['discountAmount'] as num?)?.toDouble() ?? 0;
    final finalPrice = (map['finalPrice'] as num?)?.toDouble() ?? original;
    return PromoApplyResult(
      originalPrice: original,
      discountAmount: discount,
      finalPrice: finalPrice,
      promoCode: (map['promoCode'] ?? '').toString(),
      message: (map['message'] ?? 'Code promo applique.').toString(),
    );
  }
}

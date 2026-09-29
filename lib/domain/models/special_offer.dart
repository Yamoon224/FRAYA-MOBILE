library;

enum SpecialOfferAudience {
  passenger,
  driver;

  static SpecialOfferAudience? fromValue(String value) {
    switch (value.trim().toLowerCase()) {
      case 'passenger':
        return SpecialOfferAudience.passenger;
      case 'driver':
        return SpecialOfferAudience.driver;
      default:
        return null;
    }
  }
}

class SpecialOffer {
  const SpecialOffer({
    required this.id,
    required this.title,
    required this.description,
    required this.isActive,
    required this.audiences,
    this.shareText,
  });

  factory SpecialOffer.fromMap(Map<String, dynamic> map) {
    return SpecialOffer(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString().trim(),
      description: (map['description'] ?? '').toString().trim(),
      isActive: map['isActive'] == true,
      audiences: _parseAudiences(map['audiences']),
      shareText: _parseOptionalText(map['shareText']),
    );
  }

  final String id;
  final String title;
  final String description;
  final bool isActive;
  final Set<SpecialOfferAudience> audiences;
  final String? shareText;

  bool supportsAudience(SpecialOfferAudience audience) {
    return audiences.contains(audience);
  }

  String? get resolvedShareText {
    final text = shareText?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  static Set<SpecialOfferAudience> _parseAudiences(dynamic raw) {
    if (raw is! List) return const <SpecialOfferAudience>{};
    return raw
        .map((entry) => SpecialOfferAudience.fromValue(entry.toString()))
        .whereType<SpecialOfferAudience>()
        .toSet();
  }

  static String? _parseOptionalText(dynamic raw) {
    final text = raw?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}

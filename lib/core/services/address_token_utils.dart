class AddressTokenUtils {
  const AddressTokenUtils._();

  static const List<String> knownCommunes = <String>[
    'abobo',
    'adjame',
    'attecoube',
    'cocody',
    'koumassi',
    'marcory',
    'plateau',
    'le plateau',
    'port-bouet',
    'port bouet',
    'treichville',
    'yopougon',
    'bingerville',
    'anyama',
    'songon',
    'grand-bassam',
    'grand bassam',
    'bassam',
    'abidjan',
  ];

  static const Map<String, String> communeCanonical = <String, String>{
    'bassam': 'Grand-Bassam',
    'grand bassam': 'Grand-Bassam',
    'grand-bassam': 'Grand-Bassam',
    'le plateau': 'Plateau',
  };

  static const Map<String, String> tokenReplacements = <String, String>{
    '\u00e9': 'e',
    '\u00e8': 'e',
    '\u00ea': 'e',
    '\u00eb': 'e',
    '\u00e0': 'a',
    '\u00e2': 'a',
    '\u00ee': 'i',
    '\u00ef': 'i',
    '\u00f4': 'o',
    '\u00f9': 'u',
    '\u00fb': 'u',
    'ÃƒÂ©': 'e',
    'ÃƒÂ¨': 'e',
    'ÃƒÂª': 'e',
    'ÃƒÂ«': 'e',
    'ÃƒÂ ': 'a',
    'ÃƒÂ¢': 'a',
    'ÃƒÂ®': 'i',
    'ÃƒÂ¯': 'i',
    'ÃƒÂ´': 'o',
    'ÃƒÂ¹': 'u',
    'ÃƒÂ»': 'u',
  };

  static bool isCommuneToken(String token) {
    final normalized = normalizeToken(token);
    return knownCommunes.any((value) => normalized == normalizeToken(value));
  }

  static String canonicalizeCommune(String token) {
    final cleaned = clean(token);
    if (cleaned.isEmpty) return '';
    final normalized = normalizeToken(cleaned);
    return communeCanonical[normalized] ?? cleaned;
  }

  static bool isCountryToken(String token) {
    final normalized = normalizeToken(token);
    return normalized.contains("cote d'ivoire") ||
        normalized.contains('cote divoire') ||
        normalized == 'ci';
  }

  static bool isGenericLocality(String token) =>
      normalizeToken(token) == 'abidjan';

  static bool isAdministrativeToken(String token) {
    final normalized = normalizeToken(token);
    return normalized.contains('district autonome') ||
        normalized.contains('abidjan autonomous district');
  }

  static bool isPlusCode(String token) {
    final normalized = normalizeToken(token).toUpperCase();
    return RegExp(
      r'^[23456789CFGHJMPQRVWX]{4}\+[23456789CFGHJMPQRVWX]{2,}$',
    ).hasMatch(normalized);
  }

  static bool isCoordinate(String token) {
    final cleaned = clean(token);
    if (RegExp(r'^-?\d{1,3}\.\d{4,}$').hasMatch(cleaned)) return true;
    return RegExp(
      r'^(?:lat(?:itude)?\s*[:=]\s*)?-?\d{1,2}(?:\.\d+)?\s*[,;]\s*'
      r'(?:lng|lon(?:gitude)?)?\s*[:=]?\s*-?\d{1,3}(?:\.\d+)?$',
      caseSensitive: false,
    ).hasMatch(cleaned);
  }

  static bool isTechnicalLocationToken(String token) {
    return isPlusCode(token) ||
        isCoordinate(token) ||
        isCountryToken(token) ||
        isAdministrativeToken(token);
  }

  static String cleanHtmlAddress(String value) {
    return clean(
      value
          .replaceAll(RegExp(r'<[^>]*>'), ' ')
          .replaceAll('&#39;', "'")
          .replaceAll('&apos;', "'")
          .replaceAll('&amp;', '&')
          .replaceAll('&nbsp;', ' '),
    );
  }

  static String cleanLocalDetail(
    String value, {
    String commune = '',
    bool stripTowerSuffix = false,
  }) {
    final tokens = value.split(',').map(clean).where((t) => t.isNotEmpty);
    final filtered = tokens.where(
      (token) => isUsefulLocalDetail(token, commune: commune),
    );
    final detail = filtered.isNotEmpty ? filtered.last : clean(value);
    if (!isUsefulLocalDetail(detail, commune: commune)) return '';
    final normalizedDetail = _normalizeOrdinal(detail);
    return stripTowerSuffix
        ? _stripTowerSuffix(normalizedDetail)
        : normalizedDetail;
  }

  static bool isUsefulLocalDetail(String value, {String commune = ''}) {
    final cleaned = clean(value);
    if (cleaned.isEmpty) return false;
    if (isTechnicalLocationToken(cleaned)) return false;
    if (isGenericLocality(cleaned)) return false;
    if (isCommuneToken(cleaned)) return false;
    return normalizeToken(cleaned) != normalizeToken(commune);
  }

  static String normalizeToken(String value) {
    var normalized = value.toLowerCase();
    for (final entry in tokenReplacements.entries) {
      normalized = normalized.replaceAll(entry.key, entry.value);
    }
    return normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String clean(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String _stripTowerSuffix(String value) {
    return clean(
      value.replaceFirst(
        RegExp(r'\s+Tour\s+[A-Z0-9]+$', caseSensitive: false),
        '',
      ),
    );
  }

  static String _normalizeOrdinal(String value) {
    return value.replaceAllMapped(
      RegExp(r'(\d+)\s*ème', caseSensitive: false),
      (match) => '${match.group(1)}eme',
    );
  }
}

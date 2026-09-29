import 'address_token_utils.dart';

class AddressParts {
  const AddressParts({required this.streetOrQuarter, required this.commune});

  final String streetOrQuarter;
  final String commune;
}

class AddressFormatterService {
  const AddressFormatterService();

  AddressParts parse(String raw) {
    final tokens = _splitTokens(raw);
    if (tokens.isEmpty) {
      return const AddressParts(streetOrQuarter: '', commune: '');
    }
    if (tokens.length == 1) {
      final token = tokens.first;
      return _isCommuneToken(token)
          ? AddressParts(streetOrQuarter: '', commune: _canonicalize(token))
          : AddressParts(streetOrQuarter: token, commune: '');
    }

    final communeIndex = _findCommuneIndex(tokens);
    if (communeIndex != null) {
      return _partsFromKnownCommune(tokens, communeIndex);
    }
    if (_isCommuneToken(tokens[0]) && !_isCommuneToken(tokens[1])) {
      return AddressParts(
        streetOrQuarter: tokens[1],
        commune: _canonicalize(tokens[0]),
      );
    }
    return AddressParts(
      streetOrQuarter: tokens[0],
      commune: _canonicalize(_fallbackCommune(tokens)),
    );
  }

  AddressParts fromComponents({
    String? street,
    String? quarter,
    String? commune,
    String? raw,
  }) {
    final parsed = parse(raw ?? '');
    final right = _canonicalize(_firstNonEmpty([commune, parsed.commune]));
    final left = _firstUsefulLabel([
      street,
      quarter,
      parsed.streetOrQuarter,
    ], commune: right);
    return AddressParts(streetOrQuarter: left, commune: right);
  }

  bool isKnownCommune(String value) => _isCommuneToken(value);

  bool isAbidjanToken(String value) => _normalize(value) == 'abidjan';

  String canonicalizeCommune(String value) => _canonicalize(value);

  String format(AddressParts parts) {
    final left = _clean(parts.streetOrQuarter);
    final right = _clean(parts.commune);
    if (left.isEmpty && right.isEmpty) return '';
    if (left.isEmpty) return right;
    if (right.isEmpty) return left;
    if (_normalize(left) == _normalize(right)) return right;
    return '$left, $right';
  }

  String normalize(String raw) => format(parse(raw));

  String normalizeForPlace({
    required String placeName,
    String? rawAddress,
    String? street,
    String? quarter,
    String? commune,
  }) {
    return formatLocalityLabel(
      raw: rawAddress,
      commune: commune,
      detailCandidates: [placeName, quarter, street],
    );
  }

  String formatLocalityLabel({
    String? commune,
    String? raw,
    String? adrAddress,
    List<String?> detailCandidates = const [],
    List<String?> fallbackDetailCandidates = const [],
  }) {
    final parsed = parse(raw ?? '');
    final right = _canonicalize(_firstNonEmpty([commune, parsed.commune]));
    final cleanedAdr = adrAddress == null
        ? ''
        : AddressTokenUtils.cleanHtmlAddress(adrAddress);
    final cleanedDetails = detailCandidates.map(
      (candidate) => candidate == null
          ? ''
          : AddressTokenUtils.cleanLocalDetail(candidate, commune: right),
    );
    final cleanedFallbackDetails = fallbackDetailCandidates.map(
      (candidate) => candidate == null
          ? ''
          : AddressTokenUtils.cleanLocalDetail(candidate, commune: right),
    );
    final left = _firstUsefulLabel([
      ...cleanedDetails,
      parsed.streetOrQuarter,
      parse(cleanedAdr).streetOrQuarter,
      ...cleanedFallbackDetails,
    ], commune: right);
    return format(AddressParts(streetOrQuarter: left, commune: right));
  }

  String primaryLabel(String raw, {String fallback = ''}) {
    final normalized = normalize(raw);
    if (normalized.isEmpty) return fallback;
    final index = normalized.indexOf(',');
    if (index <= 0) return normalized;
    return normalized.substring(0, index).trim();
  }

  String bestDisplayAddress(
    List<String?> candidates, {
    String fallback = 'Position actuelle',
  }) {
    for (final candidate in candidates) {
      if (candidate == null) continue;
      final cleaned = _clean(candidate);
      if (cleaned.isEmpty || isTransientAddress(cleaned)) continue;
      return cleaned;
    }
    return fallback;
  }

  bool isTransientAddress(String value) {
    final normalized = _normalize(value);
    return normalized == 'ma position' ||
        normalized == 'position actuelle' ||
        normalized == 'position inconnue' ||
        normalized == 'recherche...' ||
        normalized == 'erreur adresse' ||
        normalized == 'adresse inconnue' ||
        normalized == 'depart' ||
        normalized == 'destination';
  }

  AddressParts _partsFromKnownCommune(List<String> tokens, int communeIndex) {
    if (communeIndex == 0) {
      if (tokens.length > 1 && _isCommuneToken(tokens[1])) {
        if (isAbidjanToken(tokens[1]) && !isAbidjanToken(tokens[0])) {
          return AddressParts(
            streetOrQuarter: '',
            commune: _canonicalize(tokens[0]),
          );
        }
        return AddressParts(
          streetOrQuarter: tokens[0],
          commune: _canonicalize(tokens[1]),
        );
      }
      return AddressParts(
        streetOrQuarter: tokens.length > 1 ? tokens[1] : '',
        commune: _canonicalize(tokens[0]),
      );
    }
    final commune = tokens[communeIndex];
    return AddressParts(
      streetOrQuarter: _bestLeftToken(tokens, communeIndex),
      commune: _canonicalize(commune),
    );
  }

  int? _findCommuneIndex(List<String> tokens) {
    int? abidjanIndex;
    for (var i = 0; i < tokens.length; i++) {
      if (!_isCommuneToken(tokens[i])) continue;
      if (isAbidjanToken(tokens[i])) {
        abidjanIndex ??= i;
        continue;
      }
      return i;
    }
    return abidjanIndex;
  }

  String _fallbackCommune(List<String> tokens) {
    if (tokens.length < 2) return '';
    final countryIndex = tokens.indexWhere(_isCountryToken);
    return countryIndex > 0 ? tokens[countryIndex - 1] : tokens[1];
  }

  String _bestLeftToken(List<String> tokens, int communeIndex) {
    for (var i = communeIndex - 1; i >= 0; i--) {
      final token = tokens[i];
      if (_isCountryToken(token)) continue;
      if (isAbidjanToken(token) && communeIndex > i) continue;
      return token;
    }
    return communeIndex > 0 ? tokens[communeIndex - 1] : '';
  }

  List<String> _splitTokens(String raw) {
    return raw
        .split(',')
        .map(_clean)
        .where((token) => token.isNotEmpty)
        .where((token) => !AddressTokenUtils.isPlusCode(token))
        .where((token) => !AddressTokenUtils.isCoordinate(token))
        .toList();
  }

  String _firstUsefulLabel(List<String?> values, {String commune = ''}) {
    for (final value in values) {
      if (value == null) continue;
      final cleaned = _clean(value);
      if (_isUsefulPlaceLabel(cleaned, commune: commune)) return cleaned;
    }
    return '';
  }

  bool _isUsefulPlaceLabel(String value, {String commune = ''}) {
    final cleaned = _clean(value);
    if (cleaned.isEmpty || isTransientAddress(cleaned)) return false;
    if (!AddressTokenUtils.isUsefulLocalDetail(cleaned, commune: commune)) {
      return false;
    }
    return _normalize(cleaned) != _normalize(commune);
  }

  String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value == null) continue;
      final cleaned = _clean(value);
      if (cleaned.isNotEmpty) return cleaned;
    }
    return '';
  }

  bool _isCommuneToken(String token) => AddressTokenUtils.isCommuneToken(token);
  bool _isCountryToken(String token) => AddressTokenUtils.isCountryToken(token);
  String _canonicalize(String token) =>
      AddressTokenUtils.canonicalizeCommune(token);
  String _normalize(String value) => AddressTokenUtils.normalizeToken(value);
  String _clean(String value) => AddressTokenUtils.clean(value);
}

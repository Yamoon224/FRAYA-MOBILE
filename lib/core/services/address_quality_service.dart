import 'address_formatter_service.dart';
import 'address_token_utils.dart';

enum AddressQuality { complete, partial, poor }

class AddressQualityService {
  const AddressQualityService({
    this.formatter = const AddressFormatterService(),
  });

  final AddressFormatterService formatter;

  AddressQuality assess(String? value) {
    final sanitized = sanitize(value ?? '');
    if (sanitized.isEmpty) return AddressQuality.poor;

    final parts = formatter.parse(sanitized);
    final hasDetail = AddressTokenUtils.isUsefulLocalDetail(
      parts.streetOrQuarter,
      commune: parts.commune,
    );
    final hasSpecificCommune =
        parts.commune.isNotEmpty &&
        !formatter.isAbidjanToken(parts.commune) &&
        !AddressTokenUtils.isTechnicalLocationToken(parts.commune);

    if (hasDetail && hasSpecificCommune) return AddressQuality.complete;
    if (hasDetail || hasSpecificCommune) return AddressQuality.partial;
    return AddressQuality.poor;
  }

  String sanitize(String value) {
    final tokens = value
        .split(',')
        .map(AddressTokenUtils.clean)
        .where((token) => token.isNotEmpty)
        .where((token) => !AddressTokenUtils.isTechnicalLocationToken(token));
    final normalized = formatter.normalize(tokens.join(', '));
    return _hasUsefulContent(normalized) ? normalized : '';
  }

  String subtitleFor({
    String? localityLabel,
    required String address,
    required String name,
  }) {
    final subtitle = sanitize(localityLabel ?? address);
    if (AddressTokenUtils.normalizeToken(subtitle) ==
        AddressTokenUtils.normalizeToken(name)) {
      return '';
    }
    return subtitle;
  }

  bool _hasUsefulContent(String value) {
    if (value.isEmpty) return false;
    final tokens = value.split(',').map(AddressTokenUtils.clean);
    return tokens.any((token) {
      if (AddressTokenUtils.isTechnicalLocationToken(token)) return false;
      return !AddressTokenUtils.isGenericLocality(token);
    });
  }
}

import 'address_formatter_service.dart';
import 'address_quality_service.dart';
import 'address_token_utils.dart';

class ResolvedPlaceAddress {
  const ResolvedPlaceAddress({
    required this.placeId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.types,
    this.vicinity,
    this.localityLabel,
  });

  final String placeId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? vicinity;
  final List<String> types;
  final String? localityLabel;
}

class PlaceAddressResolver {
  const PlaceAddressResolver({
    this.formatter = const AddressFormatterService(),
    this.qualityService = const AddressQualityService(),
  });

  final AddressFormatterService formatter;
  final AddressQualityService qualityService;

  ResolvedPlaceAddress resolve(Map<String, dynamic> json) {
    final location = json['geometry']?['location'];
    final rawAddress = (json['formatted_address'] ?? json['vicinity'] ?? '')
        .toString();
    final components = (json['address_components'] as List?) ?? const [];
    final values = _readComponents(components);
    final commune = _bestCommune(values);
    final street = [
      values.streetNumber,
      values.route,
    ].where((part) => part.isNotEmpty).join(' ');
    final premise = AddressTokenUtils.cleanLocalDetail(
      values.premise,
      commune: commune,
      stripTowerSuffix: true,
    );
    final label = formatter.formatLocalityLabel(
      raw: rawAddress,
      adrAddress: (json['adr_address'] ?? '').toString(),
      commune: commune,
      detailCandidates: [values.untypedDetail, street, premise],
      fallbackDetailCandidates: [values.fineQuarter],
    );
    final sanitizedLabel = qualityService.sanitize(label);
    final name = (json['name'] ?? '').toString();
    final fallbackAddress = qualityService.sanitize(rawAddress);

    return ResolvedPlaceAddress(
      placeId: (json['place_id'] ?? '').toString(),
      name: name,
      address: sanitizedLabel.isNotEmpty
          ? sanitizedLabel
          : (fallbackAddress.isNotEmpty ? fallbackAddress : name),
      latitude: (location?['lat'] as num?)?.toDouble() ?? 0,
      longitude: (location?['lng'] as num?)?.toDouble() ?? 0,
      vicinity: _normalizedVicinity(json['vicinity']),
      types: (json['types'] as List?)?.cast<String>() ?? const [],
      localityLabel: sanitizedLabel.isEmpty ? null : sanitizedLabel,
    );
  }

  _ComponentValues _readComponents(List components) {
    final values = _ComponentValues();
    for (final component in components) {
      if (component is! Map) continue;
      final types = (component['types'] as List?) ?? const [];
      final name = (component['long_name'] ?? '').toString();
      values.add(name, types);
    }
    return values;
  }

  String _bestCommune(_ComponentValues values) {
    final knownCandidates = [
      values.fineQuarter,
      values.sublocalityLevel1,
      values.adminLevel3,
      values.locality,
      values.adminLevel2,
    ];
    return knownCandidates.firstWhere(
      (candidate) =>
          candidate.isNotEmpty &&
          formatter.isKnownCommune(candidate) &&
          !formatter.isAbidjanToken(candidate),
      orElse: () => [
        values.sublocalityLevel1,
        values.adminLevel3,
        values.locality,
        values.adminLevel2,
      ].firstWhere((candidate) => candidate.isNotEmpty, orElse: () => ''),
    );
  }

  String? _normalizedVicinity(dynamic value) {
    final normalized = qualityService.sanitize((value ?? '').toString());
    return normalized.isEmpty ? null : normalized;
  }
}

class _ComponentValues {
  String adminLevel2 = '';
  String adminLevel3 = '';
  String locality = '';
  String sublocalityLevel1 = '';
  String fineQuarter = '';
  String untypedDetail = '';
  String premise = '';
  String route = '';
  String streetNumber = '';

  void add(String name, List types) {
    if (types.isEmpty) untypedDetail = name;
    if (types.contains('premise')) premise = name;
    if (types.contains('administrative_area_level_2')) adminLevel2 = name;
    if (types.contains('administrative_area_level_3')) adminLevel3 = name;
    if (types.contains('locality')) locality = name;
    if (types.contains('sublocality_level_1')) sublocalityLevel1 = name;
    if (types.contains('neighborhood') ||
        types.contains('sublocality_level_2') ||
        types.contains('sublocality_level_3')) {
      fineQuarter = name;
    }
    if (types.contains('route')) route = name;
    if (types.contains('street_number')) streetNumber = name;
  }
}

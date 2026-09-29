import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'address_formatter_service.dart';
import '../utils/logger.dart';

final _log = AppLogger.instance;

class GeocodingService {
  final Dio _dio;
  final AddressFormatterService _addressFormatter;

  GeocodingService({Dio? dio, AddressFormatterService? addressFormatter})
    : _dio = dio ?? Dio(),
      _addressFormatter = addressFormatter ?? const AddressFormatterService();

  String get _apiKey {
    try {
      return dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Récupère la commune, le quartier et le placeId Google à partir de coordonnées GPS.
  ///
  /// Retourne un objet contenant 'commune', 'quartier', 'formatted' et 'placeId'.
  Future<Map<String, String>> reverseGeocode(double lat, double lng) async {
    final (parts, placeId) = await resolveAddressWithPlaceId(lat, lng);
    return {
      'commune': parts?.commune ?? '',
      'quartier': parts?.streetOrQuarter ?? '',
      'formatted': parts == null ? '' : _addressFormatter.format(parts),
      'placeId': placeId,
    };
  }

  Future<AddressParts?> resolveAddress(double lat, double lng) async {
    return (await resolveAddressWithPlaceId(lat, lng)).$1;
  }

  Future<(AddressParts?, String)> resolveAddressWithPlaceId(
    double lat,
    double lng,
  ) async {
    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {
          'latlng': '$lat,$lng',
          'key': _apiKey,
          'language': 'fr',
          'region': 'ci',
        },
      );
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          if (results.isNotEmpty) {
            final bestResult = _bestResult(results);
            if (bestResult != null) {
              final parts = _partsFromResult(bestResult);
              final placeId = (bestResult['place_id'] as String?) ?? '';
              return (parts, placeId);
            }
          }
        } else {
          _log.error('Google Geocoding error: ${data['status']}');
        }
      }
      return (null, '');
    } catch (e) {
      _log.error('Exception in reverseGeocode: $e');
      return (null, '');
    }
  }

  Map<String, dynamic>? _bestResult(List results) {
    Map<String, dynamic>? best;
    var bestScore = -1000;
    for (final result in results) {
      if (result is! Map) continue;
      final candidate = Map<String, dynamic>.from(result);
      final score = _scoreResult(candidate);
      if (score > bestScore) {
        best = candidate;
        bestScore = score;
      }
    }
    return best;
  }

  AddressParts _partsFromResult(Map<String, dynamic> result) {
    final components = (result['address_components'] as List?) ?? const [];
    final values = _GeocodingComponents();
    for (final component in components) {
      if (component is! Map) continue;
      values.add(
        (component['long_name'] ?? '').toString(),
        (component['types'] as List?) ?? const [],
      );
    }
    final commune = values.knownCommuneCandidates.firstWhere(
      (value) =>
          _addressFormatter.isKnownCommune(value) &&
          !_addressFormatter.isAbidjanToken(value),
      orElse: () => values.communeCandidates.firstWhere(
        (value) => value.isNotEmpty,
        orElse: () => '',
      ),
    );
    return _addressFormatter.fromComponents(
      street: values.street,
      quarter: values.quarter,
      commune: commune,
      raw: (result['formatted_address'] ?? '').toString(),
    );
  }

  int _scoreResult(Map<String, dynamic> result) {
    final components = (result['address_components'] as List?) ?? [];
    var score = 0;
    final resultTypes = (result['types'] as List?) ?? const [];
    if (resultTypes.contains('plus_code')) score -= 20;
    if (resultTypes.contains('street_address')) score += 5;
    if (resultTypes.contains('route')) score += 3;
    for (final component in components) {
      if (component is! Map) continue;
      final types = (component['types'] as List?) ?? [];
      final name = (component['long_name'] ?? '').toString();
      if (types.contains('street_number')) score += 3;
      if (types.contains('route')) score += 5;
      if (types.contains('neighborhood')) score += 4;
      if (types.contains('sublocality_level_2')) score += 3;
      if (types.contains('sublocality_level_3')) score += 3;
      if (_addressFormatter.isKnownCommune(name) &&
          !_addressFormatter.isAbidjanToken(name)) {
        score += 4;
      }
    }
    return score;
  }
}

class _GeocodingComponents {
  String streetNumber = '';
  String route = '';
  String neighborhood = '';
  String sublocalityLevel1 = '';
  String sublocalityLevel2 = '';
  String sublocalityLevel3 = '';
  String adminLevel2 = '';
  String adminLevel3 = '';
  String locality = '';

  String get street =>
      [streetNumber, route].where((part) => part.isNotEmpty).join(' ');

  String get quarter => [
    neighborhood,
    sublocalityLevel3,
    sublocalityLevel2,
  ].firstWhere((value) => value.isNotEmpty, orElse: () => '');

  List<String> get communeCandidates => [
    sublocalityLevel1,
    adminLevel3,
    adminLevel2,
    locality,
  ];

  List<String> get knownCommuneCandidates => [
    neighborhood,
    sublocalityLevel3,
    sublocalityLevel2,
    ...communeCandidates,
  ];

  void add(String name, List types) {
    if (types.contains('street_number')) streetNumber = name;
    if (types.contains('route')) route = name;
    if (types.contains('neighborhood')) neighborhood = name;
    if (types.contains('sublocality_level_1')) sublocalityLevel1 = name;
    if (types.contains('sublocality_level_2')) sublocalityLevel2 = name;
    if (types.contains('sublocality_level_3')) sublocalityLevel3 = name;
    if (types.contains('administrative_area_level_2')) adminLevel2 = name;
    if (types.contains('administrative_area_level_3')) adminLevel3 = name;
    if (types.contains('locality')) locality = name;
  }
}

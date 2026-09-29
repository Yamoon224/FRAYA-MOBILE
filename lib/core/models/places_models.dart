import '../services/address_formatter_service.dart';
import '../services/address_quality_service.dart';
import '../services/place_address_resolver.dart';

part 'saved_address.dart';

class PlaceSuggestion {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;
  final PlaceDetails? localDetails;

  /// Distance à vol d'oiseau (mètres) entre l'utilisateur et cette proposition.
  /// Renseignée uniquement si `origin` a été fourni à l'autocomplete.
  final int? distanceMeters;

  PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
    this.localDetails,
    this.distanceMeters,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    const formatter = AddressFormatterService();
    const qualityService = AddressQualityService();
    final secondary = (json['structured_formatting']?['secondary_text'] ?? '')
        .toString();
    final description = (json['description'] ?? '').toString();
    final normalizedSecondary = formatter.normalize(secondary);
    final normalizedDescription = formatter.normalize(description);

    // Sous-titre = « quartier/rue, commune » dérivé de l'adresse complète
    // (`description`), qui contient le quartier, plutôt que de `secondary_text`.
    final candidateSubtitle = normalizedDescription.isNotEmpty
        ? normalizedDescription
        : (normalizedSecondary.isNotEmpty ? normalizedSecondary : secondary);
    final subtitle = qualityService.sanitize(candidateSubtitle);
    final mainText =
        (json['structured_formatting']?['main_text'] ??
                json['description'] ??
                '')
            .toString();

    return PlaceSuggestion(
      placeId: json['place_id'] ?? '',
      description: subtitle.isNotEmpty ? subtitle : mainText,
      mainText: mainText,
      secondaryText: subtitle,
      distanceMeters: (json['distance_meters'] as num?)?.toInt(),
    );
  }
}

class PlaceDetails {
  final String placeId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? vicinity;
  final List<String> types;

  /// Libellé géographique « quartier, commune » (ex. « Angré, Cocody ») dérivé
  /// des `address_components`. Utilisé comme sous-titre enrichi des suggestions.
  final String? localityLabel;

  const PlaceDetails({
    required this.placeId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.vicinity,
    this.types = const [],
    this.localityLabel,
  });

  PlaceDetails copyWith({
    String? placeId,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? vicinity,
    List<String>? types,
    String? localityLabel,
    bool clearLocalityLabel = false,
  }) {
    return PlaceDetails(
      placeId: placeId ?? this.placeId,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      vicinity: vicinity ?? this.vicinity,
      types: types ?? this.types,
      localityLabel: clearLocalityLabel
          ? null
          : (localityLabel ?? this.localityLabel),
    );
  }

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final resolved = const PlaceAddressResolver().resolve(json);
    return PlaceDetails(
      placeId: resolved.placeId,
      name: resolved.name,
      address: resolved.address,
      latitude: resolved.latitude,
      longitude: resolved.longitude,
      vicinity: resolved.vicinity,
      types: resolved.types,
      localityLabel: resolved.localityLabel,
    );
  }

  /// Sérialisation pour stockage local (SharedPreferences)
  factory PlaceDetails.fromLocalJson(Map<String, dynamic> json) {
    const formatter = AddressFormatterService();
    final rawAddress = (json['address'] ?? '').toString();
    final normalizedAddress = formatter.normalize(rawAddress);
    return PlaceDetails(
      placeId: json['placeId'] ?? '',
      name: json['name'] ?? '',
      address: normalizedAddress.isNotEmpty ? normalizedAddress : rawAddress,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      vicinity: json['vicinity'] as String?,
      types: (json['types'] as List?)?.cast<String>() ?? const [],
      localityLabel: json['localityLabel'] as String?,
    );
  }

  bool get hasValidCoordinates => latitude != 0.0 || longitude != 0.0;

  Map<String, dynamic> toLocalJson() => {
    'placeId': placeId,
    'name': name,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    if (vicinity != null && vicinity!.isNotEmpty) 'vicinity': vicinity,
    if (types.isNotEmpty) 'types': types,
    if (localityLabel != null && localityLabel!.isNotEmpty)
      'localityLabel': localityLabel,
  };
}

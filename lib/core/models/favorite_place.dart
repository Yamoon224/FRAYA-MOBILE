import 'places_models.dart';
import 'ride_model.dart';
import '../services/address_formatter_service.dart';

class FavoritePlace {
  final String id;
  final String? placeId;
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;
  final DateTime savedAt;

  const FavoritePlace({
    required this.id,
    this.placeId,
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
    required this.savedAt,
  });

  static const _addressFormatter = AddressFormatterService();

  factory FavoritePlace.fromSuggestion(PlaceSuggestion s) => FavoritePlace(
    id: 'fav_${s.placeId}',
    placeId: s.placeId,
    name: s.mainText,
    address: _addressFormatter.normalize(
      s.secondaryText.isNotEmpty ? s.secondaryText : s.description,
    ),
    savedAt: DateTime.now(),
  );

  factory FavoritePlace.fromPlaceDetails(PlaceDetails p) => FavoritePlace(
    id: 'fav_${p.placeId.isNotEmpty ? p.placeId : p.address.hashCode}',
    placeId: p.placeId.isNotEmpty ? p.placeId : null,
    name: p.name,
    address: _addressFormatter.normalize(p.address),
    latitude: p.latitude,
    longitude: p.longitude,
    savedAt: DateTime.now(),
  );

  factory FavoritePlace.fromRide(Ride ride) => FavoritePlace(
    id: 'fav_ride_${ride.id}',
    placeId: null,
    name: _addressFormatter.primaryLabel(
      ride.arrivalAddress,
      fallback: 'Destination',
    ),
    address: _addressFormatter.normalize(ride.arrivalAddress),
    latitude: ride.arrivalLat,
    longitude: ride.arrivalLng,
    savedAt: DateTime.now(),
  );

  factory FavoritePlace.fromJson(Map<String, dynamic> json) => FavoritePlace(
    id: json['id']?.toString() ?? '',
    placeId: json['placeId'] as String?,
    name: (json['name'] ?? json['label'] ?? '').toString(),
    address: _addressFormatter.normalize((json['address'] ?? '').toString()),
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    savedAt:
        DateTime.tryParse((json['savedAt'] ?? '').toString()) ?? DateTime.now(),
  );

  factory FavoritePlace.fromBackendMap(Map<String, dynamic> json) {
    final idValue =
        json['id']?.toString() ??
        'fav_${DateTime.now().millisecondsSinceEpoch}';
    final label = (json['label'] ?? json['name'] ?? '').toString();
    final address = _addressFormatter.normalize(
      (json['address'] ?? '').toString(),
    );
    return FavoritePlace(
      id: idValue,
      placeId: (json['placeId'] as String?)?.trim().isEmpty == true
          ? null
          : json['placeId'] as String?,
      name: label.isNotEmpty
          ? label
          : _addressFormatter.primaryLabel(address, fallback: 'Destination'),
      address: address,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      savedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'placeId': placeId,
    'name': name,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'savedAt': savedAt.toIso8601String(),
  };

  bool get hasCoordinates => latitude != null && longitude != null;
}

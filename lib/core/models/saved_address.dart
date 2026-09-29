part of 'places_models.dart';

enum SavedAddressType { home, work, custom }

class SavedAddress {
  final String id;
  final String label;
  final SavedAddressType type;
  final PlaceDetails place;
  final String? iconKey;

  const SavedAddress({
    required this.id,
    required this.label,
    required this.type,
    required this.place,
    this.iconKey,
  });

  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    return SavedAddress(
      id: json['id'] as String,
      label: json['label'] as String,
      type: SavedAddressType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SavedAddressType.custom,
      ),
      place: PlaceDetails.fromLocalJson(json['place'] as Map<String, dynamic>),
      iconKey: json['iconKey'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'type': type.name,
    'place': place.toLocalJson(),
    if (iconKey != null && iconKey!.isNotEmpty) 'iconKey': iconKey,
  };
}

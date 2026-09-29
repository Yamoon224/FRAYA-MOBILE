import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/models/places_models.dart';

void main() {
  test('SavedAddress serializes and deserializes custom iconKey', () {
    const address = SavedAddress(
      id: '1',
      label: 'Salle de sport',
      type: SavedAddressType.custom,
      iconKey: 'gym',
      place: PlaceDetails(
        placeId: 'pid_1',
        name: 'Gym',
        address: 'Cocody, Abidjan',
        latitude: 5.35,
        longitude: -3.99,
      ),
    );

    final json = address.toJson();
    final restored = SavedAddress.fromJson(json);

    expect(restored.label, 'Salle de sport');
    expect(restored.type, SavedAddressType.custom);
    expect(restored.iconKey, 'gym');
    expect(restored.place.address, 'Cocody, Abidjan');
  });

  test('SavedAddress keeps backward compatibility when iconKey is absent', () {
    final restored = SavedAddress.fromJson({
      'id': '2',
      'label': 'Autre',
      'type': 'custom',
      'place': {
        'placeId': 'pid_2',
        'name': 'Lieu',
        'address': 'Plateau, Abidjan',
        'latitude': 5.32,
        'longitude': -4.01,
      },
    });

    expect(restored.iconKey, isNull);
    expect(restored.type, SavedAddressType.custom);
  });
}

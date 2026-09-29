import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/models/places_models.dart';
import 'package:fraya_mobile/core/services/places_cache_service.dart';
import 'package:fraya_mobile/data/sources/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.instance.init();
  });

  test('complete address remains cached for thirty days', () async {
    var now = DateTime(2026, 1);
    final cache = PlacesCacheService(now: () => now);
    await cache.saveDetails(_details('Avenue Aka, Cocody'));

    now = now.add(const Duration(days: 29));

    expect(cache.readDetails('place_1'), isNotNull);
  });

  test('partial address expires after twenty four hours', () async {
    var now = DateTime(2026, 1);
    final cache = PlacesCacheService(now: () => now);
    await cache.saveDetails(_details('Cocody'));

    now = now.add(const Duration(hours: 23));
    expect(cache.readDetails('place_1'), isNotNull);

    now = now.add(const Duration(hours: 2));
    expect(cache.readDetails('place_1'), isNull);
  });

  test('legacy incomplete address is invalidated immediately', () async {
    final now = DateTime(2026, 1);
    await LocalStorage.instance.setString(
      'places_cache_details_legacy',
      jsonEncode({
        'cachedAt': now.millisecondsSinceEpoch,
        'details': _details('Abidjan', placeId: 'legacy').toLocalJson(),
      }),
    );
    final cache = PlacesCacheService(now: () => now);

    expect(cache.readDetails('legacy'), isNull);
  });
}

PlaceDetails _details(String address, {String placeId = 'place_1'}) {
  return PlaceDetails(
    placeId: placeId,
    name: 'Lieu',
    address: address,
    latitude: 5.35,
    longitude: -4.01,
    localityLabel: address,
  );
}

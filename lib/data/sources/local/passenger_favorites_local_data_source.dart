library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/favorite_place.dart';

class PassengerFavoritesLocalDataSource {
  PassengerFavoritesLocalDataSource(this._userId);

  final String _userId;
  String get storageKey => 'fraya_favorite_places_$_userId';

  Future<List<FavoritePlace>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(storageKey) ?? <String>[];
    return raw
        .map(
          (entry) =>
              FavoritePlace.fromJson(jsonDecode(entry) as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> save(FavoritePlace place) async {
    final prefs = await SharedPreferences.getInstance();
    final places = await getAll();
    places.removeWhere(
      (existing) =>
          existing.id == place.id ||
          (place.placeId != null &&
              place.placeId!.isNotEmpty &&
              existing.placeId == place.placeId),
    );
    places.add(place);
    await prefs.setStringList(
      storageKey,
      places.map((entry) => jsonEncode(entry.toJson())).toList(),
    );
  }

  Future<void> replaceAll(List<FavoritePlace> places) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      storageKey,
      places.map((entry) => jsonEncode(entry.toJson())).toList(),
    );
  }

  Future<void> remove(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final updated = (await getAll()).where((entry) => entry.id != id).toList();
    await prefs.setStringList(
      storageKey,
      updated.map((entry) => jsonEncode(entry.toJson())).toList(),
    );
  }
}

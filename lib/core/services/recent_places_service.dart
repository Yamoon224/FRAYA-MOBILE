import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/places_models.dart';
import 'address_formatter_service.dart';

/// Service de gestion des adresses récentes via SharedPreferences.
///
/// Stocke jusqu'à [maxItems] lieux, dédupliqués par placeId.
/// Le lieu le plus récent est toujours en tête de liste.
class RecentPlacesService {
  RecentPlacesService(this._userId);

  final String _userId;
  String get _key => 'fraya_recent_places_$_userId';
  static const int maxItems = 10;
  static const _addressFormatter = AddressFormatterService();

  /// Récupère la liste des lieux récents (du plus récent au plus ancien).
  Future<List<PlaceDetails>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map(
          (e) =>
              PlaceDetails.fromLocalJson(jsonDecode(e) as Map<String, dynamic>),
        )
        .where((p) => p.hasValidCoordinates)
        .toList();
  }

  /// Ajoute un lieu en tête de liste.
  /// - Supprime les doublons existants (même placeId).
  /// - Limite la liste à [maxItems].
  Future<void> add(PlaceDetails place) async {
    // On ignore les lieux "manuels" sans vrai placeId Google
    if (place.placeId.startsWith('manual_')) return;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];

    // Convertir en liste de maps
    final existing = raw
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();

    // Supprimer le doublon éventuel
    existing.removeWhere((e) => e['placeId'] == place.placeId);

    // Insérer en tête
    existing.insert(
      0,
      place
          .copyWith(address: _addressFormatter.normalize(place.address))
          .toLocalJson(),
    );

    // Limiter à maxItems
    final trimmed = existing.take(maxItems).toList();

    await prefs.setStringList(_key, trimmed.map(jsonEncode).toList());
  }

  /// Supprime un lieu spécifique de l'historique.
  Future<void> remove(String placeId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final updated = raw
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .where((e) => e['placeId'] != placeId)
        .map(jsonEncode)
        .toList();
    await prefs.setStringList(_key, updated);
  }

  /// Efface tout l'historique.
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

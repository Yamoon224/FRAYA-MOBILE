import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/places_models.dart';
import 'address_formatter_service.dart';
import '../../data/sources/remote/saved_addresses_remote_data_source.dart';

/// Service CRUD pour les adresses enregistrées (Maison, Travail, Personnalisées).
/// Remote-first (backend /favorites) avec fallback cache local.
/// L'iconKey (custom uniquement) est stocké localement car non supporté par l'API.
class SavedPlacesService {
  SavedPlacesService(this._userId);

  final String _userId;
  late final SavedAddressesRemoteDataSource _remote =
      SavedAddressesRemoteDataSource();

  static const _addressFormatter = AddressFormatterService();

  String get _cacheKey => 'fraya_saved_addresses_$_userId';
  String get _iconsKey => 'fraya_saved_places_icons_$_userId';

  Future<List<SavedAddress>> getAll() async {
    try {
      final remote = await _remote.getAll();
      final icons = await _loadIconsMap();
      final merged = remote.map((a) {
        final iconKey = icons[a.id];
        return iconKey != null ? _withIconKey(a, iconKey) : a;
      }).toList();
      // Preserve items saved locally during a failed backend sync (non-integer ids)
      final cached = await _readCache();
      final remoteIds = remote.map((a) => a.id).toSet();
      final unsynced = cached
          .where((a) => int.tryParse(a.id) == null && !remoteIds.contains(a.id))
          .toList();
      final finalList = [...merged, ...unsynced];
      await _replaceCache(finalList);
      return finalList;
    } catch (_) {
      return _readCache();
    }
  }

  Future<List<SavedAddress>> getCachedAddresses() => _readCache();

  Future<void> save(SavedAddress address) async {
    try {
      final normalizedPlace = address.place.copyWith(
        address: _addressFormatter.normalize(address.place.address),
      );
      final toSave = SavedAddress(
        id: address.id,
        label: address.label,
        type: address.type,
        iconKey: address.iconKey,
        place: normalizedPlace,
      );
      final backendId = await _remote.save(toSave);
      final finalId = backendId?.toString() ?? address.id;
      final persisted = SavedAddress(
        id: finalId,
        label: toSave.label,
        type: toSave.type,
        iconKey: toSave.iconKey,
        place: toSave.place,
      );
      if (toSave.iconKey != null && toSave.iconKey!.isNotEmpty) {
        await _saveIconKey(finalId, toSave.iconKey!);
      }
      await _upsertCache(persisted);
    } catch (_) {
      // Fallback: sauvegarde locale uniquement
      await _upsertCache(
        SavedAddress(
          id: address.id,
          label: address.label,
          type: address.type,
          iconKey: address.iconKey,
          place: address.place.copyWith(
            address: _addressFormatter.normalize(address.place.address),
          ),
        ),
      );
    }
  }

  Future<void> remove(String id) async {
    final remoteId = int.tryParse(id);
    if (remoteId != null) {
      try {
        await _remote.remove(remoteId);
      } catch (_) {}
    }
    await _removeIconKey(id);
    await _removeFromCache(id);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_iconsKey);
  }

  // ── Cache local ──────────────────────────────────────────────────────────

  Future<List<SavedAddress>> _readCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_cacheKey) ?? [];
    return raw
        .map(
          (e) => SavedAddress.fromJson(jsonDecode(e) as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> _replaceCache(List<SavedAddress> addresses) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _cacheKey,
      addresses.map((a) => jsonEncode(a.toJson())).toList(),
    );
  }

  Future<void> _upsertCache(SavedAddress address) async {
    final existing = await _readCache();
    if (address.type == SavedAddressType.home ||
        address.type == SavedAddressType.work) {
      existing.removeWhere((e) => e.type == address.type);
    } else {
      existing.removeWhere((e) => e.id == address.id);
    }
    existing.add(address);
    await _replaceCache(existing);
  }

  Future<void> _removeFromCache(String id) async {
    final existing = await _readCache();
    await _replaceCache(existing.where((e) => e.id != id).toList());
  }

  // ── Map iconKey local ────────────────────────────────────────────────────

  Future<Map<String, String>> _loadIconsMap() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_iconsKey);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v.toString()));
  }

  Future<void> _saveIconKey(String id, String iconKey) async {
    final prefs = await SharedPreferences.getInstance();
    final map = await _loadIconsMap();
    map[id] = iconKey;
    await prefs.setString(_iconsKey, jsonEncode(map));
  }

  Future<void> _removeIconKey(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final map = await _loadIconsMap();
    if (map.remove(id) != null) {
      await prefs.setString(_iconsKey, jsonEncode(map));
    }
  }

  static SavedAddress _withIconKey(SavedAddress address, String iconKey) {
    return SavedAddress(
      id: address.id,
      label: address.label,
      type: address.type,
      iconKey: iconKey,
      place: address.place,
    );
  }
}

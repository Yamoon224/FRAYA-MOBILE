library;

import 'package:dio/dio.dart';

import '../../../core/error/exceptions.dart';
import '../../../core/models/places_models.dart';
import '../../../core/services/address_formatter_service.dart';
import '../../sources/api_client.dart';

class SavedAddressesRemoteDataSource {
  SavedAddressesRemoteDataSource({Dio? dio})
    : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;
  static const _addressFormatter = AddressFormatterService();

  Future<List<SavedAddress>> getAll() async {
    try {
      final response = await _dio.get('/favorites');
      final list = _extractList(response.data);
      return list.map(_fromBackendMap).toList();
    } on DioException catch (error) {
      ApiClient.handleDioError(error);
    } catch (error) {
      throw ServerException(
        message: 'Impossible de récupérer les adresses enregistrées: $error',
      );
    }
  }

  /// Envoie l'adresse au backend et retourne l'id entier attribué.
  Future<int?> save(SavedAddress address) async {
    try {
      final payload = {
        'label': address.label,
        'address': _addressFormatter.normalize(address.place.address),
        'placeId': address.place.placeId,
        'latitude': address.place.latitude,
        'longitude': address.place.longitude,
      };
      final response = await _dio.post('/favorites/create', data: payload);
      return _extractId(response.data);
    } on DioException catch (error) {
      ApiClient.handleDioError(error);
    } catch (error) {
      throw ServerException(
        message: 'Impossible d\'enregistrer l\'adresse: $error',
      );
    }
  }

  Future<void> remove(int id) async {
    try {
      await _dio.delete('/favorites/$id');
    } on DioException catch (error) {
      ApiClient.handleDioError(error);
    } catch (error) {
      throw ServerException(
        message: 'Impossible de supprimer l\'adresse: $error',
      );
    }
  }

  static SavedAddress _fromBackendMap(Map<String, dynamic> map) {
    final label = (map['label'] ?? '').toString();
    return SavedAddress(
      id: map['id']?.toString() ?? '',
      label: label,
      type: _typeFromLabel(label),
      place: PlaceDetails(
        placeId: (map['placeId'] as String?) ?? '',
        name: label,
        address: _addressFormatter.normalize((map['address'] ?? '').toString()),
        latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      ),
    );
  }

  static SavedAddressType _typeFromLabel(String label) {
    switch (label.trim().toLowerCase()) {
      case 'maison':
        return SavedAddressType.home;
      case 'travail':
        return SavedAddressType.work;
      default:
        return SavedAddressType.custom;
    }
  }

  List<Map<String, dynamic>> _extractList(dynamic data) {
    final root = _unwrap(data);
    if (root is List) {
      return root
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (root is Map && root['data'] is List) {
      return (root['data'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  int? _extractId(dynamic data) {
    var current = data;
    while (current is Map) {
      final id = current['id'];
      if (id is int) return id;
      if (id is String) return int.tryParse(id);
      final next = current['data'] ?? current['result'] ?? current['favorite'];
      if (next == null || identical(current, next)) break;
      current = next;
    }
    return null;
  }

  dynamic _unwrap(dynamic data) {
    var current = data;
    while (current is Map) {
      final next = current['data'] ?? current['result'] ?? current['favorite'];
      if (next == null || identical(current, next)) break;
      current = next;
    }
    return current;
  }
}

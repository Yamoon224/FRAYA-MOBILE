import 'package:google_maps_flutter/google_maps_flutter.dart';

Map<String, dynamic>? nestedMap(
  Map<String, dynamic> source,
  List<String> keys,
) {
  for (final key in keys) {
    final value = source[key];
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
  }
  return null;
}

String firstString(List<dynamic> values, {required String fallback}) {
  for (final value in values) {
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty && text != 'null') return text;
  }
  return fallback;
}

double? toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

LatLng parseLatLng(Map<String, dynamic> map, List<String> latKeys, List<String> lngKeys, {LatLng? fallback}) {
  double? lat;
  for (final key in latKeys) {
    lat = toDouble(map[key]);
    if (lat != null) break;
  }
  
  double? lng;
  for (final key in lngKeys) {
    lng = toDouble(map[key]);
    if (lng != null) break;
  }
  
  if (lat != null && lng != null) return LatLng(lat, lng);
  return fallback ?? const LatLng(5.3484, -3.9554);
}

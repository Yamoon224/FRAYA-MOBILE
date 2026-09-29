library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/models/directions_models.dart';
import '../../../../core/services/directions_service.dart';

class DriverHomeMapRouteQuery {
  const DriverHomeMapRouteQuery({
    required this.origin,
    required this.destination,
  });

  final LatLng origin;
  final LatLng destination;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DriverHomeMapRouteQuery &&
        _rounded(origin.latitude) == _rounded(other.origin.latitude) &&
        _rounded(origin.longitude) == _rounded(other.origin.longitude) &&
        _rounded(destination.latitude) ==
            _rounded(other.destination.latitude) &&
        _rounded(destination.longitude) ==
            _rounded(other.destination.longitude);
  }

  @override
  int get hashCode => Object.hash(
    _rounded(origin.latitude),
    _rounded(origin.longitude),
    _rounded(destination.latitude),
    _rounded(destination.longitude),
  );

  static double _rounded(double value) => (value * 10000).round() / 10000;
}

final driverHomeMapRouteProvider = FutureProvider.autoDispose
    .family<DirectionsResult?, DriverHomeMapRouteQuery>((ref, query) async {
      final service = ref.watch(driverHomeDirectionsServiceProvider);
      return service.getDirections(
        origin: query.origin,
        destination: query.destination,
      );
    });

final driverHomeDirectionsServiceProvider = Provider<DirectionsService>((ref) {
  return DirectionsService();
});

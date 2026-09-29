import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/models/directions_models.dart';

class GetRouteDirectionsParams {
  const GetRouteDirectionsParams({
    required this.origin,
    required this.destination,
    this.language = 'fr',
    this.includeAlternativeRoutes = false,
  });

  final LatLng origin;
  final LatLng destination;
  final String language;
  final bool includeAlternativeRoutes;
}

abstract class DirectionsRepository {
  Future<DirectionsResult?> getRouteDirections(GetRouteDirectionsParams params);
}

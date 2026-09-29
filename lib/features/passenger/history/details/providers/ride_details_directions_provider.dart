import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fraya_mobile/core/models/directions_models.dart';
import 'package:fraya_mobile/core/models/ride_model.dart';
import 'package:fraya_mobile/domain/repositories/directions_repository.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/directions_dependencies.dart';

final rideDetailsDirectionsProvider = FutureProvider.autoDispose
    .family<DirectionsResult?, Ride>((ref, ride) async {
      final useCase = ref.read(getRouteDirectionsUseCaseProvider);
      final origin = LatLng(ride.departureLat, ride.departureLng);
      final destination = LatLng(ride.arrivalLat, ride.arrivalLng);
      final result = await useCase(
        GetRouteDirectionsParams(
          origin: origin,
          destination: destination,
          includeAlternativeRoutes: false,
        ),
      );
      return result.fold(
        (failure) => throw StateError(failure.message),
        (value) => value,
      );
    });

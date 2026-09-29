import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/models/directions_models.dart';
import '../../../../domain/repositories/directions_repository.dart';
import '../../../../shared/providers/location_provider.dart';
import '../../../../shared/providers/places_provider.dart';
import 'booking_route_refresh_provider.dart';
import 'directions_dependencies.dart';

part 'route_directions_provider.g.dart';

@riverpod
Future<DirectionsResult?> routeDirections(Ref ref) async {
  final destination = ref.watch(selectedDestinationProvider);
  final manualPickup = ref.watch(selectedPickupProvider);
  ref.watch(bookingManualRefreshTriggerProvider);

  if (destination == null) return null;

  LatLng origin;
  if (manualPickup != null) {
    origin = LatLng(manualPickup.latitude, manualPickup.longitude);
  } else {
    final snapshot = ref.read(bookingOriginSnapshotProvider);
    if (snapshot != null) {
      origin = LatLng(snapshot.latitude, snapshot.longitude);
    } else {
      final position = await ref.watch(currentLocationProvider.future);
      if (position == null) return null;

      ref
          .read(bookingOriginSnapshotProvider.notifier)
          .state = BookingOriginSnapshot(
        latitude: position.latitude,
        longitude: position.longitude,
        capturedAt: DateTime.now(),
      );
      origin = LatLng(position.latitude, position.longitude);
    }
  }

  final dest = LatLng(destination.latitude, destination.longitude);

  final useCase = ref.read(getRouteDirectionsUseCaseProvider);
  final result = await useCase(
    GetRouteDirectionsParams(
      origin: origin,
      destination: dest,
      includeAlternativeRoutes: false,
    ),
  );
  return result.fold((failure) => throw StateError(failure.message), (value) {
    return value;
  });
}
